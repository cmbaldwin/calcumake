require "test_helper"
require "tempfile"
require "zip"

class ThreeMfParserTest < ActiveSupport::TestCase
  def setup
    @temp_file = Tempfile.new([ "test_3mf", ".3mf" ])
  end

  def teardown
    @temp_file.close
    @temp_file.unlink
  end

  # Helper to create a minimal valid 3MF file
  def create_3mf_file(metadata = {})
    Zip::File.open(@temp_file.path, create: true) do |zipfile|
      # Add main model file
      model_xml = build_model_xml(metadata)
      zipfile.get_output_stream("3D/3dmodel.model") { |f| f.write(model_xml) }

      # Add relationships file
      rels_xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Target="/3D/3dmodel.model" Id="rel0" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>
        </Relationships>
      XML
      zipfile.get_output_stream("_rels/.rels") { |f| f.write(rels_xml) }
    end
  end

  def build_model_xml(metadata = {})
    metadata_tags = metadata.map do |key, value|
      "  <metadata name=\"#{key}\">#{value}</metadata>"
    end.join("\n")

    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
      #{metadata_tags}
        <resources>
          <object id="1" type="model">
            <mesh>
              <vertices>
                <vertex x="0" y="0" z="0"/>
                <vertex x="10" y="0" z="0"/>
                <vertex x="5" y="10" z="5"/>
              </vertices>
              <triangles>
                <triangle v1="0" v2="1" v3="2"/>
              </triangles>
            </mesh>
          </object>
        </resources>
        <build>
          <item objectid="1"/>
        </build>
      </model>
    XML
  end

  test "should parse valid 3MF file" do
    create_3mf_file
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_kind_of Hash, metadata
  end

  test "should raise ParseError for non-existent file" do
    parser = ThreeMfParser.new("/nonexistent/file.3mf")

    assert_raises(ThreeMfParser::ParseError) do
      parser.parse
    end
  end

  test "should raise ParseError for invalid ZIP file" do
    # Create a file that's not a valid ZIP
    @temp_file.write("This is not a ZIP file")
    @temp_file.rewind

    parser = ThreeMfParser.new(@temp_file.path)

    assert_raises(ThreeMfParser::ParseError) do
      parser.parse
    end
  end

  test "should extract PrusaSlicer print time from seconds" do
    create_3mf_file("prusaslicer:print_time" => "7200") # 2 hours in seconds
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal 120.0, metadata[:print_time] # 120 minutes
  end

  test "should extract print time in HH:MM:SS format" do
    create_3mf_file("print_time" => "02:30:00")
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal 150.0, metadata[:print_time] # 150 minutes
  end

  test "should extract print time in human readable format" do
    create_3mf_file("print_time" => "2h 15m 30s")
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal 135.5, metadata[:print_time] # 135.5 minutes
  end

  test "should extract filament weight in grams" do
    create_3mf_file("prusaslicer:filament_used" => "75.5g")
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal 75.5, metadata[:filament_weight]
  end

  test "should extract filament weight in kilograms" do
    create_3mf_file("filament_weight" => "0.5kg")
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal 500.0, metadata[:filament_weight]
  end

  test "should extract filament weight without unit" do
    create_3mf_file("total_filament_used" => "125.5")
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal 125.5, metadata[:filament_weight]
  end

  test "should extract material type" do
    create_3mf_file("prusaslicer:material_type" => "PLA")
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal "PLA", metadata[:material_type]
  end

  test "should extract layer height" do
    create_3mf_file("prusaslicer:layer_height" => "0.2")
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal 0.2, metadata[:layer_height]
  end

  test "should extract nozzle diameter" do
    create_3mf_file("prusaslicer:nozzle_diameter" => "0.4")
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal 0.4, metadata[:nozzle_diameter]
  end

  test "should extract multiple metadata fields" do
    create_3mf_file(
      "prusaslicer:print_time" => "5400",
      "prusaslicer:filament_used" => "50.0g",
      "prusaslicer:material_type" => "PETG",
      "prusaslicer:layer_height" => "0.15"
    )
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal 90.0, metadata[:print_time] # 90 minutes
    assert_equal 50.0, metadata[:filament_weight]
    assert_equal "PETG", metadata[:material_type]
    assert_equal 0.15, metadata[:layer_height]
  end

  test "should extract mesh vertex count" do
    create_3mf_file
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal 3, metadata[:vertex_count]
  end

  test "should extract mesh triangle count" do
    create_3mf_file
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal 1, metadata[:triangle_count]
  end

  test "should calculate bounding box from vertices" do
    create_3mf_file
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert metadata[:bounding_box]
    bbox = metadata[:bounding_box]

    assert_equal 0.0, bbox[:min_x]
    assert_equal 10.0, bbox[:max_x]
    assert_equal 0.0, bbox[:min_y]
    assert_equal 10.0, bbox[:max_y]
    assert_equal 0.0, bbox[:min_z]
    assert_equal 5.0, bbox[:max_z]
    assert_equal 10.0, bbox[:width]
    assert_equal 10.0, bbox[:depth]
    assert_equal 5.0, bbox[:height]
  end

  test "should handle Cura metadata field names" do
    create_3mf_file(
      "cura:time" => "3600",
      "cura:material_weight" => "40.5g"
    )
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal 60.0, metadata[:print_time]
    assert_equal 40.5, metadata[:filament_weight]
  end

  test "should store unknown metadata fields" do
    create_3mf_file("custom:some_field" => "custom_value")
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal "custom_value", metadata[:"custom:some_field"]
  end

  test "should handle empty metadata gracefully" do
    create_3mf_file
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    # Should still parse successfully with mesh data
    assert metadata[:vertex_count]
    assert metadata[:triangle_count]
  end

  test "should handle malformed time values" do
    create_3mf_file("print_time" => "invalid_time")
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    # Should not crash, just skip the invalid value
    assert_nil metadata[:print_time]
  end

  test "should handle malformed weight values" do
    create_3mf_file("filament_weight" => "not_a_number")
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    # Should not crash, just skip the invalid value
    assert_nil metadata[:filament_weight]
  end

  # Resin-specific tests
  test "should extract resin volume in milliliters" do
    create_3mf_file("resin_volume" => "25.5ml")
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal 25.5, metadata[:resin_volume_ml]
  end

  test "should extract resin volume in liters" do
    create_3mf_file("resin_volume" => "0.05l")
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal 50.0, metadata[:resin_volume_ml]
  end

  test "should extract resin volume without unit" do
    create_3mf_file("material_volume" => "30.0")
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal 30.0, metadata[:resin_volume_ml]
  end

  test "should extract resin type" do
    create_3mf_file("resin_type" => "ABS-Like")
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal "ABS-Like", metadata[:material_type]
    assert_equal "ABS-Like", metadata[:resin_type]
  end

  test "should extract exposure time" do
    create_3mf_file("exposure_time" => "2.5")
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal 2.5, metadata[:exposure_time]
  end

  test "should extract bottom layers" do
    create_3mf_file("bottom_layers" => "5")
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal 5, metadata[:bottom_layers]
  end

  test "should extract lift height and speed" do
    create_3mf_file(
      "lift_height" => "5.0",
      "lift_speed" => "60.0"
    )
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal 5.0, metadata[:lift_height]
    assert_equal 60.0, metadata[:lift_speed]
  end

  test "should detect FDM material technology from filament data" do
    create_3mf_file(
      "filament_weight" => "50.0g",
      "nozzle_diameter" => "0.4"
    )
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal "fdm", metadata[:material_technology]
  end

  test "should detect resin material technology from resin data" do
    create_3mf_file(
      "resin_volume" => "25.0ml",
      "exposure_time" => "2.5",
      "bottom_layers" => "5"
    )
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal "resin", metadata[:material_technology]
  end

  test "should default to FDM when no clear indicators" do
    create_3mf_file("layer_height" => "0.2")
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal "fdm", metadata[:material_technology]
  end

  test "should extract multiple resin metadata fields" do
    create_3mf_file(
      "print_time" => "7200",
      "resin_volume" => "35.5ml",
      "resin_type" => "Tough",
      "exposure_time" => "3.0",
      "bottom_layers" => "6",
      "layer_height" => "0.05"
    )
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    assert_equal 120.0, metadata[:print_time]
    assert_equal 35.5, metadata[:resin_volume_ml]
    assert_equal "Tough", metadata[:resin_type]
    assert_equal 3.0, metadata[:exposure_time]
    assert_equal 6, metadata[:bottom_layers]
    assert_equal 0.05, metadata[:layer_height]
    assert_equal "resin", metadata[:material_technology]
  end

  test "should handle malformed volume values" do
    create_3mf_file("resin_volume" => "not_a_number")
    parser = ThreeMfParser.new(@temp_file.path)
    metadata = parser.parse

    # Should not crash, just skip the invalid value
    assert_nil metadata[:resin_volume_ml]
  end
end
