require "zip"
require "nokogiri"

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
    detect_material_technology
    @metadata
  end

  private

  # Validation methods
  def validate_file!
    raise ParseError, "File does not exist: #{@file_path}" unless File.exist?(@file_path)
    raise ParseError, "File is not a valid ZIP archive" unless valid_zip?
  end

  def valid_zip?
    Zip::File.open(@file_path) do |zip_file|
      # Must contain the main model file
      return zip_file.find_entry("3D/3dmodel.model").present?
    end
  rescue Zip::Error => e
    false
  end

  # Extraction methods
  def extract_metadata
    Zip::File.open(@file_path) do |zip_file|
      model_entry = find_main_model_entry(zip_file)
      raise ParseError, "No 3D model file found in 3MF archive" unless model_entry

      xml_content = model_entry.get_input_stream.read
      doc = Nokogiri::XML(xml_content) do |config|
        config.strict.nonet.noent
      end

      extract_slicer_metadata(doc)
    end
  end

  def find_main_model_entry(zip_file)
    zip_file.find_entry("3D/3dmodel.model")
  end

  def extract_slicer_metadata(doc)
    # Extract all metadata elements
    doc.xpath("//metadata").each do |node|
      name = node["name"]
      value = node.text.strip
      next if name.blank? || value.blank?

      process_metadata_field(name, value)
    end

    # Also check for metadata in different namespaces
    extract_prusa_metadata(doc)
    extract_cura_metadata(doc)
    extract_resin_metadata(doc)
  end

  def process_metadata_field(name, value)
    normalized_name = name.downcase

    case normalized_name
    # Time fields
    when /print.*time|estimated.*time|time/
      @metadata[:print_time] = parse_time_value(value) if @metadata[:print_time].nil?

    # FDM fields
    when /filament.*weight|material.*weight/
      @metadata[:filament_weight] = parse_weight_value(value)
    when /material.*type|filament.*type/
      @metadata[:material_type] = value
    when /nozzle.*diameter|nozzle/
      @metadata[:nozzle_diameter] = value.to_f
    when /layer.*height/
      @metadata[:layer_height] = value.to_f

    # Resin fields
    when /resin.*volume|volume.*ml/
      @metadata[:resin_volume_ml] = parse_volume_value(value)
    when /resin.*type|resin.*material/
      @metadata[:resin_type] = value
    when /exposure.*time/
      @metadata[:exposure_time] = value.to_f
    when /bottom.*layers|base.*layers/
      @metadata[:bottom_layers] = value.to_i
    when /lift.*height/
      @metadata[:lift_height] = value.to_f
    when /lift.*speed/
      @metadata[:lift_speed] = value.to_f
    end
  end

  def extract_prusa_metadata(doc)
    # PrusaSlicer specific metadata (already handled by generic extraction)
    # PrusaSlicer uses standard metadata tags like:
    # - prusaslicer:print_time
    # - prusaslicer:filament_weight
    # - prusaslicer:material_type
    # These are caught by the generic process_metadata_field method
  end

  def extract_cura_metadata(doc)
    # Cura specific metadata
    # Cura uses slightly different naming conventions:
    # - time (print time in seconds)
    # - material_weight (filament weight)
    # - material (material type)
    # These are also caught by the generic process_metadata_field method
  end

  def extract_resin_metadata(doc)
    # Chitubox and Lychee Slicer specific metadata
    # These already use standard naming that gets caught by generic extraction
  end

  # Parsing helper methods
  def parse_time_value(value)
    return nil if value.blank?

    # Remove all whitespace for easier parsing
    cleaned = value.strip

    # Format 1: Pure seconds (most common) - "7200"
    if cleaned.match?(/^\d+(\.\d+)?$/)
      return cleaned.to_f / 60.0  # Convert seconds to minutes
    end

    # Format 2: HH:MM:SS - "02:15:30"
    if cleaned.match?(/^(\d+):(\d+):(\d+)$/)
      hours, minutes, seconds = cleaned.split(":").map(&:to_i)
      return (hours * 60) + minutes + (seconds / 60.0)
    end

    # Format 3: Human readable - "2h 15m 30s" or "2h 15m" or "135m"
    total_minutes = 0.0

    # Extract hours
    if cleaned.match?(/(\d+)\s*h/)
      total_minutes += $1.to_i * 60
    end

    # Extract minutes
    if cleaned.match?(/(\d+)\s*m/)
      total_minutes += $1.to_i
    end

    # Extract seconds
    if cleaned.match?(/(\d+)\s*s/)
      total_minutes += $1.to_i / 60.0
    end

    total_minutes > 0 ? total_minutes : nil
  end

  def parse_weight_value(value)
    return nil if value.blank?

    cleaned = value.downcase.strip

    # Remove all non-numeric characters except decimal point
    numeric_value = cleaned.gsub(/[^\d.]/, "").to_f

    # Check for unit indicators
    if cleaned.include?("kg")
      numeric_value * 1000  # Convert kg to grams
    else
      numeric_value  # Assume grams
    end
  end

  def parse_volume_value(value)
    return nil if value.blank?

    cleaned = value.downcase.strip

    # Remove all non-numeric characters except decimal point
    numeric_value = cleaned.gsub(/[^\d.]/, "").to_f

    # Check for unit indicators
    if cleaned.include?("l") && !cleaned.include?("ml")
      numeric_value * 1000  # Convert liters to ml
    else
      numeric_value  # Assume ml
    end
  end

  # Technology detection
  def detect_material_technology
    # Heuristic based on metadata keys
    has_resin_indicators = @metadata[:resin_volume_ml].present? ||
                          @metadata[:resin_type].present? ||
                          @metadata[:exposure_time].present? ||
                          @metadata[:bottom_layers].present?

    has_fdm_indicators = @metadata[:filament_weight].present? ||
                        @metadata[:nozzle_diameter].present? ||
                        (@metadata[:material_type].present? && !@metadata[:resin_type].present?)

    if has_resin_indicators
      @metadata[:material_technology] = "resin"
    elsif has_fdm_indicators
      @metadata[:material_technology] = "fdm"
    else
      # Default to FDM if ambiguous
      @metadata[:material_technology] = "fdm"
    end
  end
end
