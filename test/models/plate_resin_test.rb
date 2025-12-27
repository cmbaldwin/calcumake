require "test_helper"

class PlateResinTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @resin = resins(:one)
    @print_pricing = print_pricings(:one)
  end

  # Helper to create a valid resin plate with plate_resin
  def create_resin_plate_with_resin(resin: @resin, volume: 50.0, markup: nil)
    plate = @print_pricing.plates.build(
      printing_time_hours: 2,
      printing_time_minutes: 30,
      material_technology: :resin
    )
    attrs = { resin: resin, resin_volume_ml: volume }
    attrs[:markup_percentage] = markup if markup
    plate_resin = plate.plate_resins.build(attrs)
    plate.save!
    [ plate, plate_resin.reload ]
  end

  test "should be valid with required attributes" do
    plate = @print_pricing.plates.build(
      printing_time_hours: 2,
      printing_time_minutes: 30,
      material_technology: :resin
    )

    plate_resin = plate.plate_resins.build(
      resin: @resin,
      resin_volume_ml: 50.0
    )
    assert plate_resin.valid?
    assert plate.valid?
  end

  test "should require resin_volume_ml" do
    plate = @print_pricing.plates.build(
      printing_time_hours: 2,
      printing_time_minutes: 30,
      material_technology: :resin
    )

    plate_resin = plate.plate_resins.build(
      resin: @resin,
      resin_volume_ml: nil
    )
    assert_not plate_resin.valid?
    assert_includes plate_resin.errors[:resin_volume_ml], "can't be blank"
  end

  test "should require positive resin_volume_ml" do
    plate = @print_pricing.plates.build(
      printing_time_hours: 2,
      printing_time_minutes: 30,
      material_technology: :resin
    )

    plate_resin = plate.plate_resins.build(
      resin: @resin,
      resin_volume_ml: -10.0
    )
    assert_not plate_resin.valid?
  end

  test "total_cost calculates correctly with default markup" do
    _plate, plate_resin = create_resin_plate_with_resin(volume: 100.0, markup: 20.0)

    # cost_per_ml = 25.0 / 1000.0 = 0.025
    # base_cost = 100 * 0.025 = 2.50
    # with 20% markup = 2.50 * 1.20 = 3.00
    assert_in_delta 3.0, plate_resin.total_cost, 0.01
  end

  test "total_cost calculates correctly with custom markup" do
    _plate, plate_resin = create_resin_plate_with_resin(volume: 100.0, markup: 50.0)

    # base_cost = 100 * 0.025 = 2.50
    # with 50% markup = 2.50 * 1.50 = 3.75
    assert_in_delta 3.75, plate_resin.total_cost, 0.01
  end

  test "total_cost returns 0 when resin has no cost data" do
    @resin.update!(bottle_price: nil)
    _plate, plate_resin = create_resin_plate_with_resin(volume: 100.0)

    assert_equal 0, plate_resin.total_cost
  end

  test "delegates resin_type to resin" do
    _plate, plate_resin = create_resin_plate_with_resin

    assert_equal @resin.resin_type, plate_resin.resin_type
  end

  test "delegates display_name to resin" do
    _plate, plate_resin = create_resin_plate_with_resin

    assert_equal @resin.display_name, plate_resin.display_name
  end

  test "defaults markup_percentage to 20" do
    _plate, plate_resin = create_resin_plate_with_resin

    assert_equal 20.0, plate_resin.markup_percentage.to_f
  end
end
