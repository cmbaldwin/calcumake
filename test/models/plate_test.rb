require "test_helper"

class PlateTest < ActiveSupport::TestCase
  test "belongs to print_pricing" do
    plate = plates(:one)
    assert_instance_of PrintPricing, plate.print_pricing
  end

  test "total_printing_time_minutes calculates correctly" do
    plate = plates(:one)
    expected = (plate.printing_time_hours * 60) + plate.printing_time_minutes
    assert_equal expected, plate.total_printing_time_minutes
  end

  test "total_filament_cost calculates correctly" do
    plate = plates(:one)
    expected = plate.plate_filaments.sum(&:total_cost)
    assert_in_delta expected, plate.total_filament_cost, 0.01
  end

  test "requires at least one filament" do
    plate = Plate.new(
      print_pricing: print_pricings(:one),
      printing_time_hours: 1,
      printing_time_minutes: 0
    )
    assert_not plate.valid?
    assert plate.errors[:base].any? { |msg| msg.include?("filament") }
  end

  test "total_filament_weight calculates correctly" do
    plate = plates(:one)
    expected = plate.plate_filaments.sum(&:filament_weight)
    assert_equal expected, plate.total_filament_weight
  end

  test "filament_types returns comma-separated material types" do
    plate = plates(:one)
    assert_kind_of String, plate.filament_types
  end
end
