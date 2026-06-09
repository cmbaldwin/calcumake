# frozen_string_literal: true

module Mcp
  module Tools
    class ToolNotFoundError < StandardError; end
    class ToolError < StandardError; end

    # Definitions exposed to MCP clients via tools/list
    DEFINITIONS = [
      {
        name: "health_check",
        description: "Check CalcuMake API health and status. No authentication required.",
        inputSchema: { type: "object", properties: {}, required: [] }
      },
      {
        name: "get_profile",
        description: "Get the authenticated user's profile: email, currency, plan, locale.",
        inputSchema: { type: "object", properties: {}, required: [] }
      },
      {
        name: "list_printers",
        description: "List the user's 3D printers. Filter by technology (fdm/resin).",
        inputSchema: {
          type: "object",
          properties: {
            technology: { type: "string", enum: [ "fdm", "resin" ], description: "Filter by printing technology" },
            page:     { type: "integer", description: "Page number (default: 1)" },
            per_page: { type: "integer", description: "Items per page (default: 20, max: 100)" }
          }
        }
      },
      {
        name: "get_printer",
        description: "Get details for a specific printer by ID.",
        inputSchema: {
          type: "object",
          properties: { id: { type: "integer", description: "Printer ID" } },
          required: [ "id" ]
        }
      },
      {
        name: "create_printer",
        description: "Create a new 3D printer.",
        inputSchema: {
          type: "object",
          properties: {
            name:                   { type: "string", description: "Printer name (required)" },
            manufacturer:           { type: "string", description: "Manufacturer/brand" },
            material_technology:    { type: "string", enum: [ "fdm", "resin" ], description: "Printing technology" },
            power_consumption:      { type: "number", description: "Power in watts" },
            cost:                   { type: "number", description: "Purchase cost" },
            payoff_goal_years:      { type: "number", description: "Years to pay off printer" },
            daily_usage_hours:      { type: "number", description: "Average daily usage hours" },
            repair_cost_percentage: { type: "number", description: "Annual repair cost as % of purchase" }
          },
          required: [ "name", "manufacturer", "material_technology", "power_consumption", "cost", "payoff_goal_years", "daily_usage_hours" ]
        }
      },
      {
        name: "update_printer",
        description: "Update an existing printer by ID.",
        inputSchema: {
          type: "object",
          properties: {
            id:                     { type: "integer", description: "Printer ID (required)" },
            name:                   { type: "string" },
            manufacturer:           { type: "string" },
            material_technology:    { type: "string", enum: [ "fdm", "resin" ] },
            power_consumption:      { type: "number" },
            cost:                   { type: "number" },
            payoff_goal_years:      { type: "number" },
            daily_usage_hours:      { type: "number" },
            repair_cost_percentage: { type: "number" }
          },
          required: [ "id" ]
        }
      },
      {
        name: "delete_printer",
        description: "Delete a printer by ID.",
        inputSchema: {
          type: "object",
          properties: { id: { type: "integer", description: "Printer ID" } },
          required: [ "id" ]
        }
      },
      {
        name: "list_filaments",
        description: "List the user's filaments. Filter by material type or search by name.",
        inputSchema: {
          type: "object",
          properties: {
            q:             { type: "string", description: "Search by name or brand" },
            material_type: { type: "string", description: "Filter by material type (e.g. PLA, ABS, PETG)" },
            page:          { type: "integer", description: "Page number (default: 1)" },
            per_page:      { type: "integer", description: "Items per page (default: 20, max: 100)" }
          }
        }
      },
      {
        name: "get_filament",
        description: "Get details for a specific filament by ID.",
        inputSchema: {
          type: "object",
          properties: { id: { type: "integer", description: "Filament ID" } },
          required: [ "id" ]
        }
      },
      {
        name: "create_filament",
        description: "Create a new filament.",
        inputSchema: {
          type: "object",
          properties: {
            name:          { type: "string", description: "Filament name (required)" },
            brand:         { type: "string", description: "Brand/manufacturer" },
            material_type: { type: "string", description: "Material type: PLA, ABS, PETG, TPU, etc. (required)" },
            color:         { type: "string", description: "Color name" },
            diameter:      { type: "number", description: "Diameter in mm (default 1.75)" },
            spool_weight:  { type: "number", description: "Spool weight in grams" },
            spool_price:   { type: "number", description: "Spool price" },
            notes:         { type: "string", description: "Optional notes" }
          },
          required: [ "name", "brand", "material_type" ]
        }
      },
      {
        name: "list_clients",
        description: "List the user's clients. Search by name, email, or company.",
        inputSchema: {
          type: "object",
          properties: {
            q:        { type: "string", description: "Search by name, email, or company" },
            page:     { type: "integer", description: "Page number (default: 1)" },
            per_page: { type: "integer", description: "Items per page (default: 20, max: 100)" }
          }
        }
      },
      {
        name: "get_client",
        description: "Get details for a specific client by ID.",
        inputSchema: {
          type: "object",
          properties: { id: { type: "integer", description: "Client ID" } },
          required: [ "id" ]
        }
      },
      {
        name: "create_client",
        description: "Create a new client.",
        inputSchema: {
          type: "object",
          properties: {
            name:         { type: "string", description: "Client name (required)" },
            email:        { type: "string", description: "Email address" },
            phone:        { type: "string", description: "Phone number" },
            company_name: { type: "string", description: "Company name" },
            address:      { type: "string", description: "Address" },
            tax_id:       { type: "string", description: "Tax ID / VAT number" },
            notes:        { type: "string", description: "Optional notes" }
          },
          required: [ "name" ]
        }
      },
      {
        name: "list_print_pricings",
        description: "List the user's 3D print pricing jobs. Search by job name.",
        inputSchema: {
          type: "object",
          properties: {
            q:        { type: "string", description: "Search by job name" },
            page:     { type: "integer", description: "Page number (default: 1)" },
            per_page: { type: "integer", description: "Items per page (default: 20, max: 100)" }
          }
        }
      },
      {
        name: "get_print_pricing",
        description: "Get full details for a print pricing job including plates and cost breakdown.",
        inputSchema: {
          type: "object",
          properties: { id: { type: "integer", description: "Print pricing ID" } },
          required: [ "id" ]
        }
      },
      {
        name: "list_printer_profiles",
        description: "List the public printer profile library (no authentication required). Useful for discovering printer specs.",
        inputSchema: {
          type: "object",
          properties: {
            page:     { type: "integer", description: "Page number (default: 1)" },
            per_page: { type: "integer", description: "Items per page (default: 20, max: 100)" }
          }
        }
      }
    ].freeze

    def self.definitions
      DEFINITIONS
    end

    def self.call(name, arguments, user:)
      tool = DEFINITIONS.find { |t| t[:name] == name }
      raise ToolNotFoundError, "Tool '#{name}' not found. Run tools/list to see available tools." unless tool

      # health_check and list_printer_profiles are public
      public_tools = %w[health_check list_printer_profiles]
      raise ToolError, "Authentication required" if user.nil? && !public_tools.include?(name)

      result = dispatch(name, arguments || {}, user)
      { content: [ { type: "text", text: result.to_json } ], isError: false }
    rescue ToolNotFoundError, ToolError
      raise
    rescue ActiveRecord::RecordNotFound
      raise ToolError, "Resource not found"
    rescue ActiveRecord::RecordInvalid => e
      raise ToolError, "Validation failed: #{e.record.errors.full_messages.join(', ')}"
    rescue ArgumentError => e
      raise ToolError, e.message
    rescue StandardError => e
      raise ToolError, "Tool execution failed: #{e.message}"
    end

    # --- Private dispatch -------------------------------------------------------

    def self.dispatch(name, args, user) # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity
      case name
      when "health_check"          then health_check(args, user)
      when "get_profile"           then get_profile(args, user)
      when "list_printers"         then list_printers(args, user)
      when "get_printer"           then get_printer(args, user)
      when "create_printer"        then create_printer(args, user)
      when "update_printer"        then update_printer(args, user)
      when "delete_printer"        then delete_printer(args, user)
      when "list_filaments"        then list_filaments(args, user)
      when "get_filament"          then get_filament(args, user)
      when "create_filament"       then create_filament(args, user)
      when "list_clients"          then list_clients(args, user)
      when "get_client"            then get_client(args, user)
      when "create_client"         then create_client(args, user)
      when "list_print_pricings"   then list_print_pricings(args, user)
      when "get_print_pricing"     then get_print_pricing(args, user)
      when "list_printer_profiles" then list_printer_profiles(args, user)
      else raise ToolNotFoundError, "Tool '#{name}' not found"
      end
    end
    private_class_method :dispatch

    # --- Helper -----------------------------------------------------------------

    def self.paginate(scope, args)
      page     = [ args["page"].to_i, 1 ].max
      per_page = args["per_page"].to_i
      per_page = 20 if per_page < 1
      per_page = [ per_page, 100 ].min

      total  = scope.count
      items  = scope.offset((page - 1) * per_page).limit(per_page)
      [ items, { total: total, page: page, per_page: per_page, total_pages: (total.to_f / per_page).ceil } ]
    end
    private_class_method :paginate

    # --- Tool implementations ---------------------------------------------------

    def self.health_check(_args, _user)
      { status: "ok", service: "CalcuMake MCP", version: "1.0", timestamp: Time.current.iso8601 }
    end
    private_class_method :health_check

    def self.get_profile(_args, user)
      {
        id: user.id,
        email: user.email,
        default_currency: user.default_currency,
        default_energy_cost_per_kwh: user.default_energy_cost_per_kwh&.to_f,
        plan: user.plan,
        locale: user.locale,
        created_at: user.created_at.iso8601
      }
    end
    private_class_method :get_profile

    def self.list_printers(args, user)
      scope = user.printers.order(:name)
      scope = scope.where(material_technology: args["technology"]) if %w[fdm resin].include?(args["technology"])
      items, meta = paginate(scope, args)
      { data: items.map { |p| serialize_printer(p) }, meta: meta }
    end
    private_class_method :list_printers

    def self.get_printer(args, user)
      printer = user.printers.find(Integer(args["id"]))
      { data: serialize_printer(printer) }
    end
    private_class_method :get_printer

    def self.create_printer(args, user)
      attrs = {
        name:                args["name"],
        manufacturer:        args["manufacturer"],
        material_technology: args["material_technology"],
        power_consumption:   args["power_consumption"],
        cost:                args["cost"],
        payoff_goal_years:   args["payoff_goal_years"],
        daily_usage_hours:   args["daily_usage_hours"]
      }
      attrs[:repair_cost_percentage] = args["repair_cost_percentage"] if args.key?("repair_cost_percentage")
      printer = user.printers.create!(attrs)
      { data: serialize_printer(printer) }
    end
    private_class_method :create_printer

    def self.update_printer(args, user)
      printer = user.printers.find(Integer(args["id"]))
      update_attrs = args.slice(
        "name", "manufacturer", "material_technology", "power_consumption",
        "cost", "payoff_goal_years", "daily_usage_hours", "repair_cost_percentage"
      ).reject { |_, v| v.nil? }
      printer.update!(update_attrs)
      { data: serialize_printer(printer) }
    end
    private_class_method :update_printer

    def self.delete_printer(args, user)
      printer = user.printers.find(Integer(args["id"]))
      printer.destroy!
      { deleted: true, id: args["id"].to_i }
    end
    private_class_method :delete_printer

    def self.list_filaments(args, user)
      scope = user.filaments.order(:material_type, :name)
      scope = scope.search(args["q"]) if args["q"].present?
      scope = scope.by_material_type(args["material_type"]) if args["material_type"].present?
      items, meta = paginate(scope, args)
      { data: items.map { |f| serialize_filament(f) }, meta: meta }
    end
    private_class_method :list_filaments

    def self.get_filament(args, user)
      filament = user.filaments.find(Integer(args["id"]))
      { data: serialize_filament(filament) }
    end
    private_class_method :get_filament

    def self.create_filament(args, user)
      filament = user.filaments.create!(
        name:          args["name"],
        brand:         args["brand"],
        material_type: args["material_type"],
        color:         args["color"],
        diameter:      args["diameter"],
        spool_weight:  args["spool_weight"],
        spool_price:   args["spool_price"],
        notes:         args["notes"]
      )
      { data: serialize_filament(filament) }
    end
    private_class_method :create_filament

    def self.list_clients(args, user)
      scope = user.clients.order(:name)
      scope = scope.search(args["q"]) if args["q"].present?
      items, meta = paginate(scope, args)
      { data: items.map { |c| serialize_client(c) }, meta: meta }
    end
    private_class_method :list_clients

    def self.get_client(args, user)
      client = user.clients.find(Integer(args["id"]))
      { data: serialize_client(client) }
    end
    private_class_method :get_client

    def self.create_client(args, user)
      client = user.clients.create!(
        name:         args["name"],
        email:        args["email"],
        phone:        args["phone"],
        company_name: args["company_name"],
        address:      args["address"],
        tax_id:       args["tax_id"],
        notes:        args["notes"]
      )
      { data: serialize_client(client) }
    end
    private_class_method :create_client

    def self.list_print_pricings(args, user)
      scope = user.print_pricings.includes(:printer, :client).order(created_at: :desc)
      scope = scope.search(args["q"]) if args["q"].present?
      items, meta = paginate(scope, args)
      { data: items.map { |pp| serialize_print_pricing(pp) }, meta: meta }
    end
    private_class_method :list_print_pricings

    def self.get_print_pricing(args, user)
      pricing = user.print_pricings
                    .includes(:printer, :client, plates: [ :plate_filaments, :filaments, :plate_resins, :resins ])
                    .find(Integer(args["id"]))
      { data: serialize_print_pricing(pricing, include_plates: true) }
    end
    private_class_method :get_print_pricing

    def self.list_printer_profiles(args, _user)
      scope = PrinterProfile.order(:manufacturer, :model)
      items, meta = paginate(scope, args)
      { data: items.map { |pp| serialize_printer_profile(pp) }, meta: meta }
    end
    private_class_method :list_printer_profiles

    # --- Serializers ------------------------------------------------------------

    def self.serialize_printer(p)
      {
        id: p.id,
        name: p.name,
        manufacturer: p.manufacturer,
        material_technology: p.material_technology,
        power_consumption: p.power_consumption&.to_f,
        cost: p.cost&.to_f,
        payoff_goal_years: p.payoff_goal_years,
        daily_usage_hours: p.daily_usage_hours,
        repair_cost_percentage: p.repair_cost_percentage&.to_f,
        paid_off: p.paid_off?,
        months_to_payoff: p.months_to_payoff,
        created_at: p.created_at.iso8601
      }
    end
    private_class_method :serialize_printer

    def self.serialize_filament(f)
      {
        id: f.id,
        name: f.name,
        brand: f.brand,
        material_type: f.material_type,
        color: f.color,
        diameter: f.diameter&.to_f,
        spool_weight: f.spool_weight&.to_f,
        spool_price: f.spool_price&.to_f,
        cost_per_gram: f.cost_per_gram&.to_f,
        notes: f.notes,
        created_at: f.created_at.iso8601
      }
    end
    private_class_method :serialize_filament

    def self.serialize_client(c)
      {
        id: c.id,
        name: c.name,
        email: c.email,
        phone: c.phone,
        company_name: c.company_name,
        address: c.address,
        tax_id: c.tax_id,
        notes: c.notes,
        created_at: c.created_at.iso8601
      }
    end
    private_class_method :serialize_client

    def self.serialize_print_pricing(pp, include_plates: false)
      data = {
        id: pp.id,
        job_name: pp.job_name,
        units: pp.units,
        times_printed: pp.times_printed,
        total_material_cost: pp.total_material_cost&.to_f,
        total_electricity_cost: pp.total_electricity_cost&.to_f,
        total_labor_cost: pp.total_labor_cost&.to_f,
        total_machine_upkeep_cost: pp.total_machine_upkeep_cost&.to_f,
        final_price: pp.final_price&.to_f,
        per_unit_price: pp.per_unit_price&.to_f,
        currency: pp.default_currency,
        printer_id: pp.printer_id,
        printer_name: pp.printer&.name,
        client_id: pp.client_id,
        client_name: pp.client&.name,
        created_at: pp.created_at.iso8601
      }
      data[:plates] = pp.plates.map { |plate| serialize_plate(plate) } if include_plates
      data
    end
    private_class_method :serialize_print_pricing

    def self.serialize_plate(plate)
      {
        id: plate.id,
        material_technology: plate.material_technology,
        printing_time_hours: plate.printing_time_hours,
        printing_time_minutes: plate.printing_time_minutes,
        total_material_cost: plate.total_material_cost&.to_f,
        filaments: plate.fdm? ? plate.plate_filaments.map { |pf|
          {
            filament_id: pf.filament_id,
            filament_name: pf.filament&.name,
            weight_grams: pf.filament_weight&.to_f,
            cost: pf.total_cost&.to_f
          }
        } : [],
        resins: plate.resin? ? plate.plate_resins.map { |pr|
          {
            resin_id: pr.resin_id,
            resin_name: pr.resin&.display_name,
            volume_ml: pr.resin_volume_ml&.to_f,
            cost: pr.total_cost&.to_f
          }
        } : []
      }
    end
    private_class_method :serialize_plate

    def self.serialize_printer_profile(pp)
      {
        id: pp.id,
        manufacturer: pp.manufacturer,
        model: pp.model,
        technology: pp.technology,
        category: pp.category,
        power_consumption_avg_watts: pp.power_consumption_avg_watts,
        power_consumption_peak_watts: pp.power_consumption_peak_watts,
        cost_usd: pp.cost_usd&.to_f,
        display_name: pp.try(:display_name),
        full_display_name: pp.try(:full_display_name)
      }
    end
    private_class_method :serialize_printer_profile
  end
end
