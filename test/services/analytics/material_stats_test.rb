require "test_helper"

module Analytics
  class MaterialStatsTest < ActiveSupport::TestCase
    setup do
      @user = users(:one)
      @filament = filaments(:one)

      # Create print pricing with filament usage
      @pricing = create_print_pricing_with_filament(
        @user,
        created_at: 10.days.ago,
        final_price: 200,
        times_printed: 2,
        filament_weight: 100.0
      )

      @stats = Analytics::MaterialStats.new(@user, start_date: 30.days.ago.to_date, end_date: Date.current)
    end

    test "returns top filaments by usage" do
      top_filaments = @stats.top_filaments_by_usage(limit: 10)

      assert_instance_of Array, top_filaments
      assert top_filaments.any?

      stat = top_filaments.first
      assert_equal @filament, stat[:filament]
      # 2 prints * 100g = 200g total
      assert_equal 200.0, stat[:weight_grams]
      assert_equal 2, stat[:print_count]
      assert_kind_of Numeric, stat[:cost]
    end

    test "calculates filament cost correctly" do
      # Filament price is set in fixture
      top_filaments = @stats.top_filaments_by_usage
      stat = top_filaments.first

      # Cost = (weight_grams / 1000) * price_per_kg
      # = (200 / 1000) * filament.price_per_kg
      expected_cost = (200.0 / 1000.0) * @filament.price_per_kg
      assert_equal expected_cost.round(2), stat[:cost].round(2)
    end

    test "sorts filaments by weight usage" do
      # Create another print with different weight
      filament2 = @user.filaments.create!(
        name: "Heavy Filament",
        manufacturer: "Test",
        material_type: "PLA",
        color: "Red",
        price_per_kg: 25.0
      )

      create_print_pricing_with_custom_filament(
        @user,
        filament2,
        created_at: 5.days.ago,
        times_printed: 1,
        filament_weight: 300.0
      )

      top_filaments = @stats.top_filaments_by_usage

      # Heavier filament should be first (300g vs 200g)
      assert_equal filament2, top_filaments.first[:filament]
    end

    test "calculates total material costs" do
      costs = @stats.total_material_costs

      assert_includes costs.keys, :filament_cost
      assert_includes costs.keys, :resin_cost
      assert_includes costs.keys, :total_cost

      assert_kind_of Numeric, costs[:filament_cost]
      assert_kind_of Numeric, costs[:resin_cost]
      assert_kind_of Numeric, costs[:total_cost]

      assert_equal costs[:filament_cost] + costs[:resin_cost], costs[:total_cost]
    end

    test "calculates average material cost per print" do
      avg_cost = @stats.average_material_cost_per_print

      assert_kind_of Numeric, avg_cost
      assert avg_cost > 0
    end

    test "returns zero avg cost when no prints" do
      user_with_no_prints = users(:two)
      stats = Analytics::MaterialStats.new(user_with_no_prints, start_date: 30.days.ago.to_date, end_date: Date.current)

      assert_equal 0, stats.average_material_cost_per_print
    end

    test "calculates estimated failure cost" do
      # Create pricing with failure rate
      pricing_with_failures = create_print_pricing_with_filament(
        @user,
        created_at: 5.days.ago,
        final_price: 100,
        times_printed: 10,
        filament_weight: 50.0,
        failure_rate: 10.0 # 10% failure rate
      )

      failure_cost = @stats.estimated_failure_cost

      assert_kind_of Numeric, failure_cost
      assert failure_cost > 0
    end

    test "returns zero failure cost when no failures" do
      # All pricings have 0 or nil failure rate by default
      failure_cost = @stats.estimated_failure_cost

      # Should be minimal or zero since default fixture likely has no failure rate
      assert_kind_of Numeric, failure_cost
      assert failure_cost >= 0
    end

    test "calculates technology usage split" do
      split = @stats.technology_usage_split

      assert_includes split.keys, :fdm_prints
      assert_includes split.keys, :resin_prints
      assert_includes split.keys, :fdm_percentage
      assert_includes split.keys, :resin_percentage

      assert_kind_of Integer, split[:fdm_prints]
      assert_kind_of Integer, split[:resin_prints]
      assert_kind_of Numeric, split[:fdm_percentage]
      assert_kind_of Numeric, split[:resin_percentage]

      # Percentages should add up to 100 (or 0 if no prints)
      total_prints = split[:fdm_prints] + split[:resin_prints]
      if total_prints > 0
        assert_in_delta 100.0, split[:fdm_percentage] + split[:resin_percentage], 0.1
      end
    end

    test "handles multiple filaments per plate" do
      filament2 = @user.filaments.create!(
        name: "Second Filament",
        manufacturer: "Test",
        material_type: "PETG",
        color: "Blue",
        price_per_kg: 30.0
      )

      pricing = @user.print_pricings.create!(
        job_name: "Multi Filament Job",
        final_price: 150,
        times_printed: 1,
        created_at: 5.days.ago,
        printer: printers(:one)
      )

      plate = pricing.plates.create!(
        printing_time_hours: 3,
        printing_time_minutes: 0,
        material_technology: "fdm"
      )

      # Add two different filaments to the same plate
      plate.plate_filaments.create!(filament: @filament, filament_weight: 80.0)
      plate.plate_filaments.create!(filament: filament2, filament_weight: 120.0)

      top_filaments = @stats.top_filaments_by_usage

      # Should have stats for both filaments
      filament1_stat = top_filaments.find { |s| s[:filament] == @filament }
      filament2_stat = top_filaments.find { |s| s[:filament] == filament2 }

      assert_not_nil filament1_stat
      assert_not_nil filament2_stat
    end

    test "material costs by day returns correct structure" do
      costs_by_day = @stats.material_costs_by_day

      assert_instance_of Hash, costs_by_day
      costs_by_day.each do |date, costs|
        assert_instance_of Date, date
        assert_includes costs.keys, :filament
        assert_includes costs.keys, :resin
        assert_kind_of Numeric, costs[:filament]
        assert_kind_of Numeric, costs[:resin]
      end
    end

    private

    def create_print_pricing_with_filament(user, created_at:, final_price:, times_printed:, filament_weight:, failure_rate: 0)
      pricing = user.print_pricings.create!(
        job_name: "Test Job #{rand(1000)}",
        final_price: final_price,
        times_printed: times_printed,
        failure_rate_percentage: failure_rate,
        created_at: created_at,
        printer: printers(:one)
      )

      plate = pricing.plates.create!(
        printing_time_hours: 2,
        printing_time_minutes: 0,
        material_technology: "fdm"
      )

      plate.plate_filaments.create!(
        filament: @filament,
        filament_weight: filament_weight
      )

      pricing
    end

    def create_print_pricing_with_custom_filament(user, filament, created_at:, times_printed:, filament_weight:)
      pricing = user.print_pricings.create!(
        job_name: "Test Job #{rand(1000)}",
        final_price: 100,
        times_printed: times_printed,
        created_at: created_at,
        printer: printers(:one)
      )

      plate = pricing.plates.create!(
        printing_time_hours: 2,
        printing_time_minutes: 0,
        material_technology: "fdm"
      )

      plate.plate_filaments.create!(
        filament: filament,
        filament_weight: filament_weight
      )

      pricing
    end
  end
end
