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
end
