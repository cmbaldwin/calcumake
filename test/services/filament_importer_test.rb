# frozen_string_literal: true

require "test_helper"

class FilamentImporterTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
  end

  # Validation tests
  test "should reject blank source content" do
    importer = FilamentImporter.new(@user, source_type: "text", source_content: "")
    result = importer.import

    assert_not result
    assert_includes importer.errors.join, "cannot be blank"
  end

  test "should reject invalid URL" do
    importer = FilamentImporter.new(@user, source_type: "url", source_content: "not-a-url")
    result = importer.import

    assert_not result
    assert_includes importer.errors.join, "Invalid URL"
  end

  test "should accept valid URL format" do
    importer = FilamentImporter.new(@user, source_type: "url", source_content: "https://example.com/filament")

    # Will fail at fetch step (no actual URL), but should pass validation
    assert importer.send(:valid_input?)
  end

  # Configuration tests
  test "should check for OpenRouter API key" do
    # Temporarily unset the env vars
    original_key = ENV["OPENROUTER_API_KEY"]
    original_translation_key = ENV["OPENROUTER_TRANSLATION_KEY"]

    ENV.delete("OPENROUTER_API_KEY")
    ENV.delete("OPENROUTER_TRANSLATION_KEY")

    importer = FilamentImporter.new(@user, source_type: "text", source_content: "test content")
    result = importer.import

    assert_not result
    assert_includes importer.errors.join, "API key not configured"
  ensure
    # Restore original values
    ENV["OPENROUTER_API_KEY"] = original_key if original_key
    ENV["OPENROUTER_TRANSLATION_KEY"] = original_translation_key if original_translation_key
  end

  # Data normalization tests
  test "should normalize material type case-insensitively" do
    importer = FilamentImporter.new(@user, source_type: "text", source_content: "test")
    data = { "name" => "Test", "material_type" => "pla" }

    normalized = importer.send(:normalize_filament_data, data)

    assert_equal "PLA", normalized[:material_type]
  end

  test "should reject invalid material type" do
    importer = FilamentImporter.new(@user, source_type: "text", source_content: "test")
    data = { "name" => "Test", "material_type" => "InvalidType" }

    normalized = importer.send(:normalize_filament_data, data)

    assert_nil normalized
  end

  test "should default to 1.75mm diameter" do
    importer = FilamentImporter.new(@user, source_type: "text", source_content: "test")
    data = { "name" => "Test", "material_type" => "PLA", "diameter" => 99.99 }

    normalized = importer.send(:normalize_filament_data, data)

    assert_equal 1.75, normalized[:diameter]
  end

  test "should accept valid diameters" do
    importer = FilamentImporter.new(@user, source_type: "text", source_content: "test")

    [ 1.75, 2.85, 3.0 ].each do |diameter|
      data = { "name" => "Test", "material_type" => "PLA", "diameter" => diameter }
      normalized = importer.send(:normalize_filament_data, data)

      assert_equal diameter, normalized[:diameter]
    end
  end

  test "should convert numeric fields properly" do
    importer = FilamentImporter.new(@user, source_type: "text", source_content: "test")
    data = {
      "name" => "Test",
      "material_type" => "PLA",
      "spool_weight" => "1000",
      "spool_price" => "25.99",
      "print_temperature_min" => "190",
      "print_temperature_max" => "220"
    }

    normalized = importer.send(:normalize_filament_data, data)

    assert_equal 1000.0, normalized[:spool_weight]
    assert_equal 25.99, normalized[:spool_price]
    assert_equal 190, normalized[:print_temperature_min]
    assert_equal 220, normalized[:print_temperature_max]
  end

  test "should require name and material_type" do
    importer = FilamentImporter.new(@user, source_type: "text", source_content: "test")

    # Missing name
    data = { "material_type" => "PLA" }
    assert_nil importer.send(:normalize_filament_data, data)

    # Missing material_type
    data = { "name" => "Test" }
    assert_nil importer.send(:normalize_filament_data, data)
  end

  # Duplicate handling tests
  test "should handle duplicate filament names" do
    # Create a filament with a specific name
    existing = @user.filaments.create!(
      name: "Test Filament",
      material_type: "PLA",
      diameter: 1.75
    )

    importer = FilamentImporter.new(@user, source_type: "text", source_content: "test")
    filaments_data = [
      { name: "Test Filament", material_type: "PLA", diameter: 1.75 }
    ]

    created = importer.send(:create_filaments, filaments_data)

    assert_equal 1, created.count
    assert_equal "Test Filament (1)", created.first.name
  end

  # Constants validation
  test "should have correct valid material types" do
    expected = %w[PLA ABS PETG TPU ASA HIPS Nylon PC PVA Wood Metal Carbon]
    assert_equal expected, FilamentImporter::VALID_MATERIAL_TYPES
  end

  test "should have correct valid diameters" do
    expected = [ 1.75, 2.85, 3.0 ]
    assert_equal expected, FilamentImporter::VALID_DIAMETERS
  end
end
