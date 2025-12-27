# frozen_string_literal: true

# Weekly job to discover and add new 3D printer models using AI
# Scheduled to run every Sunday at 3am UTC via recurring.yml
class UpdatePrinterProfilesJob < ApplicationJob
  queue_as :default

  # Retry up to 3 times with exponential backoff
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform
    return unless api_key_available?

    Rails.logger.info "[PrinterProfiles] Starting weekly update..."

    existing_manufacturers = PrinterProfile.distinct.pluck(:manufacturer)
    existing_models = PrinterProfile.pluck(:manufacturer, :model).map { |m, mod| "#{m} #{mod}" }

    prompt = build_prompt(existing_manufacturers, existing_models)

    response = call_api(prompt)
    new_printers = parse_response(response)

    created_count = 0
    new_printers.each do |printer|
      next if printer[:manufacturer].blank? || printer[:model].blank?

      profile = PrinterProfile.find_or_initialize_by(
        manufacturer: printer[:manufacturer],
        model: printer[:model]
      )

      # Only create new profiles, don't update existing ones
      next unless profile.new_record?

      profile.assign_attributes(
        category: normalize_category(printer[:category]),
        technology: normalize_technology(printer[:technology]),
        power_consumption_avg_watts: printer[:power_avg],
        power_consumption_peak_watts: printer[:power_peak],
        cost_usd: printer[:cost_usd],
        source: "AI-generated #{Date.current}",
        verified: false
      )

      if profile.save
        created_count += 1
        Rails.logger.info "[PrinterProfiles] Added: #{profile.display_name}"
      else
        Rails.logger.warn "[PrinterProfiles] Failed to save #{profile.display_name}: #{profile.errors.full_messages.join(', ')}"
      end
    end

    Rails.logger.info "[PrinterProfiles] Update complete. Added #{created_count} new printers (total: #{PrinterProfile.count})"
  end

  private

  def api_key_available?
    api_key = ENV.fetch("OPENROUTER_TRANSLATION_KEY", nil)
    if api_key.blank?
      Rails.logger.info "[PrinterProfiles] Skipping update - OPENROUTER_TRANSLATION_KEY not configured"
      false
    else
      true
    end
  end

  def call_api(prompt)
    client = OpenRouter::Client.new(access_token: ENV.fetch("OPENROUTER_TRANSLATION_KEY"))

    client.complete(
      [ { role: "user", content: prompt } ],
      model: "google/gemini-2.0-flash-001",
      extras: { temperature: 0.3, max_tokens: 4000 }
    )
  end

  def build_prompt(manufacturers, existing_models)
    <<~PROMPT
      You are a 3D printing expert with comprehensive knowledge of consumer and prosumer 3D printers.

      I need you to list NEW 3D printers that have been released or announced this year #{Time.current.year} or next year #{Time.current.year + 1}.

      EXISTING PRINTERS (do not include these):
      #{existing_models.take(50).join("\n")}

      For each NEW printer, provide a JSON object with these exact fields:
      - manufacturer (string): The brand/company name
      - model (string): The model name/number
      - category (string): One of: "Budget FDM", "Mid-Range FDM", "Premium FDM", "Professional FDM", "Budget Resin", "Mid-Range Resin", "Professional Resin"
      - technology (string): Either "fdm" or "resin"
      - power_avg (integer): Average power consumption in watts during printing
      - power_peak (integer): Peak power consumption in watts
      - cost_usd (number): MSRP in USD

      Guidelines:
      - Only include printers with verified specifications from manufacturer websites or reputable reviews
      - Focus on printers from major manufacturers: #{manufacturers.take(10).join(', ')}, and similar
      - Include printers released in this year or announced for release in 2024-2025
      - Ensure data accuracy; if unsure about a specification, omit that printer
      - Limit to 20 printers maximum
      - If power consumption is not available, estimate based on similar printers in the category

      Return ONLY a valid JSON array with no markdown formatting, no explanation, just the JSON:
    PROMPT
  end

  def parse_response(response)
    content = response.dig("choices", 0, "message", "content")
    return [] if content.blank?

    # Clean markdown code blocks if present
    content = content.gsub(/```json\n?/, "").gsub(/```\n?/, "").strip

    JSON.parse(content, symbolize_names: true)
  rescue JSON::ParserError => e
    Rails.logger.error "[PrinterProfiles] Failed to parse AI response: #{e.message}"
    Rails.logger.error "[PrinterProfiles] Response content: #{content&.first(500)}"
    []
  end

  def normalize_category(category)
    return nil if category.blank?

    valid_categories = PrinterProfile::CATEGORIES
    # Try exact match first
    return category if valid_categories.include?(category)

    # Try case-insensitive match
    matched = valid_categories.find { |c| c.downcase == category.downcase }
    matched || category
  end

  def normalize_technology(tech)
    return "fdm" if tech.blank?

    tech_str = tech.to_s.downcase
    case tech_str
    when "fdm", "fff"
      "fdm"
    when "resin", "sla", "dlp", "msla", "lcd"
      "resin"
    else
      "fdm"
    end
  end
end
