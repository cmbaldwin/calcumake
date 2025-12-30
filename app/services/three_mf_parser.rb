require "zip"

class ThreeMfParser
  class ParseError < StandardError; end

  attr_reader :file_path, :metadata

  def initialize(file_path)
    @file_path = file_path
    @metadata = {}
  end

  def parse
    validate_file!
    extract_metadata
    extract_model_data
    detect_material_technology
    @metadata
  rescue => e
    raise ParseError, "Failed to parse 3MF file: #{e.message}"
  end

  private

  def validate_file!
    raise ParseError, "File not found: #{file_path}" unless File.exist?(file_path)
    raise ParseError, "File is not a valid ZIP archive" unless valid_zip?
  end

  def valid_zip?
    Zip::File.open(file_path) { true }
  rescue
    false
  end

  def extract_metadata
    Zip::File.open(file_path) do |zip_file|
      # Extract metadata from various sources
      extract_core_metadata(zip_file)
      extract_slicer_metadata(zip_file)
      extract_model_relationships(zip_file)
    end
  end

  def extract_core_metadata(zip_file)
    # Try to find and parse metadata XML
    metadata_entry = zip_file.find_entry("Metadata/model_metadata.xml") ||
                     zip_file.find_entry("metadata/model_metadata.xml")

    return unless metadata_entry

    xml_content = metadata_entry.get_input_stream.read
    doc = Nokogiri::XML(xml_content)

    # Extract metadata elements
    doc.xpath("//metadata").each do |metadata_node|
      name = metadata_node["name"]
      value = metadata_node.text
      @metadata[name.to_sym] = value if name.present?
    end
  end

  def extract_slicer_metadata(zip_file)
    # PrusaSlicer and other slicers often include metadata in the model file
    # or in custom metadata files
    model_entry = find_main_model_entry(zip_file)
    return unless model_entry

    xml_content = model_entry.get_input_stream.read
    doc = Nokogiri::XML(xml_content)

    # Register namespaces
    namespaces = doc.collect_namespaces

    # Extract metadata from model file
    doc.xpath("//metadata", namespaces).each do |metadata_node|
      name = metadata_node["name"]
      value = metadata_node.text.strip
      store_metadata(name, value) if name.present? && value.present?
    end

    # Try to extract PrusaSlicer-specific metadata
    extract_prusa_metadata(doc, namespaces)
    # Try to extract Cura-specific metadata
    extract_cura_metadata(doc, namespaces)
    # Try to extract resin slicer metadata
    extract_resin_metadata(doc, namespaces)
  end

  def find_main_model_entry(zip_file)
    # The main model is usually at 3D/3dmodel.model
    zip_file.find_entry("3D/3dmodel.model") ||
    zip_file.find_entry("3D/3DModel.model") ||
    zip_file.find_entry("3dmodel.model")
  end

  def extract_prusa_metadata(doc, namespaces)
    # PrusaSlicer stores metadata in custom namespace
    # Look for common metadata fields
    [
      "estimated_printing_time",
      "print_time",
      "total_filament_used",
      "filament_used",
      "filament_weight",
      "material_type",
      "layer_height",
      "nozzle_diameter"
    ].each do |field|
      extract_metadata_field(doc, namespaces, field)
    end
  end

  def extract_resin_metadata(doc, namespaces)
    # Resin slicers (Chitubox, Lychee Slicer, etc.) store resin-specific metadata
    # Look for common resin metadata fields
    [
      "resin_volume",
      "resin_type",
      "resin_material",
      "material_volume",
      "volume_ml",
      "exposure_time",
      "layer_height",
      "bottom_layers",
      "lift_height",
      "lift_speed"
    ].each do |field|
      extract_metadata_field(doc, namespaces, field)
    end
  end

  def extract_cura_metadata(doc, namespaces)
    # Cura may use different field names
    [
      "time",
      "material",
      "material_weight"
    ].each do |field|
      extract_metadata_field(doc, namespaces, field)
    end
  end

  def extract_metadata_field(doc, namespaces, field_name)
    # Try various XPath queries to find the metadata
    value = doc.xpath("//metadata[@name='#{field_name}']", namespaces).first&.text ||
            doc.xpath("//metadata[@name='slic3r:#{field_name}']", namespaces).first&.text ||
            doc.xpath("//metadata[@name='prusaslicer:#{field_name}']", namespaces).first&.text ||
            doc.xpath("//metadata[@name='cura:#{field_name}']", namespaces).first&.text

    store_metadata(field_name, value) if value.present?
  end

  def store_metadata(name, value)
    # Normalize common metadata field names
    case name.downcase
    when "estimated_printing_time", "print_time", "time"
      @metadata[:print_time] = parse_time_value(value)
    when "total_filament_used", "filament_used", "filament_weight", "material_weight"
      @metadata[:filament_weight] = parse_weight_value(value)
    when "resin_volume", "material_volume", "volume_ml"
      @metadata[:resin_volume_ml] = parse_volume_value(value)
    when "material_type", "material", "resin_type", "resin_material"
      # Store as both material_type and resin_type for compatibility
      material = value.strip
      @metadata[:material_type] = material
      @metadata[:resin_type] = material if name.downcase.include?("resin")
    when "layer_height"
      @metadata[:layer_height] = value.to_f
    when "nozzle_diameter"
      @metadata[:nozzle_diameter] = value.to_f
    when "exposure_time"
      @metadata[:exposure_time] = value.to_f
    when "bottom_layers"
      @metadata[:bottom_layers] = value.to_i
    when "lift_height"
      @metadata[:lift_height] = value.to_f
    when "lift_speed"
      @metadata[:lift_speed] = value.to_f
    else
      # Store unknown metadata for potential future use
      @metadata[name.to_sym] = value
    end
  end

  def parse_time_value(value)
    # Time can be in various formats:
    # - Seconds: "7200"
    # - HH:MM:SS: "02:00:00"
    # - Human readable: "2h 15m 30s"
    return nil unless value.present?

    value = value.to_s.strip

    # Try to parse as seconds first
    if value =~ /^\d+$/
      return value.to_i / 60.0 # Convert seconds to minutes
    end

    # Try HH:MM:SS format
    if value =~ /^(\d+):(\d+):(\d+)$/
      hours, minutes, seconds = $1.to_i, $2.to_i, $3.to_i
      return (hours * 60) + minutes + (seconds / 60.0)
    end

    # Try human readable format
    hours = value.scan(/(\d+)\s*h/i).flatten.first.to_i
    minutes = value.scan(/(\d+)\s*m/i).flatten.first.to_i
    seconds = value.scan(/(\d+)\s*s/i).flatten.first.to_i

    if hours > 0 || minutes > 0 || seconds > 0
      return (hours * 60) + minutes + (seconds / 60.0)
    end

    nil
  end

  def parse_weight_value(value)
    # Weight can be in various formats:
    # - Grams: "50.5g"
    # - Kilograms: "0.05kg"
    # - Just number: "50.5"
    return nil unless value.present?

    value = value.to_s.strip

    # Remove common units and convert to grams
    if value =~ /(\d+\.?\d*)\s*kg/i
      return $1.to_f * 1000
    elsif value =~ /(\d+\.?\d*)\s*g/i
      return $1.to_f
    elsif value =~ /^(\d+\.?\d*)$/
      # Assume grams if no unit
      return $1.to_f
    end

    nil
  end

  def parse_volume_value(value)
    # Volume can be in various formats:
    # - Milliliters: "50.5ml"
    # - Liters: "0.05l"
    # - Just number: "50.5"
    return nil unless value.present?

    value = value.to_s.strip

    # Remove common units and convert to milliliters
    if value =~ /(\d+\.?\d*)\s*l/i
      return $1.to_f * 1000
    elsif value =~ /(\d+\.?\d*)\s*ml/i
      return $1.to_f
    elsif value =~ /^(\d+\.?\d*)$/
      # Assume milliliters if no unit
      return $1.to_f
    end

    nil
  end

  def detect_material_technology
    # Detect whether this is FDM or resin based on extracted metadata
    # Resin indicators: resin_volume_ml, exposure_time, bottom_layers, lift_height
    # FDM indicators: filament_weight, nozzle_diameter, extrusion_width

    resin_indicators = [
      @metadata[:resin_volume_ml].present?,
      @metadata[:exposure_time].present?,
      @metadata[:bottom_layers].present?,
      @metadata[:lift_height].present?,
      @metadata[:lift_speed].present?,
      @metadata[:resin_type].present?
    ].count(true)

    fdm_indicators = [
      @metadata[:filament_weight].present?,
      @metadata[:nozzle_diameter].present?
    ].count(true)

    # If we have more resin indicators, it's a resin print
    # Otherwise default to FDM
    if resin_indicators > fdm_indicators && resin_indicators > 0
      @metadata[:material_technology] = "resin"
    else
      @metadata[:material_technology] = "fdm"
    end
  end

  def extract_model_data
    Zip::File.open(file_path) do |zip_file|
      model_entry = find_main_model_entry(zip_file)
      return unless model_entry

      xml_content = model_entry.get_input_stream.read
      doc = Nokogiri::XML(xml_content)
      namespaces = doc.collect_namespaces

      # Extract mesh data for calculating volume/bounding box if needed
      extract_mesh_info(doc, namespaces)
    end
  end

  def extract_mesh_info(doc, namespaces)
    # Extract basic mesh information
    vertices = doc.xpath("//vertex", namespaces)
    triangles = doc.xpath("//triangle", namespaces)

    @metadata[:vertex_count] = vertices.count
    @metadata[:triangle_count] = triangles.count

    # Calculate bounding box if we have vertices
    if vertices.any?
      calculate_bounding_box(vertices)
    end
  end

  def calculate_bounding_box(vertices)
    x_coords = []
    y_coords = []
    z_coords = []

    vertices.each do |vertex|
      x_coords << vertex["x"].to_f if vertex["x"]
      y_coords << vertex["y"].to_f if vertex["y"]
      z_coords << vertex["z"].to_f if vertex["z"]
    end

    if x_coords.any? && y_coords.any? && z_coords.any?
      @metadata[:bounding_box] = {
        min_x: x_coords.min,
        max_x: x_coords.max,
        min_y: y_coords.min,
        max_y: y_coords.max,
        min_z: z_coords.min,
        max_z: z_coords.max,
        width: x_coords.max - x_coords.min,
        depth: y_coords.max - y_coords.min,
        height: z_coords.max - z_coords.min
      }
    end
  end

  def extract_model_relationships(zip_file)
    # Extract relationship information from _rels/.rels
    rels_entry = zip_file.find_entry("_rels/.rels")
    return unless rels_entry

    xml_content = rels_entry.get_input_stream.read
    doc = Nokogiri::XML(xml_content)

    # Store relationship information for reference
    relationships = []
    doc.xpath("//Relationship").each do |rel|
      relationships << {
        id: rel["Id"],
        type: rel["Type"],
        target: rel["Target"]
      }
    end

    @metadata[:relationships] = relationships if relationships.any?
  end
end
