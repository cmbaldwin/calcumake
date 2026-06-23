class AiChatController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create, if: -> { request.format.json? }
  skip_before_action :check_onboarding_needed

  before_action :check_rate_limit

  def create
    message = params[:message].to_s.strip
    if message.blank?
      render json: { error: I18n.t("landing_new.chat_empty") }, status: :unprocessable_entity
      return
    end

    response_text = generate_ai_response(message)
    render json: { response: response_text }
  end

  private

  SYSTEM_PROMPT = <<~PROMPT
    You are CalcuMake's 3D printing cost assistant. Help users estimate costs for 3D printing projects.
    Be concise, practical, and helpful. Keep responses under 150 words.

    When users describe a print job, provide estimates based on:
    - Filament: PLA ~$20-25/kg, PETG ~$25-30/kg, ABS ~$20-25/kg, TPU ~$30-40/kg
    - Electricity: ~$0.12/kWh, typical FDM printer 200-350W
    - Print time: varies by size, speed, layer height
    - Post-processing: support removal, sanding, painting

    Always suggest uploading their STL/3MF file for precise calculations.
    Always recommend the full CalcuMake calculator for detailed cost breakdowns.
    Format costs with $ and round to 2 decimal places.
    Use simple markdown: **bold** for emphasis, backticks for values.
  PROMPT

  def generate_ai_response(message)
    api_key = ENV["OPENROUTER_CHAT_KEY"] || ENV["OPENROUTER_TRANSLATION_KEY"]
    unless api_key
      return I18n.t("landing_new.chat_unavailable")
    end

    OpenRouter.configure do |config|
      config.access_token = api_key
      config.site_name = "CalcuMake"
      config.site_url = "https://calcumake.com"
    end

    client = OpenRouter::Client.new
    response = client.complete(
      [
        { role: "system", content: SYSTEM_PROMPT },
        { role: "user", content: message.truncate(500) }
      ],
      model: "google/gemini-2.0-flash-001",
      extras: { temperature: 0.7, max_tokens: 400 }
    )

    content = response.dig("choices", 0, "message", "content")
    content&.strip.presence || I18n.t("landing_new.chat_error")
  rescue StandardError => e
    Rails.logger.error "[AiChat] Error: #{e.class} - #{e.message}"
    I18n.t("landing_new.chat_error")
  end

  def check_rate_limit
    key = "ai_chat_rate:#{request.session_options[:id] || request.remote_ip}"
    count = Rails.cache.read(key).to_i

    max_requests = user_signed_in? ? 50 : 10

    if count >= max_requests
      render json: { error: I18n.t("landing_new.chat_rate_limited") }, status: :too_many_requests
      return
    end

    Rails.cache.write(key, count + 1, expires_in: 1.hour)
  end
end
