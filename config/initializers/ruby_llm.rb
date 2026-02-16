# frozen_string_literal: true

if defined?(RubyLLM)
  RubyLLM.configure do |config|
    openrouter_key = ENV["OPENROUTER_API_KEY"].presence || ENV["OPENROUTER_TRANSLATION_KEY"].presence
    config.openrouter_api_key = openrouter_key if openrouter_key.present?
    config.default_model = ENV.fetch("SETUP_ASSISTANT_MODEL", "openrouter/google/gemini-2.0-flash-lite-001")
  end
end
