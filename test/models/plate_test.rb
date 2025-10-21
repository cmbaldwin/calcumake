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
    base_cost = (plate.filament_weight * plate.spool_price / plate.spool_weight)
    expected = base_cost * (1 + plate.markup_percentage / 100)
    assert_in_delta expected, plate.total_filament_cost, 0.01
  end

  test "requires filament_type" do
    plate = Plate.new(
      print_pricing: print_pricings(:one),
      printing_time_hours: 1,
      printing_time_minutes: 0,
      filament_weight: 50.0,
      spool_price: 25.0,
      spool_weight: 1000.0,
      markup_percentage: 20.0
    )
    assert_not plate.valid?
    assert_includes plate.errors[:filament_type], "can't be blank"
  end

  test "requires positive filament_weight" do
    plate = plates(:one)
    plate.filament_weight = 0
    assert_not plate.valid?
    assert_includes plate.errors[:filament_weight], "must be greater than 0"
  end
end
