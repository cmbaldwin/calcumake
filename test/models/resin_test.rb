require "test_helper"

class ResinTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @resin = resins(:one)
  end

  test "should be valid with required attributes" do
    resin = @user.resins.build(
      name: "Test Resin",
      resin_type: "Standard"
    )
    assert resin.valid?
  end

  test "should require name" do
    resin = @user.resins.build(resin_type: "Standard")
    assert_not resin.valid?
    assert_includes resin.errors[:name], "can't be blank"
  end

  test "should require resin_type" do
    resin = @user.resins.build(name: "Test")
    assert_not resin.valid?
    assert_includes resin.errors[:resin_type], "can't be blank"
  end

  test "should require valid resin_type" do
    resin = @user.resins.build(name: "Test", resin_type: "InvalidType")
    assert_not resin.valid?
    assert_includes resin.errors[:resin_type], "is not included in the list"
  end

  test "should allow all valid resin types" do
    Resin::RESIN_TYPES.each do |type|
      resin = @user.resins.build(name: "Test #{type}", resin_type: type)
      assert resin.valid?, "Expected #{type} to be valid"
    end
  end

  test "should require unique name per user" do
    resin = @user.resins.build(
      name: @resin.name,
      resin_type: "Standard"
    )
    assert_not resin.valid?
    assert_includes resin.errors[:name], "has already been taken"
  end

  test "should allow same name for different users" do
    other_user = users(:two)
    resin = other_user.resins.build(
      name: @resin.name,
      resin_type: "Standard"
    )
    assert resin.valid?
  end

  test "cost_per_ml calculates correctly" do
    @resin.bottle_price = 25.0
    @resin.bottle_volume_ml = 1000.0
    assert_in_delta 0.025, @resin.cost_per_ml, 0.0001
  end

  test "cost_per_ml returns 0 when bottle_price is nil" do
    @resin.bottle_price = nil
    assert_equal 0, @resin.cost_per_ml
  end

  test "cost_per_ml returns 0 when bottle_volume_ml is nil" do
    @resin.bottle_volume_ml = nil
    assert_equal 0, @resin.cost_per_ml
  end

  test "cost_per_ml returns 0 when bottle_volume_ml is zero" do
    @resin.bottle_volume_ml = 0
    assert_equal 0, @resin.cost_per_ml
  end

  test "display_name includes brand when present" do
    @resin.brand = "Elegoo"
    @resin.name = "Standard Gray"
    @resin.resin_type = "Standard"
    @resin.color = "Gray"
    assert_equal "Elegoo Standard Gray (Standard - Gray)", @resin.display_name
  end

  test "display_name works without brand" do
    @resin.brand = nil
    @resin.name = "Standard Gray"
    @resin.resin_type = "Standard"
    @resin.color = nil
    assert_equal "Standard Gray (Standard)", @resin.display_name
  end

  test "layer_height_range shows range when both values present" do
    @resin.layer_height_min = 0.025
    @resin.layer_height_max = 0.100
    assert_equal "0.025-0.1mm", @resin.layer_height_range
  end

  test "layer_height_range shows not specified when both nil" do
    @resin.layer_height_min = nil
    @resin.layer_height_max = nil
    assert_equal "Not specified", @resin.layer_height_range
  end

  test "validates layer_height_max greater than min" do
    resin = @user.resins.build(
      name: "Test",
      resin_type: "Standard",
      layer_height_min: 0.100,
      layer_height_max: 0.050
    )
    assert_not resin.valid?
    assert resin.errors[:layer_height_max].any?
  end

  test "validates bottle_volume_ml is positive" do
    resin = @user.resins.build(
      name: "Test",
      resin_type: "Standard",
      bottle_volume_ml: -100
    )
    assert_not resin.valid?
  end

  test "validates bottle_price is positive" do
    resin = @user.resins.build(
      name: "Test",
      resin_type: "Standard",
      bottle_price: -10
    )
    assert_not resin.valid?
  end

  test "search scope finds by name" do
    results = @user.resins.search("Gray")
    assert_includes results, @resin
  end

  test "search scope finds by brand" do
    results = @user.resins.search("Elegoo")
    assert_includes results, @resin
  end

  test "search scope finds by color" do
    results = @user.resins.search(@resin.color)
    assert_includes results, @resin
  end

  test "by_resin_type scope filters correctly" do
    results = @user.resins.by_resin_type("Standard")
    assert_includes results, @resin
  end

  test "touches user on save" do
    original_updated_at = @user.updated_at
    travel 1.minute do
      @resin.update!(name: "Updated Name")
      assert_not_equal original_updated_at, @user.reload.updated_at
    end
  end
end
