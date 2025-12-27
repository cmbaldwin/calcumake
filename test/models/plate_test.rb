require "test_helper"

class PlateTest < ActiveSupport::TestCase
  def setup
    @plate = plates(:one)
    @print_pricing = print_pricings(:one)
    @user = users(:one)
    @resin = resins(:one)
  end

  test "belongs to print_pricing" do
    assert_instance_of PrintPricing, @plate.print_pricing
  end

  test "total_printing_time_minutes calculates correctly" do
    expected = (@plate.printing_time_hours * 60) + @plate.printing_time_minutes
    assert_equal expected, @plate.total_printing_time_minutes
  end

  test "total_filament_cost calculates correctly" do
    expected = @plate.plate_filaments.sum(&:total_cost)
    assert_in_delta expected, @plate.total_filament_cost, 0.01
  end

  test "requires at least one filament for fdm plates" do
    plate = Plate.new(
      print_pricing: @print_pricing,
      printing_time_hours: 1,
      printing_time_minutes: 0,
      material_technology: :fdm
    )
    assert_not plate.valid?
    assert plate.errors[:base].any?
  end

  test "total_filament_weight calculates correctly" do
    expected = @plate.plate_filaments.sum(&:filament_weight)
    assert_equal expected, @plate.total_filament_weight
  end

  test "filament_types returns comma-separated material types" do
    assert_kind_of String, @plate.filament_types
  end

  # Material technology enum tests
  test "defaults to fdm technology" do
    plate = Plate.new
    assert plate.fdm?
    assert_equal "fdm", plate.material_technology
  end

  test "can set resin technology" do
    plate = Plate.new(material_technology: :resin)
    assert plate.resin?
  end

  # Resin plate tests
  test "requires at least one resin for resin plates" do
    plate = Plate.new(
      print_pricing: @print_pricing,
      printing_time_hours: 1,
      printing_time_minutes: 0,
      material_technology: :resin
    )
    assert_not plate.valid?
    assert plate.errors[:base].any?
  end

  test "resin plate is valid with resin" do
    plate = @print_pricing.plates.build(
      printing_time_hours: 2,
      printing_time_minutes: 0,
      material_technology: :resin
    )
    plate.plate_resins.build(resin: @resin, resin_volume_ml: 50.0)
    assert plate.valid?
  end

  test "total_resin_cost calculates correctly" do
    plate = @print_pricing.plates.build(
      printing_time_hours: 2,
      printing_time_minutes: 0,
      material_technology: :resin
    )
    plate.plate_resins.build(resin: @resin, resin_volume_ml: 100.0, markup_percentage: 20.0)
    plate.save!

    expected = plate.plate_resins.sum(&:total_cost)
    assert_in_delta expected, plate.total_resin_cost, 0.01
  end

  test "total_material_cost returns filament cost for fdm" do
    assert @plate.fdm?
    assert_equal @plate.total_filament_cost, @plate.total_material_cost
  end

  test "total_material_cost returns resin cost for resin" do
    plate = @print_pricing.plates.build(
      printing_time_hours: 2,
      printing_time_minutes: 0,
      material_technology: :resin
    )
    plate.plate_resins.build(resin: @resin, resin_volume_ml: 50.0)
    plate.save!

    assert plate.resin?
    assert_equal plate.total_resin_cost, plate.total_material_cost
  end

  test "total_resin_volume calculates correctly" do
    plate = @print_pricing.plates.build(
      printing_time_hours: 2,
      printing_time_minutes: 0,
      material_technology: :resin
    )
    plate.plate_resins.build(resin: @resin, resin_volume_ml: 50.0)
    plate.save!

    expected = plate.plate_resins.sum(&:resin_volume_ml)
    assert_equal expected, plate.total_resin_volume
  end

  test "resin_types returns comma-separated resin types" do
    plate = @print_pricing.plates.build(
      printing_time_hours: 2,
      printing_time_minutes: 0,
      material_technology: :resin
    )
    plate.plate_resins.build(resin: @resin, resin_volume_ml: 50.0)
    plate.save!

    assert_kind_of String, plate.resin_types
    assert_includes plate.resin_types, @resin.resin_type
  end

  test "material_types returns filament types for fdm" do
    assert @plate.fdm?
    assert_equal @plate.filament_types, @plate.material_types
  end

  test "material_types returns resin types for resin" do
    plate = @print_pricing.plates.build(
      printing_time_hours: 2,
      printing_time_minutes: 0,
      material_technology: :resin
    )
    plate.plate_resins.build(resin: @resin, resin_volume_ml: 50.0)
    plate.save!

    assert plate.resin?
    assert_equal plate.resin_types, plate.material_types
  end

  test "fdm plate does not require resin" do
    plate = @print_pricing.plates.build(
      printing_time_hours: 1,
      printing_time_minutes: 0,
      material_technology: :fdm
    )
    plate.plate_filaments.build(filament: filaments(:one), filament_weight: 50.0)

    assert plate.valid?
    assert plate.plate_resins.empty?
  end

  test "resin plate does not require filaments" do
    plate = @print_pricing.plates.build(
      printing_time_hours: 1,
      printing_time_minutes: 0,
      material_technology: :resin
    )
    plate.plate_resins.build(resin: @resin, resin_volume_ml: 50.0)

    assert plate.valid?
    assert plate.plate_filaments.empty?
  end
end
