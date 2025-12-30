# frozen_string_literal: true

require "open-uri"

# Service class for importing filaments from various sources using LLM
class FilamentImporter
  VALID_MATERIAL_TYPES = %w[PLA ABS PETG TPU ASA HIPS Nylon PC PVA Wood Metal Carbon Resin].freeze
  VALID_DIAMETERS = [ 1.75, 2.85, 3.0 ].freeze

  attr_reader :user, :source_type, :source_content, :errors

  def initialize(user, source_type:, source_content:)
    @user = user
    @source_type = source_type # "url" or "text"
    @source_content = source_content
    @errors = []
  end

  def import
    return false unless valid_input?

    content = fetch_content
    return false if content.blank?

    filaments_data = extract_filaments_from_content(content)
    return false if filaments_data.blank?

    create_filaments(filaments_data)
  end

  private

  def valid_input?
    if source_content.blank?
      @errors << "Source content cannot be blank"
      return false
    end

    if source_type == "url" && !valid_url?(source_content)
      @errors << "Invalid URL format"
      return false
    end

    true
  end

  def valid_url?(url)
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end

  def fetch_content
    case source_type
    when "url"
      fetch_url_content
    when "text"
      source_content
    else
      @errors << "Invalid source type"
      nil
    end
  rescue StandardError => e
    @errors << "Failed to fetch content: #{e.message}"
    nil
  end

  def fetch_url_content
    # Fetch content from URL with timeout
    URI.open(
      source_content,
      redirect: true,
      open_timeout: 10,
      read_timeout: 30,
      &:read
    )
  rescue OpenURI::HTTPError, SocketError, Net::OpenTimeout, Net::ReadTimeout => e
    @errors << "Failed to fetch URL: #{e.message}"
    nil
  end

  def extract_filaments_from_content(content)
    return [] unless openrouter_configured?

    prompt = build_extraction_prompt(content)
    response = call_openrouter(prompt)

    parse_llm_response(response)
  rescue StandardError => e
    @errors << "LLM extraction failed: #{e.message}"
    []
  end

  def openrouter_configured?
    api_key = ENV["OPENROUTER_API_KEY"] || ENV["OPENROUTER_TRANSLATION_KEY"]
    if api_key.blank?
      @errors << "OpenRouter API key not configured"
      return false
    end
    true
  end

  def build_extraction_prompt(content)
    <<~PROMPT
      You are a 3D printing filament data extraction assistant. Extract filament information from the following text.
      The text may be from an invoice, receipt, product page, or plain text description.

      Valid material types: #{VALID_MATERIAL_TYPES.join(", ")}
      Valid diameters (mm): #{VALID_DIAMETERS.join(", ")}

      Extract as many filaments as you can find. For each filament, provide:
      - name: Product name or model (required)
      - brand: Manufacturer/brand name (optional)
      - material_type: One of the valid types listed above (required)
      - diameter: One of the valid diameters (default: 1.75)
      - color: Color name (optional)
      - spool_weight: Weight in grams (optional)
      - spool_price: Price in the currency mentioned (optional)
      - print_temperature_min: Minimum printing temperature in Celsius (optional)
      - print_temperature_max: Maximum printing temperature in Celsius (optional)
      - heated_bed_temperature: Bed temperature in Celsius (optional)
      - notes: Any additional relevant information (optional)

      Respond with ONLY a valid JSON array of filament objects. Example:
      [
        {
          "name": "Premium PLA",
          "brand": "eSun",
          "material_type": "PLA",
          "diameter": 1.75,
          "color": "Red",
          "spool_weight": 1000,
          "spool_price": 25.99,
          "print_temperature_min": 190,
          "print_temperature_max": 220,
          "heated_bed_temperature": 60,
          "notes": "High quality filament"
        }
      ]

      If no filaments can be extracted, respond with an empty array: []

      Content to analyze:
      #{content.truncate(4000)}
    PROMPT
  end

  def call_openrouter(prompt)
    api_key = ENV["OPENROUTER_API_KEY"] || ENV["OPENROUTER_TRANSLATION_KEY"]

    client = OpenRouter::Client.new do |config|
      config.access_token = api_key
    end

    # Use a fast, capable model (GPT-4 Turbo or Claude Haiku)
    response = client.chat(
      model: "anthropic/claude-3.5-haiku",
      messages: [
        { role: "user", content: prompt }
      ]
    )

    response.dig("choices", 0, "message", "content")
  end

  def parse_llm_response(response)
    return [] if response.blank?

    # Try to extract JSON from markdown code blocks if present
    json_match = response.match(/```(?:json)?\s*(\[.*?\])\s*```/m)
    json_string = json_match ? json_match[1] : response

    filaments = JSON.parse(json_string)

    # Validate and normalize each filament
    filaments.map { |f| normalize_filament_data(f) }.compact
  rescue JSON::ParserError => e
    @errors << "Failed to parse LLM response as JSON: #{e.message}"
    []
  end

  def normalize_filament_data(data)
    # Ensure required fields are present
    return nil if data["name"].blank? || data["material_type"].blank?

    # Normalize material type
    material_type = VALID_MATERIAL_TYPES.find { |t| t.casecmp?(data["material_type"]) }
    return nil if material_type.nil?

    # Normalize diameter
    diameter = data["diameter"].to_f
    diameter = 1.75 unless VALID_DIAMETERS.include?(diameter)

    {
      name: data["name"],
      brand: data["brand"],
      material_type: material_type,
      diameter: diameter,
      color: data["color"],
      density: data["density"]&.to_f,
      spool_weight: data["spool_weight"]&.to_f,
      spool_price: data["spool_price"]&.to_f,
      print_temperature_min: data["print_temperature_min"]&.to_i,
      print_temperature_max: data["print_temperature_max"]&.to_i,
      heated_bed_temperature: data["heated_bed_temperature"]&.to_i,
      print_speed_max: data["print_speed_max"]&.to_i,
      finish: data["finish"],
      storage_temperature_max: data["storage_temperature_max"]&.to_i,
      moisture_sensitive: data["moisture_sensitive"],
      notes: data["notes"]
    }.compact
  end

  def create_filaments(filaments_data)
    created_filaments = []

    filaments_data.each do |data|
      # Check if filament with same name already exists
      existing = user.filaments.find_by(name: data[:name])

      if existing
        # Append a number to make it unique
        counter = 1
        new_name = "#{data[:name]} (#{counter})"
        while user.filaments.exists?(name: new_name)
          counter += 1
          new_name = "#{data[:name]} (#{counter})"
        end
        data[:name] = new_name
      end

      filament = user.filaments.build(data)
      if filament.save
        created_filaments << filament
      else
        @errors << "Failed to create filament '#{data[:name]}': #{filament.errors.full_messages.join(", ")}"
      end
    end

    created_filaments
  end
end
