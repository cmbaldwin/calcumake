# frozen_string_literal: true

module Mcp
  # Defines every MCP tool exposed to AI agents. Each tool mirrors a CalcuMake
  # API capability and is automatically scoped to the authenticated user.
  #
  # A tool is registered with:
  #   register("name", description:, input_schema:) { |user, args| ... }
  #
  # The block returns Ruby data; it's serialized as JSON text content for the
  # agent. All operations go through the same model code as the REST API, so
  # validations, callbacks, and authorization stay consistent.
  module Tools
    module_function

    def handlers
      @handlers ||= build_handlers
    end

    def text_result(data)
      json = JSON.pretty_generate(data)
      { content: [ { type: "text", text: json } ], isError: false }
    end

    # ---- shared helpers ----

    def stringify_keys(value)
      case value
      when Hash then value.transform_keys(&:to_s).transform_values { |v| stringify_keys(v) }
      when Array then value.map { |v| stringify_keys(v) }
      else value
      end
    end

    def slice_attrs(args, *keys)
      keys.flatten.each_with_object({}) do |key, hash|
        skey = key.to_s
        hash[skey] = args[skey] if args.key?(skey)
      end
    end

    def serialize_printer(p)
      {
        id: p.id.to_s,
        name: p.name,
        manufacturer: p.manufacturer,
        material_technology: p.material_technology,
        power_consumption: p.power_consumption,
        cost: p.cost&.to_f,
        payoff_goal_years: p.payoff_goal_years,
        daily_usage_hours: p.daily_usage_hours,
        repair_cost_percentage: p.repair_cost_percentage&.to_f,
        date_added: p.date_added&.iso8601,
        paid_off: p.paid_off?,
        months_to_payoff: p.months_to_payoff,
        created_at: p.created_at&.iso8601,
        updated_at: p.updated_at&.iso8601
      }
    end

    # Fetch a required argument; raises a clean ArgumentError that the
    # registry converts into an isError tool result.
    def require_arg(args, key)
      val = args[key.to_s]
      raise ArgumentError, "Missing required argument: #{key}" if val.blank?

      val
    end

    def serialize_filament(f)
      {
        id: f.id.to_s,
        name: f.name,
        brand: f.brand,
        material_type: f.material_type,
        color: f.color,
        finish: f.finish,
        diameter: f.diameter&.to_f,
        density: f.density&.to_f,
        print_temperature_min: f.print_temperature_min,
        print_temperature_max: f.print_temperature_max,
        heated_bed_temperature: f.heated_bed_temperature,
        print_speed_max: f.print_speed_max,
        spool_weight: f.spool_weight&.to_f,
        spool_price: f.spool_price&.to_f,
        cost_per_gram: f.cost_per_gram&.to_f,
        storage_temperature_max: f.storage_temperature_max,
        moisture_sensitive: f.moisture_sensitive,
        notes: f.notes,
        created_at: f.created_at&.iso8601,
        updated_at: f.updated_at&.iso8601
      }
    end

    def serialize_resin(r)
      {
        id: r.id.to_s,
        name: r.name,
        brand: r.brand,
        resin_type: r.resin_type,
        color: r.color,
        bottle_volume_ml: r.bottle_volume_ml&.to_f,
        bottle_price: r.bottle_price&.to_f,
        cost_per_ml: r.cost_per_ml&.to_f,
        cure_time_seconds: r.cure_time_seconds,
        exposure_time_seconds: r.exposure_time_seconds,
        layer_height_min: r.layer_height_min&.to_f,
        layer_height_max: r.layer_height_max&.to_f,
        needs_wash: r.needs_wash,
        notes: r.notes,
        display_name: r.display_name,
        created_at: r.created_at&.iso8601,
        updated_at: r.updated_at&.iso8601
      }
    end

    def serialize_client(c)
      {
        id: c.id.to_s,
        name: c.name,
        email: c.email,
        phone: c.phone,
        company_name: c.company_name,
        address: c.address,
        tax_id: c.tax_id,
        notes: c.notes,
        print_pricings_count: c.print_pricings.count,
        invoices_count: c.invoices.count,
        created_at: c.created_at&.iso8601,
        updated_at: c.updated_at&.iso8601
      }
    end

    def serialize_print_pricing(p, include_plates: false)
      data = {
        id: p.id.to_s,
        job_name: p.job_name,
        printer_id: p.printer_id&.to_s,
        client_id: p.client_id&.to_s,
        units: p.units,
        times_printed: p.times_printed,
        total_printing_time_minutes: p.total_printing_time_minutes,
        total_material_cost: p.total_material_cost&.to_f,
        total_electricity_cost: p.total_electricity_cost&.to_f,
        total_labor_cost: p.total_labor_cost&.to_f,
        total_machine_upkeep_cost: p.total_machine_upkeep_cost&.to_f,
        total_listing_cost: p.total_listing_cost&.to_f,
        total_payment_processing_cost: p.total_payment_processing_cost&.to_f,
        subtotal: p.calculate_subtotal&.to_f,
        final_price: p.final_price&.to_f,
        per_unit_price: p.per_unit_price&.to_f,
        currency: p.default_currency,
        prep_time_minutes: p.prep_time_minutes,
        prep_cost_per_hour: p.prep_cost_per_hour&.to_f,
        postprocessing_time_minutes: p.postprocessing_time_minutes,
        postprocessing_cost_per_hour: p.postprocessing_cost_per_hour&.to_f,
        other_costs: p.other_costs&.to_f,
        vat_percentage: p.vat_percentage&.to_f,
        failure_rate_percentage: p.failure_rate_percentage&.to_f,
        listing_cost_percentage: p.listing_cost_percentage&.to_f,
        payment_processing_cost_percentage: p.payment_processing_cost_percentage&.to_f,
        plates_count: p.plates.size,
        invoices_count: p.invoices.count,
        created_at: p.created_at&.iso8601,
        updated_at: p.updated_at&.iso8601
      }
      data[:plates] = p.plates.map { |plate| serialize_plate(plate) } if include_plates
      data
    end

    def serialize_plate(plate)
      {
        id: plate.id.to_s,
        material_technology: plate.material_technology,
        printing_time_hours: plate.printing_time_hours,
        printing_time_minutes: plate.printing_time_minutes,
        total_printing_time_minutes: plate.total_printing_time_minutes,
        total_material_cost: plate.total_material_cost&.to_f,
        filaments: plate.fdm? ? plate.plate_filaments.map { |pf|
          {
            id: pf.id.to_s,
            filament_id: pf.filament_id.to_s,
            filament_name: pf.filament&.name,
            filament_weight: pf.filament_weight&.to_f,
            markup_percentage: pf.markup_percentage&.to_f,
            total_cost: pf.total_cost&.to_f
          }
        } : nil,
        resins: plate.resin? ? plate.plate_resins.map { |pr|
          {
            id: pr.id.to_s,
            resin_id: pr.resin_id.to_s,
            resin_name: pr.resin&.display_name,
            resin_volume_ml: pr.resin_volume_ml&.to_f,
            markup_percentage: pr.markup_percentage&.to_f,
            total_cost: pr.total_cost&.to_f
          }
        } : nil
      }.compact
    end

    def serialize_printer_profile(profile)
      {
        id: profile.id.to_s,
        manufacturer: profile.manufacturer,
        model: profile.model,
        technology: profile.technology,
        category: profile.category,
        power_consumption_avg_watts: profile.power_consumption_avg_watts,
        power_consumption_peak_watts: profile.power_consumption_peak_watts,
        cost_usd: profile.cost_usd&.to_f,
        display_name: profile.display_name
      }
    end

    # ---- registration ----

    @handlers = {}

    def self.register(name, description:, input_schema:, &block)
      @handlers ||= {}
      @handlers[name.to_s] = {
        description: description,
        input_schema: input_schema,
        run: block
      }
    end

    def self.build_handlers
      @handlers ||= {}
      @handlers
    end

    # =========================================================================
    # Account / profile
    # =========================================================================

    register(
      "get_profile",
      description: "Get the authenticated user's profile, default settings, and subscription plan.",
      input_schema: { type: "object", properties: {}, additionalProperties: false }
    ) do |user, _args|
      {
        id: user.id.to_s,
        email: user.email,
        plan: user.plan,
        in_trial_period: user.in_trial_period?,
        trial_days_remaining: user.trial_days_remaining,
        default_currency: user.default_currency,
        default_energy_cost_per_kwh: user.default_energy_cost_per_kwh&.to_f,
        locale: user.locale,
        default_prep_time_minutes: user.default_prep_time_minutes,
        default_prep_cost_per_hour: user.default_prep_cost_per_hour&.to_f,
        default_postprocessing_time_minutes: user.default_postprocessing_time_minutes,
        default_postprocessing_cost_per_hour: user.default_postprocessing_cost_per_hour&.to_f,
        default_other_costs: user.default_other_costs&.to_f,
        default_vat_percentage: user.default_vat_percentage&.to_f
      }
    end

    register(
      "update_profile",
      description: "Update the authenticated user's defaults (currency, energy cost, locale, default labor rates, VAT, etc).",
      input_schema: {
        type: "object",
        properties: {
          default_currency: { type: "string", description: "ISO currency code, e.g. USD, JPY, EUR." },
          default_energy_cost_per_kwh: { type: "number", description: "Cost per kWh in user's currency." },
          locale: { type: "string", enum: %w[en ja zh-CN hi es fr ar] },
          default_prep_time_minutes: { type: "integer" },
          default_prep_cost_per_hour: { type: "number" },
          default_postprocessing_time_minutes: { type: "integer" },
          default_postprocessing_cost_per_hour: { type: "number" },
          default_other_costs: { type: "number" },
          default_vat_percentage: { type: "number" }
        },
        additionalProperties: false
      }
    ) do |user, args|
      attrs = slice_attrs(args, %w[default_currency default_energy_cost_per_kwh locale default_prep_time_minutes
                                   default_prep_cost_per_hour default_postprocessing_time_minutes
                                   default_postprocessing_cost_per_hour default_other_costs default_vat_percentage])
      user.update!(attrs)
      {
        id: user.id.to_s,
        email: user.email,
        default_currency: user.default_currency,
        default_energy_cost_per_kwh: user.default_energy_cost_per_kwh&.to_f,
        locale: user.locale,
        plan: user.plan
      }
    end

    register(
      "get_usage_stats",
      description: "Get the authenticated user's resource counts, plan limits, and remaining quota.",
      input_schema: { type: "object", properties: {}, additionalProperties: false }
    ) do |user, _args|
      {
        plan: user.plan,
        in_trial_period: user.in_trial_period?,
        counts: {
          print_pricings: user.print_pricings.count,
          printers: user.printers.count,
          filaments: user.filaments.count,
          resins: user.resins.count,
          clients: user.clients.count,
          invoices: user.invoices.count
        },
        limits: {
          print_pricings: ::PlanLimits.limit_for(user, "print_pricing"),
          printers: ::PlanLimits.limit_for(user, "printer"),
          filaments: ::PlanLimits.limit_for(user, "filament"),
          invoices: ::PlanLimits.limit_for(user, "invoice")
        }.transform_values { |v| v == Float::INFINITY ? "unlimited" : v },
        remaining: {
          print_pricings: ::PlanLimits.remaining(user, "print_pricing"),
          printers: ::PlanLimits.remaining(user, "printer"),
          filaments: ::PlanLimits.remaining(user, "filament")
        }.transform_values { |v| v == Float::INFINITY ? "unlimited" : v }
      }
    end

    # =========================================================================
    # Printers
    # =========================================================================

    PRINTER_FIELDS = %w[name manufacturer material_technology power_consumption cost
                        payoff_goal_years daily_usage_hours repair_cost_percentage date_added].freeze

    register(
      "list_printers",
      description: "List all printers for the authenticated user. Supports optional technology filter (fdm or resin).",
      input_schema: {
        type: "object",
        properties: {
          technology: { type: "string", enum: %w[fdm resin], description: "Filter by material technology." }
        },
        additionalProperties: false
      }
    ) do |user, args|
      scope = user.printers.order(:name)
      scope = scope.where(material_technology: args["technology"]) if %w[fdm resin].include?(args["technology"])
      { printers: scope.map { |p| serialize_printer(p) } }
    end

    register(
      "get_printer",
      description: "Get a single printer by id.",
      input_schema: {
        type: "object",
        properties: { id: { type: "string", description: "Printer id (as string)." } },
        required: %w[id],
        additionalProperties: false
      }
    ) do |user, args|
      serialize_printer(user.printers.find(require_arg(args, "id")))
    end

    register(
      "create_printer",
      description: "Create a new printer. Required: name, material_technology (fdm or resin). Other fields optional.",
      input_schema: {
        type: "object",
        properties: {
          name: { type: "string" },
          manufacturer: { type: "string" },
          material_technology: { type: "string", enum: %w[fdm resin] },
          power_consumption: { type: "integer", description: "Watts." },
          cost: { type: "number", description: "Purchase cost." },
          payoff_goal_years: { type: "integer" },
          daily_usage_hours: { type: "number" },
          repair_cost_percentage: { type: "number" },
          date_added: { type: "string", description: "ISO 8601 date." }
        },
        required: %w[name material_technology],
        additionalProperties: false
      }
    ) do |user, args|
      attrs = slice_attrs(args, PRINTER_FIELDS)
      printer = user.printers.create!(attrs)
      serialize_printer(printer)
    end

    register(
      "update_printer",
      description: "Update fields on an existing printer.",
      input_schema: {
        type: "object",
        properties: {
          id: { type: "string" },
          name: { type: "string" },
          manufacturer: { type: "string" },
          material_technology: { type: "string", enum: %w[fdm resin] },
          power_consumption: { type: "integer" },
          cost: { type: "number" },
          payoff_goal_years: { type: "integer" },
          daily_usage_hours: { type: "number" },
          repair_cost_percentage: { type: "number" },
          date_added: { type: "string" }
        },
        required: %w[id],
        additionalProperties: false
      }
    ) do |user, args|
      printer = user.printers.find(require_arg(args, "id"))
      printer.update!(slice_attrs(args, PRINTER_FIELDS))
      serialize_printer(printer)
    end

    register(
      "delete_printer",
      description: "Delete a printer by id.",
      input_schema: {
        type: "object",
        properties: { id: { type: "string" } },
        required: %w[id],
        additionalProperties: false
      }
    ) do |user, args|
      printer = user.printers.find(require_arg(args, "id"))
      printer.destroy!
      { id: args["id"], deleted: true }
    end

    # =========================================================================
    # Filaments
    # =========================================================================

    FILAMENT_FIELDS = %w[name brand material_type diameter density print_temperature_min print_temperature_max
                         heated_bed_temperature print_speed_max color finish spool_weight spool_price
                         storage_temperature_max moisture_sensitive notes].freeze

    register(
      "list_filaments",
      description: "List filaments owned by the user. Supports search query and material_type filter.",
      input_schema: {
        type: "object",
        properties: {
          q: { type: "string", description: "Free-text search across name/brand/material." },
          material_type: { type: "string", description: "Filter by material type, e.g. PLA, PETG, ABS." }
        },
        additionalProperties: false
      }
    ) do |user, args|
      scope = user.filaments.order(:material_type, :name)
      scope = scope.search(args["q"]) if args["q"].present?
      scope = scope.by_material_type(args["material_type"]) if args["material_type"].present?
      { filaments: scope.map { |f| serialize_filament(f) } }
    end

    register(
      "get_filament",
      description: "Get a single filament by id.",
      input_schema: {
        type: "object",
        properties: { id: { type: "string" } },
        required: %w[id],
        additionalProperties: false
      }
    ) do |user, args|
      serialize_filament(user.filaments.find(require_arg(args, "id")))
    end

    register(
      "create_filament",
      description: "Create a new filament for the user.",
      input_schema: {
        type: "object",
        properties: {
          name: { type: "string" }, brand: { type: "string" }, material_type: { type: "string" },
          diameter: { type: "number" }, density: { type: "number" },
          print_temperature_min: { type: "integer" }, print_temperature_max: { type: "integer" },
          heated_bed_temperature: { type: "integer" }, print_speed_max: { type: "integer" },
          color: { type: "string" }, finish: { type: "string" },
          spool_weight: { type: "number" }, spool_price: { type: "number" },
          storage_temperature_max: { type: "integer" },
          moisture_sensitive: { type: "boolean" }, notes: { type: "string" }
        },
        required: %w[name material_type],
        additionalProperties: false
      }
    ) do |user, args|
      filament = user.filaments.create!(slice_attrs(args, FILAMENT_FIELDS))
      serialize_filament(filament)
    end

    register(
      "update_filament",
      description: "Update fields on an existing filament.",
      input_schema: {
        type: "object",
        properties: {
          id: { type: "string" },
          name: { type: "string" }, brand: { type: "string" }, material_type: { type: "string" },
          diameter: { type: "number" }, density: { type: "number" },
          print_temperature_min: { type: "integer" }, print_temperature_max: { type: "integer" },
          heated_bed_temperature: { type: "integer" }, print_speed_max: { type: "integer" },
          color: { type: "string" }, finish: { type: "string" },
          spool_weight: { type: "number" }, spool_price: { type: "number" },
          storage_temperature_max: { type: "integer" },
          moisture_sensitive: { type: "boolean" }, notes: { type: "string" }
        },
        required: %w[id],
        additionalProperties: false
      }
    ) do |user, args|
      filament = user.filaments.find(require_arg(args, "id"))
      filament.update!(slice_attrs(args, FILAMENT_FIELDS))
      serialize_filament(filament)
    end

    register(
      "delete_filament",
      description: "Delete a filament by id.",
      input_schema: {
        type: "object",
        properties: { id: { type: "string" } },
        required: %w[id],
        additionalProperties: false
      }
    ) do |user, args|
      user.filaments.find(require_arg(args, "id")).destroy!
      { id: args["id"], deleted: true }
    end

    register(
      "duplicate_filament",
      description: "Duplicate an existing filament. The copy's name will be suffixed with ' (Copy)'.",
      input_schema: {
        type: "object",
        properties: { id: { type: "string" } },
        required: %w[id],
        additionalProperties: false
      }
    ) do |user, args|
      source = user.filaments.find(require_arg(args, "id"))
      copy = source.dup
      copy.name = "#{source.name} (Copy)"
      copy.save!
      serialize_filament(copy)
    end

    # =========================================================================
    # Resins
    # =========================================================================

    RESIN_FIELDS = %w[name brand resin_type color bottle_volume_ml bottle_price cure_time_seconds
                      exposure_time_seconds layer_height_min layer_height_max needs_wash notes].freeze

    register(
      "list_resins",
      description: "List resins owned by the user. Supports search and resin_type filter.",
      input_schema: {
        type: "object",
        properties: {
          q: { type: "string" },
          resin_type: { type: "string" }
        },
        additionalProperties: false
      }
    ) do |user, args|
      scope = user.resins.order(:resin_type, :name)
      scope = scope.search(args["q"]) if args["q"].present?
      scope = scope.by_resin_type(args["resin_type"]) if args["resin_type"].present?
      { resins: scope.map { |r| serialize_resin(r) } }
    end

    register(
      "get_resin",
      description: "Get a single resin by id.",
      input_schema: {
        type: "object",
        properties: { id: { type: "string" } },
        required: %w[id],
        additionalProperties: false
      }
    ) do |user, args|
      serialize_resin(user.resins.find(require_arg(args, "id")))
    end

    register(
      "create_resin",
      description: "Create a new resin for the user.",
      input_schema: {
        type: "object",
        properties: {
          name: { type: "string" }, brand: { type: "string" }, resin_type: { type: "string" },
          color: { type: "string" },
          bottle_volume_ml: { type: "number" }, bottle_price: { type: "number" },
          cure_time_seconds: { type: "integer" }, exposure_time_seconds: { type: "integer" },
          layer_height_min: { type: "number" }, layer_height_max: { type: "number" },
          needs_wash: { type: "boolean" }, notes: { type: "string" }
        },
        required: %w[name resin_type],
        additionalProperties: false
      }
    ) do |user, args|
      resin = user.resins.create!(slice_attrs(args, RESIN_FIELDS))
      serialize_resin(resin)
    end

    register(
      "update_resin",
      description: "Update fields on an existing resin.",
      input_schema: {
        type: "object",
        properties: {
          id: { type: "string" },
          name: { type: "string" }, brand: { type: "string" }, resin_type: { type: "string" },
          color: { type: "string" },
          bottle_volume_ml: { type: "number" }, bottle_price: { type: "number" },
          cure_time_seconds: { type: "integer" }, exposure_time_seconds: { type: "integer" },
          layer_height_min: { type: "number" }, layer_height_max: { type: "number" },
          needs_wash: { type: "boolean" }, notes: { type: "string" }
        },
        required: %w[id],
        additionalProperties: false
      }
    ) do |user, args|
      resin = user.resins.find(require_arg(args, "id"))
      resin.update!(slice_attrs(args, RESIN_FIELDS))
      serialize_resin(resin)
    end

    register(
      "delete_resin",
      description: "Delete a resin by id.",
      input_schema: {
        type: "object",
        properties: { id: { type: "string" } },
        required: %w[id],
        additionalProperties: false
      }
    ) do |user, args|
      user.resins.find(require_arg(args, "id")).destroy!
      { id: args["id"], deleted: true }
    end

    register(
      "duplicate_resin",
      description: "Duplicate an existing resin. The copy's name will be suffixed with ' (Copy)'.",
      input_schema: {
        type: "object",
        properties: { id: { type: "string" } },
        required: %w[id],
        additionalProperties: false
      }
    ) do |user, args|
      source = user.resins.find(require_arg(args, "id"))
      copy = source.dup
      copy.name = "#{source.name} (Copy)"
      copy.save!
      serialize_resin(copy)
    end

    # =========================================================================
    # Materials (combined library) and Printer Profiles (catalog)
    # =========================================================================

    register(
      "search_materials",
      description: "Search across the user's filaments and resins library combined. Filter by technology (fdm or resin).",
      input_schema: {
        type: "object",
        properties: {
          q: { type: "string" },
          technology: { type: "string", enum: %w[fdm resin] }
        },
        additionalProperties: false
      }
    ) do |user, args|
      filaments = user.filaments.order(:material_type, :name)
      resins = user.resins.order(:resin_type, :name)
      filaments = filaments.search(args["q"]) if args["q"].present?
      resins = resins.search(args["q"]) if args["q"].present?
      case args["technology"]
      when "fdm" then resins = resins.none
      when "resin" then filaments = filaments.none
      end
      {
        filaments: filaments.map { |f| serialize_filament(f) },
        resins: resins.map { |r| serialize_resin(r) }
      }
    end

    register(
      "search_printer_profiles",
      description: "Search the public catalog of printer profiles (manufacturer/model presets). Useful for prefilling printer specs.",
      input_schema: {
        type: "object",
        properties: {
          q: { type: "string" },
          technology: { type: "string", enum: %w[fdm resin] }
        },
        additionalProperties: false
      }
    ) do |_user, args|
      scope = ::PrinterProfile.all
      scope = scope.search(args["q"]) if args["q"].present?
      scope = scope.by_technology(args["technology"]) if args["technology"].present?
      scope = scope.order(:manufacturer, :model)
      { profiles: scope.map { |p| serialize_printer_profile(p) } }
    end

    # =========================================================================
    # Clients
    # =========================================================================

    CLIENT_FIELDS = %w[name email phone company_name address tax_id notes].freeze

    register(
      "list_clients",
      description: "List the user's clients. Supports a search query.",
      input_schema: {
        type: "object",
        properties: { q: { type: "string" } },
        additionalProperties: false
      }
    ) do |user, args|
      scope = user.clients.order(:name)
      scope = scope.search(args["q"]) if args["q"].present?
      { clients: scope.map { |c| serialize_client(c) } }
    end

    register(
      "get_client",
      description: "Get a single client by id.",
      input_schema: {
        type: "object",
        properties: { id: { type: "string" } },
        required: %w[id],
        additionalProperties: false
      }
    ) do |user, args|
      serialize_client(user.clients.find(require_arg(args, "id")))
    end

    register(
      "create_client",
      description: "Create a new client.",
      input_schema: {
        type: "object",
        properties: {
          name: { type: "string" }, email: { type: "string" }, phone: { type: "string" },
          company_name: { type: "string" }, address: { type: "string" },
          tax_id: { type: "string" }, notes: { type: "string" }
        },
        required: %w[name],
        additionalProperties: false
      }
    ) do |user, args|
      client = user.clients.create!(slice_attrs(args, CLIENT_FIELDS))
      serialize_client(client)
    end

    register(
      "update_client",
      description: "Update fields on an existing client.",
      input_schema: {
        type: "object",
        properties: {
          id: { type: "string" }, name: { type: "string" }, email: { type: "string" },
          phone: { type: "string" }, company_name: { type: "string" },
          address: { type: "string" }, tax_id: { type: "string" }, notes: { type: "string" }
        },
        required: %w[id],
        additionalProperties: false
      }
    ) do |user, args|
      client = user.clients.find(require_arg(args, "id"))
      client.update!(slice_attrs(args, CLIENT_FIELDS))
      serialize_client(client)
    end

    register(
      "delete_client",
      description: "Delete a client by id.",
      input_schema: {
        type: "object",
        properties: { id: { type: "string" } },
        required: %w[id],
        additionalProperties: false
      }
    ) do |user, args|
      user.clients.find(require_arg(args, "id")).destroy!
      { id: args["id"], deleted: true }
    end

    # =========================================================================
    # Print pricings (the core domain object)
    # =========================================================================

    PRINT_PRICING_FIELDS = %w[job_name printer_id client_id units times_printed
                              prep_time_minutes prep_cost_per_hour
                              postprocessing_time_minutes postprocessing_cost_per_hour
                              other_costs vat_percentage failure_rate_percentage
                              listing_cost_percentage payment_processing_cost_percentage].freeze

    PLATE_SCHEMA = {
      type: "object",
      properties: {
        id: { type: "string", description: "Existing plate id (omit to create)." },
        _destroy: { type: "boolean", description: "Set true to remove an existing plate." },
        printing_time_hours: { type: "integer" },
        printing_time_minutes: { type: "integer" },
        material_technology: { type: "string", enum: %w[fdm resin] },
        plate_filaments: {
          type: "array",
          items: {
            type: "object",
            properties: {
              id: { type: "string" },
              _destroy: { type: "boolean" },
              filament_id: { type: "string" },
              filament_weight: { type: "number" },
              markup_percentage: { type: "number" }
            },
            additionalProperties: false
          }
        },
        plate_resins: {
          type: "array",
          items: {
            type: "object",
            properties: {
              id: { type: "string" },
              _destroy: { type: "boolean" },
              resin_id: { type: "string" },
              resin_volume_ml: { type: "number" },
              markup_percentage: { type: "number" }
            },
            additionalProperties: false
          }
        }
      },
      additionalProperties: false
    }.freeze

    # Convert MCP plates argument (array of hashes with arrays for filaments/resins)
    # into the nested-attributes format Rails expects.
    def self.normalize_plates_for_nested(plates)
      return nil if plates.nil?
      raise ArgumentError, "plates must be an array" unless plates.is_a?(Array)

      plates_attrs = {}
      plates.each_with_index do |plate, i|
        plate = plate.deep_stringify_keys
        attrs = plate.slice("id", "_destroy", "printing_time_hours", "printing_time_minutes", "material_technology")
        if (filaments = plate["plate_filaments"])
          raise ArgumentError, "plate_filaments must be an array" unless filaments.is_a?(Array)

          attrs["plate_filaments_attributes"] = filaments.each_with_index.to_h do |pf, j|
            pf = pf.deep_stringify_keys.slice("id", "_destroy", "filament_id", "filament_weight", "markup_percentage")
            [ j.to_s, pf ]
          end
        end
        if (resins = plate["plate_resins"])
          raise ArgumentError, "plate_resins must be an array" unless resins.is_a?(Array)

          attrs["plate_resins_attributes"] = resins.each_with_index.to_h do |pr, j|
            pr = pr.deep_stringify_keys.slice("id", "_destroy", "resin_id", "resin_volume_ml", "markup_percentage")
            [ j.to_s, pr ]
          end
        end
        plates_attrs[i.to_s] = attrs
      end
      plates_attrs
    end

    register(
      "list_print_pricings",
      description: "List the user's print pricing jobs (newest first). Supports a search query across job name.",
      input_schema: {
        type: "object",
        properties: { q: { type: "string" } },
        additionalProperties: false
      }
    ) do |user, args|
      scope = user.print_pricings
        .includes(:printer, :client, plates: [ :plate_filaments, :filaments, :plate_resins, :resins ])
        .order(created_at: :desc)
      scope = scope.search(args["q"]) if args["q"].present?
      { print_pricings: scope.map { |p| serialize_print_pricing(p) } }
    end

    register(
      "get_print_pricing",
      description: "Get a single print pricing job, including all plates and material breakdown.",
      input_schema: {
        type: "object",
        properties: { id: { type: "string" } },
        required: %w[id],
        additionalProperties: false
      }
    ) do |user, args|
      pricing = user.print_pricings
        .includes(plates: [ :plate_filaments, :filaments, :plate_resins, :resins ])
        .find(require_arg(args, "id"))
      serialize_print_pricing(pricing, include_plates: true)
    end

    register(
      "create_print_pricing",
      description: "Create a new print pricing job. Pass nested `plates` (1-10) each with their `plate_filaments` or `plate_resins`. The system auto-calculates totals.",
      input_schema: {
        type: "object",
        properties: {
          job_name: { type: "string" },
          printer_id: { type: "string" },
          client_id: { type: "string" },
          units: { type: "integer", description: "Number of units to produce." },
          times_printed: { type: "integer" },
          prep_time_minutes: { type: "integer" },
          prep_cost_per_hour: { type: "number" },
          postprocessing_time_minutes: { type: "integer" },
          postprocessing_cost_per_hour: { type: "number" },
          other_costs: { type: "number" },
          vat_percentage: { type: "number" },
          failure_rate_percentage: { type: "number" },
          listing_cost_percentage: { type: "number" },
          payment_processing_cost_percentage: { type: "number" },
          plates: {
            type: "array",
            description: "1-10 plates. Each plate must include either plate_filaments (FDM) or plate_resins (resin).",
            items: PLATE_SCHEMA
          }
        },
        required: %w[job_name printer_id plates],
        additionalProperties: false
      }
    ) do |user, args|
      attrs = slice_attrs(args, PRINT_PRICING_FIELDS)
      attrs["plates_attributes"] = normalize_plates_for_nested(args["plates"]) if args["plates"]
      pricing = user.print_pricings.create!(attrs)
      serialize_print_pricing(pricing.reload, include_plates: true)
    end

    register(
      "update_print_pricing",
      description: "Update an existing print pricing. Pass nested `plates` to add, modify (with id), or remove (with _destroy:true).",
      input_schema: {
        type: "object",
        properties: {
          id: { type: "string" },
          job_name: { type: "string" }, printer_id: { type: "string" }, client_id: { type: "string" },
          units: { type: "integer" }, times_printed: { type: "integer" },
          prep_time_minutes: { type: "integer" }, prep_cost_per_hour: { type: "number" },
          postprocessing_time_minutes: { type: "integer" }, postprocessing_cost_per_hour: { type: "number" },
          other_costs: { type: "number" }, vat_percentage: { type: "number" },
          failure_rate_percentage: { type: "number" },
          listing_cost_percentage: { type: "number" }, payment_processing_cost_percentage: { type: "number" },
          plates: { type: "array", items: PLATE_SCHEMA }
        },
        required: %w[id],
        additionalProperties: false
      }
    ) do |user, args|
      pricing = user.print_pricings.find(require_arg(args, "id"))
      attrs = slice_attrs(args, PRINT_PRICING_FIELDS)
      attrs["plates_attributes"] = normalize_plates_for_nested(args["plates"]) if args.key?("plates")
      pricing.update!(attrs)
      serialize_print_pricing(pricing.reload, include_plates: true)
    end

    register(
      "delete_print_pricing",
      description: "Delete a print pricing job (and its plates) by id.",
      input_schema: {
        type: "object",
        properties: { id: { type: "string" } },
        required: %w[id],
        additionalProperties: false
      }
    ) do |user, args|
      user.print_pricings.find(require_arg(args, "id")).destroy!
      { id: args["id"], deleted: true }
    end

    register(
      "duplicate_print_pricing",
      description: "Duplicate an existing print pricing job, including all plates and materials. The new job's name is suffixed with ' (Copy)'.",
      input_schema: {
        type: "object",
        properties: { id: { type: "string" } },
        required: %w[id],
        additionalProperties: false
      }
    ) do |user, args|
      original = user.print_pricings.find(require_arg(args, "id"))
      copy = original.dup
      copy.job_name = "#{original.job_name} (Copy)"
      copy.times_printed = 0

      original.plates.each do |plate|
        new_plate = plate.dup
        copy.plates << new_plate
        plate.plate_filaments.each { |pf| new_plate.plate_filaments << pf.dup }
        plate.plate_resins.each { |pr| new_plate.plate_resins << pr.dup }
      end

      copy.save!
      serialize_print_pricing(copy.reload, include_plates: true)
    end

    register(
      "increment_times_printed",
      description: "Increment the times_printed counter for a print pricing job (logs another successful run).",
      input_schema: {
        type: "object",
        properties: { id: { type: "string" } },
        required: %w[id],
        additionalProperties: false
      }
    ) do |user, args|
      pricing = user.print_pricings.find(require_arg(args, "id"))
      pricing.increment_times_printed!
      { id: pricing.id.to_s, times_printed: pricing.times_printed }
    end

    register(
      "decrement_times_printed",
      description: "Decrement the times_printed counter for a print pricing job.",
      input_schema: {
        type: "object",
        properties: { id: { type: "string" } },
        required: %w[id],
        additionalProperties: false
      }
    ) do |user, args|
      pricing = user.print_pricings.find(require_arg(args, "id"))
      pricing.decrement_times_printed!
      { id: pricing.id.to_s, times_printed: pricing.times_printed }
    end

    register(
      "list_plates_for_pricing",
      description: "List all plates belonging to a single print pricing job.",
      input_schema: {
        type: "object",
        properties: { print_pricing_id: { type: "string" } },
        required: %w[print_pricing_id],
        additionalProperties: false
      }
    ) do |user, args|
      pricing = user.print_pricings
        .includes(plates: [ :plate_filaments, :filaments, :plate_resins, :resins ])
        .find(require_arg(args, "print_pricing_id"))
      { plates: pricing.plates.map { |plate| serialize_plate(plate) } }
    end
  end
end
