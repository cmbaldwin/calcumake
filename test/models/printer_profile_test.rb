require "test_helper"

class PrinterProfileTest < ActiveSupport::TestCase
  def setup
    @bambu = printer_profiles(:bambu_p1s)
    @elegoo = printer_profiles(:elegoo_mars)
  end

  test "should be valid with required attributes" do
    profile = PrinterProfile.new(
      manufacturer: "Test Brand",
      model: "Test Model",
      technology: "fdm"
    )
    assert profile.valid?
  end

  test "should require manufacturer" do
    profile = PrinterProfile.new(model: "Test", technology: "fdm")
    assert_not profile.valid?
    assert_includes profile.errors[:manufacturer], "can't be blank"
  end

  test "should require model" do
    profile = PrinterProfile.new(manufacturer: "Test", technology: "fdm")
    assert_not profile.valid?
    assert_includes profile.errors[:model], "can't be blank"
  end

  test "should require unique manufacturer-model combination" do
    duplicate = PrinterProfile.new(
      manufacturer: @bambu.manufacturer,
      model: @bambu.model,
      technology: "fdm"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:model], "has already been taken"
  end

  test "should allow same model from different manufacturer" do
    profile = PrinterProfile.new(
      manufacturer: "Different Brand",
      model: @bambu.model,
      technology: "fdm"
    )
    assert profile.valid?
  end

  test "should validate technology is an enum" do
    # Rails enum raises ArgumentError for invalid values
    assert_raises(ArgumentError) do
      PrinterProfile.new(
        manufacturer: "Test",
        model: "Test",
        technology: "laser"
      )
    end
  end

  test "should validate category inclusion when present" do
    profile = PrinterProfile.new(
      manufacturer: "Test",
      model: "Test",
      technology: "fdm",
      category: "Invalid Category"
    )
    assert_not profile.valid?
    assert_includes profile.errors[:category], "is not included in the list"
  end

  test "should allow blank category" do
    profile = PrinterProfile.new(
      manufacturer: "Test",
      model: "Test",
      technology: "fdm",
      category: nil
    )
    assert profile.valid?
  end

  test "display_name returns manufacturer and model" do
    assert_equal "Bambu Lab P1S Combo", @bambu.display_name
  end

  test "full_display_name includes category when present" do
    assert_equal "Bambu Lab P1S Combo (Mid-Range FDM)", @bambu.full_display_name
  end

  test "full_display_name excludes category when blank" do
    @bambu.category = nil
    assert_equal "Bambu Lab P1S Combo", @bambu.full_display_name
  end

  test "by_technology scope filters correctly" do
    fdm_profiles = PrinterProfile.by_technology("fdm")
    resin_profiles = PrinterProfile.by_technology("resin")

    assert fdm_profiles.include?(@bambu)
    assert_not fdm_profiles.include?(@elegoo)
    assert resin_profiles.include?(@elegoo)
    assert_not resin_profiles.include?(@bambu)
  end

  test "search scope finds by manufacturer" do
    results = PrinterProfile.search("Bambu")
    assert results.include?(@bambu)
    assert_not results.include?(@elegoo)
  end

  test "search scope finds by model" do
    results = PrinterProfile.search("Mars")
    assert results.include?(@elegoo)
    assert_not results.include?(@bambu)
  end

  test "search scope finds by category" do
    results = PrinterProfile.search("Resin")
    assert results.include?(@elegoo)
  end

  test "search scope is case insensitive" do
    results = PrinterProfile.search("bambu")
    assert results.include?(@bambu)
  end

  test "fdm enum value" do
    assert @bambu.fdm?
    assert_not @bambu.resin?
  end

  test "resin enum value" do
    assert @elegoo.resin?
    assert_not @elegoo.fdm?
  end

  test "CATEGORIES constant contains expected values" do
    assert_includes PrinterProfile::CATEGORIES, "Budget FDM"
    assert_includes PrinterProfile::CATEGORIES, "Mid-Range FDM"
    assert_includes PrinterProfile::CATEGORIES, "Premium FDM"
    assert_includes PrinterProfile::CATEGORIES, "Professional FDM"
    assert_includes PrinterProfile::CATEGORIES, "Industrial FDM"
    assert_includes PrinterProfile::CATEGORIES, "Budget Resin"
    assert_includes PrinterProfile::CATEGORIES, "Mid-Range Resin"
    assert_includes PrinterProfile::CATEGORIES, "Professional Resin"
    assert_includes PrinterProfile::CATEGORIES, "Industrial Resin"
  end
end
