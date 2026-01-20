require "test_helper"

module Analytics
  class OverviewStatsTest < ActiveSupport::TestCase
    setup do
      @user = users(:one)

      # Create print pricings in current period (last 30 days)
      @current_pricing1 = create_print_pricing(@user, created_at: 10.days.ago, final_price: 100, times_printed: 2)
      @current_pricing2 = create_print_pricing(@user, created_at: 5.days.ago, final_price: 150, times_printed: 1)

      # Create print pricings in previous period (30-60 days ago)
      @previous_pricing1 = create_print_pricing(@user, created_at: 40.days.ago, final_price: 80, times_printed: 2)
      @previous_pricing2 = create_print_pricing(@user, created_at: 35.days.ago, final_price: 120, times_printed: 1)

      @stats = Analytics::OverviewStats.new(@user, start_date: 30.days.ago.to_date, end_date: Date.current)
    end

    test "calculates total revenue for current period" do
      expected_revenue = (100 * 2) + (150 * 1) # 350
      assert_equal expected_revenue, @stats.total_revenue
    end

    test "calculates revenue trend compared to previous period" do
      current_revenue = (100 * 2) + (150 * 1) # 350
      previous_revenue = (80 * 2) + (120 * 1) # 280
      expected_trend = ((current_revenue - previous_revenue) / previous_revenue.to_f * 100).round(1) # 25.0%

      assert_equal expected_trend, @stats.revenue_trend
    end

    test "calculates total prints for current period" do
      expected_prints = 2 + 1 # 3
      assert_equal expected_prints, @stats.total_prints
    end

    test "calculates prints trend compared to previous period" do
      current_prints = 2 + 1 # 3
      previous_prints = 2 + 1 # 3
      expected_trend = 0.0 # No change

      assert_equal expected_trend, @stats.prints_trend
    end

    test "calculates total calculations for current period" do
      assert_equal 2, @stats.total_calculations
    end

    test "calculates calculations trend" do
      # Current period has 2 calculations
      # Previous period also has 2 calculations
      # Trend should be 0%
      assert_equal 0.0, @stats.calculations_trend
    end

    test "returns zero trend when previous period has no data" do
      user_with_no_history = users(:two)
      create_print_pricing(user_with_no_history, created_at: 10.days.ago, final_price: 100, times_printed: 1)

      stats = Analytics::OverviewStats.new(user_with_no_history, start_date: 30.days.ago.to_date, end_date: Date.current)
      assert_equal 0.0, stats.revenue_trend
    end

    test "groups revenue by day" do
      revenue_by_day = @stats.revenue_by_day

      assert_instance_of Hash, revenue_by_day
      assert revenue_by_day.keys.all? { |k| k.is_a?(Date) }
      assert revenue_by_day.values.all? { |v| v.is_a?(Numeric) }
    end

    test "groups prints by day" do
      prints_by_day = @stats.prints_by_day

      assert_instance_of Hash, prints_by_day
      assert prints_by_day.keys.all? { |k| k.is_a?(Date) }
      assert prints_by_day.values.all? { |v| v.is_a?(Integer) }
    end

    test "caches time series data" do
      # First call should query the database
      first_result = @stats.revenue_by_day

      # Second call should use cache
      Rails.cache.expects(:fetch).with(
        ["analytics", @user.id, "revenue_by_day", @stats.start_date, @stats.end_date],
        expires_in: 5.minutes
      ).returns(first_result)

      second_result = @stats.revenue_by_day
      assert_equal first_result, second_result
    end

    private

    def create_print_pricing(user, created_at:, final_price:, times_printed:)
      pricing = user.print_pricings.create!(
        job_name: "Test Job",
        final_price: final_price,
        times_printed: times_printed,
        created_at: created_at,
        printer: printers(:one)
      )

      # Create at least one plate with one filament
      plate = pricing.plates.create!(
        printing_time_hours: 2,
        printing_time_minutes: 30,
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
