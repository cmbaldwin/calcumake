# frozen_string_literal: true

require "json"
require "bigdecimal"

module Ai
  class SetupAssistant
    include Rails.application.routes.url_helpers

    MAX_MESSAGE_LENGTH = 1200
    MAX_ACTIONS = 3
    MAX_HISTORY_ITEMS = 8

    VALID_ACTION_TYPES = %w[
      create_printer
      create_filament
      create_resin
      update_user_preferences
      complete_onboarding
      none
    ].freeze

    FILAMENT_TYPES = %w[PLA ABS PETG TPU ASA HIPS Nylon PC PVA Wood Metal Carbon].freeze
    DEFAULT_MODEL = "openrouter/google/gemini-2.0-flash-lite-001"

    def initialize(user:, context: "app", onboarding_step: nil)
      @user = user
      @context = context.to_s
      @onboarding_step = onboarding_step.to_s
    end

    def call(message:, conversation: [])
      user_message = message.to_s.strip
      return error_response(I18n.t("setup_assistant.errors.blank_message")) if user_message.blank?
      return error_response(I18n.t("setup_assistant.errors.message_too_long", max: MAX_MESSAGE_LENGTH)) if user_message.length > MAX_MESSAGE_LENGTH

      plan = plan_from_llm(user_message, conversation)
      execution = execute_actions(plan[:actions])

      {
        ok: true,
        message: compose_reply(plan[:response], execution[:results]),
        actions: execution[:results],
        errors: execution[:errors],
        onboarding_ready: onboarding_step_ready?
      }
    rescue StandardError => e
      Rails.logger.error("[SetupAssistant] #{e.class}: #{e.message}")
      error_response(I18n.t("setup_assistant.errors.unavailable"))
    end

    private

    attr_reader :user, :context, :onboarding_step

    def error_response(message)
      {
        ok: false,
        message: message,
        actions: [],
        errors: [ message ],
        onboarding_ready: false
      }
    end

    def plan_from_llm(user_message, conversation)
      return fallback_plan(user_message) unless llm_available?

      raw_content = request_plan_from_llm(user_message, conversation)
      parsed = parse_plan_json(raw_content)
      return parsed if parsed

      fallback_plan(raw_content.presence || user_message)
    end

    def fallback_plan(content)
      {
        response: content.to_s.truncate(240).presence || I18n.t("setup_assistant.fallback_reply"),
        actions: []
      }
    end

    def llm_available?
      defined?(RubyLLM) && openrouter_api_key.present?
    end

    def openrouter_api_key
      ENV["OPENROUTER_API_KEY"].presence || ENV["OPENROUTER_TRANSLATION_KEY"].presence
    end

    def request_plan_from_llm(user_message, conversation)
      chat = RubyLLM.chat
      chat.with_model(assistant_model)
      chat.with_instructions(system_prompt)
      response = chat.ask(build_prompt(user_message, conversation))
      response.respond_to?(:content) ? response.content.to_s : response.to_s
    rescue StandardError => e
      Rails.logger.warn("[SetupAssistant] LLM request failed: #{e.class}: #{e.message}")
      nil
    end

    def assistant_model
      ENV.fetch("SETUP_ASSISTANT_MODEL", DEFAULT_MODEL)
    end

    def system_prompt
      <<~PROMPT
        You are CalcuMake Setup Assistant for a 3D printing business app.

        Return ONLY valid JSON with this exact shape:
        {
          "response": "short assistant message for the user",
          "actions": [
            {
              "type": "create_printer|create_filament|create_resin|update_user_preferences|complete_onboarding|none",
              "attributes": { "key": "value" }
            }
          ]
        }

        Rules:
        - Use actions only when the user explicitly asks you to do something.
        - If required fields are missing, do not create an action; ask a question in "response" instead.
        - Never output markdown or code fences.
        - Keep "response" short and actionable.
      PROMPT
    end

    def build_prompt(user_message, conversation)
      <<~PROMPT
        Context:
        - mode: #{context}
        - onboarding_step: #{onboarding_step.presence || "n/a"}
        - user_currency: #{user.default_currency}
        - energy_cost_per_kwh: #{user.default_energy_cost_per_kwh}
        - existing_printers: #{user.printers.order(:created_at).limit(20).pluck(:name).join(", ").presence || "none"}
        - existing_filaments: #{user.filaments.order(:created_at).limit(20).pluck(:name).join(", ").presence || "none"}
        - existing_resins: #{user.resins.order(:created_at).limit(20).pluck(:name).join(", ").presence || "none"}

        Recent conversation:
        #{serialize_conversation(conversation)}

        User message:
        #{user_message}
      PROMPT
    end

    def serialize_conversation(conversation)
      Array(conversation).last(MAX_HISTORY_ITEMS).filter_map do |item|
        role = item.is_a?(Hash) ? item["role"].to_s : ""
        content = item.is_a?(Hash) ? item["content"].to_s : ""
        next if role.blank? || content.blank?

        "#{role}: #{content.truncate(280)}"
      end.join("\n").presence || "none"
    end

    def parse_plan_json(raw_content)
      return nil if raw_content.blank?

      json_candidate = extract_json_object(raw_content)
      return nil if json_candidate.blank?

      parsed = JSON.parse(json_candidate)
      {
        response: parsed["response"].to_s.presence || I18n.t("setup_assistant.fallback_reply"),
        actions: normalize_actions(parsed["actions"])
      }
    rescue JSON::ParserError
      nil
    end

    def extract_json_object(raw_content)
      cleaned = raw_content.to_s.gsub(/```json/i, "").gsub(/```/, "").strip
      start_index = cleaned.index("{")
      end_index = cleaned.rindex("}")
      return nil unless start_index && end_index && end_index >= start_index

      cleaned[start_index..end_index]
    end

    def normalize_actions(actions)
      Array(actions).first(MAX_ACTIONS).filter_map do |action|
        next unless action.is_a?(Hash)

        type = action["type"].to_s
        next unless VALID_ACTION_TYPES.include?(type)
        next if type == "none"

        attributes = action["attributes"].is_a?(Hash) ? action["attributes"] : {}
        { type: type, attributes: attributes }
      end
    end

    def execute_actions(actions)
      results = []
      errors = []

      actions.each do |action|
        result = execute_action(action)
        results << result
        errors << result[:message] if result[:status] == "error"
      end

      { results: results, errors: errors }
    end

    def execute_action(action)
      case action[:type]
      when "create_printer"
        create_printer(action[:attributes])
      when "create_filament"
        create_filament(action[:attributes])
      when "create_resin"
        create_resin(action[:attributes])
      when "update_user_preferences"
        update_user_preferences(action[:attributes])
      when "complete_onboarding"
        complete_onboarding
      else
        { type: action[:type], status: "ignored", message: I18n.t("setup_assistant.action_ignored") }
      end
    end

    def create_printer(attributes)
      if attributes["preset_model"].present?
        return create_printer_from_preset(attributes["preset_model"])
      end

      name = clean_text(attributes["name"])
      return error_result("create_printer", I18n.t("setup_assistant.missing.printer_name")) if name.blank?
      return skipped_result("create_printer", I18n.t("setup_assistant.already_exists.printer", name: name)) if user.printers.exists?(name: name)

      printer = user.printers.build(
        name: name,
        manufacturer: normalize_manufacturer(attributes["manufacturer"]),
        material_technology: normalize_technology(attributes["material_technology"]),
        power_consumption: positive_integer(attributes["power_consumption"], default: 200),
        cost: positive_decimal(attributes["cost"], default: 500),
        daily_usage_hours: positive_integer(attributes["daily_usage_hours"], default: 8),
        payoff_goal_years: positive_integer(attributes["payoff_goal_years"], default: 2),
        repair_cost_percentage: non_negative_decimal(attributes["repair_cost_percentage"], default: 0)
      )

      if printer.save
        success_result("create_printer", I18n.t("setup_assistant.created.printer", name: printer.name), printer_path(printer))
      else
        error_result("create_printer", printer.errors.full_messages.to_sentence)
      end
    end

    def create_printer_from_preset(model_name)
      model = model_name.to_s
      defaults = Printer::COMMON_DEFAULTS[model]
      return error_result("create_printer", I18n.t("setup_assistant.missing.printer_preset", model: model)) unless defaults
      return skipped_result("create_printer", I18n.t("setup_assistant.already_exists.printer", name: model)) if user.printers.exists?(name: model)

      converted_cost = convert_to_user_currency(defaults[:cost])
      printer = user.printers.build(
        name: model,
        manufacturer: defaults[:manufacturer],
        power_consumption: defaults[:power_consumption],
        cost: converted_cost,
        daily_usage_hours: defaults[:daily_usage_hours],
        payoff_goal_years: defaults[:payoff_goal_years],
        material_technology: defaults[:material_technology],
        repair_cost_percentage: 0
      )

      if printer.save
        success_result("create_printer", I18n.t("setup_assistant.created.printer", name: printer.name), printer_path(printer))
      else
        error_result("create_printer", printer.errors.full_messages.to_sentence)
      end
    end

    def create_filament(attributes)
      preset_name = attributes["starter_preset"].to_s
      if preset_name.present? && Filament::STARTER_PRESETS.key?(preset_name)
        return create_filament_from_preset(preset_name, attributes["name"])
      end

      material_type = normalize_filament_type(attributes["material_type"])
      return error_result("create_filament", I18n.t("setup_assistant.missing.filament_material")) if material_type.blank?

      name = clean_text(attributes["name"]) || material_type
      return skipped_result("create_filament", I18n.t("setup_assistant.already_exists.filament", name: name)) if user.filaments.exists?(name: name)

      filament = user.filaments.build(
        name: name,
        material_type: material_type,
        diameter: normalize_diameter(attributes["diameter"]),
        spool_weight: positive_decimal(attributes["spool_weight"], default: 1000),
        spool_price: positive_decimal(attributes["spool_price"], default: 25),
        color: clean_text(attributes["color"]),
        brand: clean_text(attributes["brand"])
      )

      if filament.save
        success_result("create_filament", I18n.t("setup_assistant.created.filament", name: filament.name), filament_path(filament))
      else
        error_result("create_filament", filament.errors.full_messages.to_sentence)
      end
    end

    def create_filament_from_preset(preset_name, requested_name = nil)
      preset = Filament::STARTER_PRESETS[preset_name]
      name = clean_text(requested_name) || preset_name
      return skipped_result("create_filament", I18n.t("setup_assistant.already_exists.filament", name: name)) if user.filaments.exists?(name: name)

      filament = user.filaments.build(
        { name: name }.merge(preset).merge(spool_price: convert_to_user_currency(preset[:spool_price]))
      )

      if filament.save
        success_result("create_filament", I18n.t("setup_assistant.created.filament", name: filament.name), filament_path(filament))
      else
        error_result("create_filament", filament.errors.full_messages.to_sentence)
      end
    end

    def create_resin(attributes)
      resin_type = normalize_resin_type(attributes["resin_type"])
      return error_result("create_resin", I18n.t("setup_assistant.missing.resin_type")) if resin_type.blank?

      name = clean_text(attributes["name"])
      return error_result("create_resin", I18n.t("setup_assistant.missing.resin_name")) if name.blank?
      return skipped_result("create_resin", I18n.t("setup_assistant.already_exists.resin", name: name)) if user.resins.exists?(name: name)

      resin = user.resins.build(
        name: name,
        resin_type: resin_type,
        bottle_volume_ml: positive_decimal(attributes["bottle_volume_ml"], default: 1000),
        bottle_price: positive_decimal(attributes["bottle_price"], default: 40),
        color: clean_text(attributes["color"]),
        brand: clean_text(attributes["brand"]),
        needs_wash: boolean_value(attributes["needs_wash"], default: true)
      )

      if resin.save
        success_result("create_resin", I18n.t("setup_assistant.created.resin", name: resin.name), resin_path(resin))
      else
        error_result("create_resin", resin.errors.full_messages.to_sentence)
      end
    end

    def update_user_preferences(attributes)
      updates = {}

      currency = attributes["default_currency"].to_s.upcase
      if currency.present?
        if CurrencyHelper::CURRENCY_CONFIGS.key?(currency)
          updates[:default_currency] = currency
        else
          return error_result("update_user_preferences", I18n.t("setup_assistant.invalid_currency", currency: currency))
        end
      end

      energy_cost = positive_decimal(attributes["default_energy_cost_per_kwh"])
      updates[:default_energy_cost_per_kwh] = energy_cost if energy_cost

      company_name = clean_text(attributes["default_company_name"])
      updates[:default_company_name] = company_name if company_name

      return skipped_result("update_user_preferences", I18n.t("setup_assistant.no_changes")) if updates.empty?

      if user.update(updates)
        success_result("update_user_preferences", I18n.t("setup_assistant.updated_preferences"), user_profile_path)
      else
        error_result("update_user_preferences", user.errors.full_messages.to_sentence)
      end
    end

    def complete_onboarding
      return skipped_result("complete_onboarding", I18n.t("setup_assistant.not_in_onboarding")) unless context == "onboarding"

      user.update!(
        onboarding_completed_at: Time.current,
        onboarding_current_step: OnboardingController::STEPS.length - 1
      )

      success_result("complete_onboarding", I18n.t("setup_assistant.completed_onboarding"), dashboard_path)
    rescue StandardError => e
      error_result("complete_onboarding", e.message)
    end

    def onboarding_step_ready?
      return false unless context == "onboarding"

      case onboarding_step
      when "profile"
        user.default_currency.present? && user.default_energy_cost_per_kwh.present?
      when "company"
        true
      when "printer"
        user.printers.exists?
      when "filament"
        user.filaments.exists?
      else
        false
      end
    end

    def compose_reply(base_response, action_results)
      base_text = base_response.to_s.strip
      base_text = I18n.t("setup_assistant.fallback_reply") if base_text.blank?
      return base_text if action_results.blank?

      summary = action_results.map { |result| "- #{result[:message]}" }.join("\n")
      "#{base_text}\n\n#{I18n.t('setup_assistant.action_summary')}\n#{summary}"
    end

    def success_result(type, message, path = nil)
      { type: type, status: "success", message: message, path: path }
    end

    def error_result(type, message)
      { type: type, status: "error", message: message }
    end

    def skipped_result(type, message)
      { type: type, status: "skipped", message: message }
    end

    def normalize_manufacturer(manufacturer)
      value = clean_text(manufacturer)
      return "Other" if value.blank?
      return value if Printer::MANUFACTURERS.include?(value)

      "Other"
    end

    def normalize_technology(value)
      normalized = value.to_s.downcase
      return "resin" if %w[resin sla dlp msla lcd].include?(normalized)

      "fdm"
    end

    def normalize_filament_type(value)
      normalized = value.to_s.strip
      return nil if normalized.blank?

      exact = FILAMENT_TYPES.find { |entry| entry.casecmp?(normalized) }
      exact
    end

    def normalize_resin_type(value)
      normalized = value.to_s.strip
      return nil if normalized.blank?

      Resin::RESIN_TYPES.find { |entry| entry.casecmp?(normalized) }
    end

    def normalize_diameter(value)
      diameter = value.to_f
      return 1.75 unless [ 1.75, 2.85, 3.0 ].include?(diameter)

      diameter
    end

    def clean_text(value)
      text = value.to_s.strip
      text.presence
    end

    def positive_integer(value, default: nil)
      number = value.to_i
      return number if number.positive?
      return default if default

      nil
    end

    def positive_decimal(value, default: nil)
      number = begin
        BigDecimal(value.to_s)
      rescue StandardError
        nil
      end

      if number&.positive?
        number
      elsif default
        BigDecimal(default.to_s)
      end
    end

    def non_negative_decimal(value, default: nil)
      number = begin
        BigDecimal(value.to_s)
      rescue StandardError
        nil
      end

      if number && number >= 0
        number
      elsif default
        BigDecimal(default.to_s)
      end
    end

    def boolean_value(value, default: false)
      return default if value.nil?

      ActiveModel::Type::Boolean.new.cast(value)
    end

    def convert_to_user_currency(usd_amount)
      user_currency = user.default_currency || "USD"
      return usd_amount if user_currency == "USD"

      converted = CurrencyConverter.convert(usd_amount, from: "USD", to: user_currency)
      converted || usd_amount
    end
  end
end
