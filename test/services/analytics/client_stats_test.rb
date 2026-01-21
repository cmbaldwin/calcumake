require "test_helper"

module Analytics
  class ClientStatsTest < ActiveSupport::TestCase
    setup do
      @user = users(:one)
      @client1 = clients(:one)
      @client2 = @user.clients.create!(name: "High Value Client", email: "high@example.com")

      # Create pricing for client1 (lower revenue)
      @pricing1 = create_print_pricing(
        @user,
        @client1,
        created_at: 10.days.ago,
        final_price: 100,
        times_printed: 2
      )

      # Create pricing for client2 (higher revenue)
      @pricing2 = create_print_pricing(
        @user,
        @client2,
        created_at: 5.days.ago,
        final_price: 200,
        times_printed: 5
      )

      @stats = Analytics::ClientStats.new(@user, start_date: 30.days.ago.to_date, end_date: Date.current)
    end

    test "returns top clients by revenue" do
      top_clients = @stats.top_clients_by_revenue(limit: 10)

      assert_instance_of Array, top_clients
      assert_equal 2, top_clients.size

      # Client2 should be first (1000 revenue) vs client1 (200 revenue)
      assert_equal @client2, top_clients.first[:client]
      assert_equal 1000, top_clients.first[:revenue] # 200 * 5
      assert_equal 1, top_clients.first[:job_count]
      assert_equal 5, top_clients.first[:total_prints]
    end

    test "sorts clients by revenue descending" do
      top_clients = @stats.top_clients_by_revenue

      revenues = top_clients.map { |c| c[:revenue] }
      assert_equal revenues.sort.reverse, revenues
    end

    test "limits top clients by specified amount" do
      # Create additional clients
      5.times do |i|
        client = @user.clients.create!(name: "Client #{i}", email: "client#{i}@example.com")
        create_print_pricing(@user, client, created_at: 5.days.ago, final_price: 50, times_printed: 1)
      end

      top_clients = @stats.top_clients_by_revenue(limit: 3)
      assert_equal 3, top_clients.size
    end

    test "returns top clients by profit" do
      top_profitable = @stats.top_clients_by_profit(limit: 10)

      assert_instance_of Array, top_profitable
      assert top_profitable.any?

      stat = top_profitable.first
      assert_includes stat.keys, :client
      assert_includes stat.keys, :profit
      assert_includes stat.keys, :job_count
      assert_includes stat.keys, :profit_margin
    end

    test "calculates profit margin correctly" do
      top_profitable = @stats.top_clients_by_profit

      top_profitable.each do |stat|
        assert_kind_of Numeric, stat[:profit_margin]
        assert stat[:profit_margin] >= 0
        assert stat[:profit_margin] <= 100
      end
    end

    test "calculates average order value" do
      aov = @stats.average_order_value

      # Total revenue: 200 + 1000 = 1200
      # Total jobs: 2
      # AOV: 1200 / 2 = 600
      assert_equal 600.0, aov
    end

    test "returns zero AOV when no jobs" do
      user_with_no_jobs = users(:two)
      stats = Analytics::ClientStats.new(user_with_no_jobs, start_date: 30.days.ago.to_date, end_date: Date.current)

      assert_equal 0, stats.average_order_value
    end

    test "calculates client activity summary" do
      # Create inactive client (no orders in period)
      inactive_client = @user.clients.create!(name: "Inactive Client", email: "inactive@example.com")

      activity = @stats.client_activity_summary

      assert_equal 3, activity[:total_clients]
      assert_equal 2, activity[:active_clients]
      assert_equal 1, activity[:inactive_clients]
      assert_kind_of Numeric, activity[:activity_rate]
    end

    test "identifies at-risk clients" do
      # Create client with old order
      old_client = @user.clients.create!(name: "Old Client", email: "old@example.com")
      create_print_pricing(
        @user,
        old_client,
        created_at: 90.days.ago,
        final_price: 100,
        times_printed: 1
      )

      at_risk = @stats.at_risk_clients(days_threshold: 60)

      assert_includes at_risk, old_client
      assert_not_includes at_risk, @client1 # Recent order
      assert_not_includes at_risk, @client2 # Recent order
    end

    test "calculates revenue concentration" do
      # Create many small clients
      10.times do |i|
        client = @user.clients.create!(name: "Small Client #{i}", email: "small#{i}@example.com")
        create_print_pricing(@user, client, created_at: 5.days.ago, final_price: 10, times_printed: 1)
      end

      concentration = @stats.revenue_concentration

      assert_includes concentration.keys, :top_20_percent_revenue
      assert_includes concentration.keys, :total_revenue
      assert_includes concentration.keys, :concentration_percentage

      assert_kind_of Numeric, concentration[:concentration_percentage]
      assert concentration[:concentration_percentage] >= 0
      assert concentration[:concentration_percentage] <= 100
    end

    test "excludes clients with zero revenue" do
      # Create client with no orders
      zero_revenue_client = @user.clients.create!(name: "Zero Client", email: "zero@example.com")

      top_clients = @stats.top_clients_by_revenue

      assert_not_includes top_clients.map { |c| c[:client] }, zero_revenue_client
    end

    test "handles user with no clients" do
      user_with_no_clients = users(:two)
      stats = Analytics::ClientStats.new(user_with_no_clients, start_date: 30.days.ago.to_date, end_date: Date.current)

      assert_empty stats.top_clients_by_revenue
      assert_empty stats.top_clients_by_profit
      assert_equal 0, stats.average_order_value

      activity = stats.client_activity_summary
      assert_equal 0, activity[:total_clients]
      assert_equal 0, activity[:active_clients]
    end

    private

    def create_print_pricing(user, client, created_at:, final_price:, times_printed:)
      pricing = user.print_pricings.create!(
        job_name: "Test Job #{rand(1000)}",
        final_price: final_price,
        times_printed: times_printed,
        created_at: created_at,
        printer: printers(:one),
        client: client
      )

      plate = pricing.plates.create!(
        printing_time_hours: 2,
        printing_time_minutes: 0,
        material_technology: "fdm"
      )

      plate.plate_filaments.create!(
        filament: filaments(:one),
        filament_weight: 50.0
      )

      pricing
    end
  end
end
