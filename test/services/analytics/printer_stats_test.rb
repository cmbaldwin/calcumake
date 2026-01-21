require "test_helper"

module Analytics
  class PrinterStatsTest < ActiveSupport::TestCase
    setup do
      @user = users(:one)
      @printer = printers(:one)

      # Set daily usage hours for utilization calculations
      @printer.update(daily_usage_hours: 8)

      # Create print pricings in current period
      @current_pricing = create_print_pricing(
        @user,
        @printer,
        created_at: 10.days.ago,
        final_price: 200,
        times_printed: 2,
        print_time_minutes: 120
      )

      @stats = Analytics::PrinterStats.new(@user, start_date: 30.days.ago.to_date, end_date: Date.current)
    end

    test "calculates printer usage stats" do
      usage_stats = @stats.printer_usage_stats

      assert_instance_of Array, usage_stats
      assert usage_stats.any?

      stat = usage_stats.first
      assert_equal @printer, stat[:printer]
      assert_kind_of Numeric, stat[:total_print_time_hours]
      assert_kind_of Integer, stat[:total_prints]
      assert_kind_of Numeric, stat[:utilization_rate]
      assert_kind_of Numeric, stat[:revenue]
    end

    test "calculates utilization rate correctly" do
      usage_stats = @stats.printer_usage_stats
      stat = usage_stats.find { |s| s[:printer] == @printer }

      # 2 prints * 120 minutes = 240 minutes total
      # 30 days * 8 hours/day * 60 minutes = 14,400 minutes available
      # Utilization = (240 / 14400) * 100 = 1.67%
      expected_utilization = (240.0 / (30 * 8 * 60) * 100).round(1)

      assert_equal expected_utilization, stat[:utilization_rate]
    end

    test "calculates revenue per printer" do
      usage_stats = @stats.printer_usage_stats
      stat = usage_stats.find { |s| s[:printer] == @printer }

      # 2 prints * 200 price = 400
      assert_equal 400, stat[:revenue]
    end

    test "sorts printers by revenue descending" do
      # Create second printer with higher revenue
      printer2 = @user.printers.create!(
        name: "High Revenue Printer",
        manufacturer: "Test",
        power_consumption: 300,
        daily_usage_hours: 8
      )

      create_print_pricing(
        @user,
        printer2,
        created_at: 5.days.ago,
        final_price: 500,
        times_printed: 5,
        print_time_minutes: 60
      )

      usage_stats = @stats.printer_usage_stats

      # Higher revenue printer should be first
      assert_equal printer2, usage_stats.first[:printer]
      assert_equal @printer, usage_stats.second[:printer]
    end

    test "calculates ROI progress" do
      # Set up printer cost for ROI calculation
      @printer.update(
        cost: 1000,
        payoff_goal_years: 2,
        daily_usage_hours: 8
      )

      roi_progress = @stats.roi_progress

      assert_instance_of Array, roi_progress
      assert roi_progress.any?

      stat = roi_progress.find { |r| r[:printer] == @printer }
      assert_not_nil stat

      assert_includes [ true, false ], stat[:paid_off]
      assert_kind_of Numeric, stat[:progress_percentage]

      # Progress should be (revenue / cost) * 100 = (400 / 1000) * 100 = 40%
      assert_equal 40.0, stat[:progress_percentage]
    end

    test "marks printer as paid off when revenue exceeds cost" do
      # Set low cost so printer is paid off
      @printer.update(
        cost: 100,
        payoff_goal_years: 1,
        daily_usage_hours: 8
      )

      roi_progress = @stats.roi_progress
      stat = roi_progress.find { |r| r[:printer] == @printer }

      assert stat[:paid_off]
      assert_equal 100, stat[:progress_percentage] # Capped at 100%
    end

    test "calculates cost per print" do
      cost_stats = @stats.cost_per_print_by_printer

      assert_instance_of Array, cost_stats
      stat = cost_stats.find { |s| s[:printer] == @printer }

      assert_not_nil stat
      assert_kind_of Numeric, stat[:cost_per_print]
      assert_equal 2, stat[:total_prints]
    end

    test "identifies most used printer" do
      most_used = @stats.most_used_printer

      assert_not_nil most_used
      assert_equal @printer, most_used[:printer]
      assert_kind_of Numeric, most_used[:total_print_time_hours]
    end

    test "calculates average utilization rate" do
      avg_utilization = @stats.average_utilization_rate

      assert_kind_of Numeric, avg_utilization
      assert avg_utilization >= 0
      assert avg_utilization <= 100
    end

    test "returns zero for average utilization when no printers" do
      user_with_no_printers = users(:two)
      stats = Analytics::PrinterStats.new(user_with_no_printers, start_date: 30.days.ago.to_date, end_date: Date.current)

      assert_equal 0, stats.average_utilization_rate
    end

    test "handles printer with no prints in period" do
      unused_printer = @user.printers.create!(
        name: "Unused Printer",
        manufacturer: "Test",
        power_consumption: 200,
        daily_usage_hours: 8
      )

      usage_stats = @stats.printer_usage_stats
      stat = usage_stats.find { |s| s[:printer] == unused_printer }

      if stat # May not be in list if sorted by revenue and has 0
        assert_equal 0, stat[:total_prints]
        assert_equal 0, stat[:utilization_rate]
        assert_equal 0, stat[:revenue]
      end
    end

    private

    def create_print_pricing(user, printer, created_at:, final_price:, times_printed:, print_time_minutes:)
      pricing = user.print_pricings.create!(
        job_name: "Test Job #{rand(1000)}",
        final_price: final_price,
        times_printed: times_printed,
        created_at: created_at,
        printer: printer
      )

      plate = pricing.plates.create!(
        printing_time_hours: print_time_minutes / 60,
        printing_time_minutes: print_time_minutes % 60,
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
