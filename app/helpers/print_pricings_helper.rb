module PrintPricingsHelper
  def format_print_time(pricing)
    "#{pricing.printing_time_hours}h #{pricing.printing_time_minutes}m"
  end

  def format_creation_date(pricing)
    pricing.created_at.strftime("%b %d, %Y")
  end

  def total_print_time_hours(print_pricings)
    print_pricings.sum { |p| p.total_actual_print_time_minutes } / 60
  end

  def pricing_card_metadata_badges(pricing)
    content_tag :div, class: "d-flex gap-2 flex-wrap d-lg-none justify-content-center" do
      concat content_tag(:span, pricing.default_currency, class: "badge bg-secondary")
      concat content_tag(:span, format_print_time(pricing), class: "text-muted")
    end
  end

  def pricing_card_actions(pricing)
    content_tag :div, class: "dropdown text-center" do
      button = content_tag(:button, t("actions.actions"), class: "btn btn-outline-secondary btn-sm dropdown-toggle", type: "button", data: { "bs-toggle": "dropdown", "bs-boundary": "viewport", "bs-container": "body" }, "aria-expanded": "false")

      menu_items = []
      menu_items << content_tag(:li, link_to(t("actions.show"), pricing, class: "dropdown-item"))
      menu_items << content_tag(:li, link_to(t("print_pricing.invoice"), invoice_print_pricing_path(pricing), class: "dropdown-item"))
      menu_items << content_tag(:li, link_to(t("actions.edit"), edit_print_pricing_path(pricing), class: "dropdown-item"))
      menu_items << content_tag(:li, content_tag(:hr, "", class: "dropdown-divider"))
      menu_items << content_tag(:li, link_to(t("actions.delete"), pricing, method: :delete,
                                           class: "dropdown-item text-danger",
                                           data: {
                                             confirm: t("print_pricing.confirm_delete", name: pricing.job_name),
                                             turbo_method: :delete
                                           }))

      menu = content_tag(:ul, menu_items.join.html_safe, class: "dropdown-menu")

      button + menu
    end
  end

  def pricing_show_actions(pricing)
    content_tag :div, class: "dropdown" do
      button = content_tag(:button, t("actions.actions"), class: "btn btn-primary btn-sm dropdown-toggle", type: "button", data: { "bs-toggle": "dropdown" }, "aria-expanded": "false")

      menu_items = []
      menu_items << content_tag(:li, link_to(t("print_pricing.invoice"), invoice_print_pricing_path(pricing), class: "dropdown-item"))
      menu_items << content_tag(:li, link_to(t("actions.edit"), edit_print_pricing_path(pricing), class: "dropdown-item"))
      menu_items << content_tag(:li, content_tag(:hr, "", class: "dropdown-divider"))
      menu_items << content_tag(:li, link_to(t("actions.delete"), pricing, method: :delete,
                                           class: "dropdown-item text-danger",
                                           data: {
                                             confirm: t("print_pricing.confirm_delete", name: pricing.job_name),
                                             turbo_method: :delete
                                           }))

      menu = content_tag(:ul, menu_items.join.html_safe, class: "dropdown-menu")

      button + menu
    end
  end

  def format_detailed_creation_date(pricing)
    pricing.created_at.strftime("%B %d, %Y at %I:%M %p")
  end

  def cost_breakdown_sections(pricing)
    sections = []

    # Basic costs
    sections << {
      title: "Print Information",
      items: [
        [ "Currency", content_tag(:span, pricing.default_currency, class: "badge badge-currency") ],
        [ "Printing Time", format_print_time(pricing) ],
        [ "Filament Weight", "#{pricing.filament_weight}g" ],
        [ "Filament Type", content_tag(:span, pricing.filament_type, class: "badge badge-filament") ]
      ]
    }

    # Filament details
    sections << {
      title: "Filament Details",
      items: [
        [ "Spool Price", format_currency_with_symbol(pricing.spool_price, pricing.default_currency) ],
        [ "Spool Weight", "#{pricing.spool_weight}g" ],
        [ "Markup", "#{pricing.markup_percentage}%" ]
      ]
    }

    # Electricity (if applicable)
    if pricing.printer&.power_consumption && pricing.default_energy_cost_per_kwh
      sections << {
        title: "Electricity",
        items: [
          [ "Power Consumption", "#{pricing.printer.power_consumption}W" ],
          [ "Energy Cost per kWh", format_currency_with_symbol(pricing.default_energy_cost_per_kwh, pricing.default_currency) ]
        ]
      }
    end

    # Labor (if applicable)
    if has_labor_costs?(pricing)
      labor_items = []
      if pricing.prep_time_minutes && pricing.prep_cost_per_hour
        labor_items << [ "Prep Time", "#{pricing.prep_time_minutes} min @ #{format_currency_with_symbol(pricing.prep_cost_per_hour, pricing.default_currency)}/hour" ]
      end
      if pricing.postprocessing_time_minutes && pricing.postprocessing_cost_per_hour
        labor_items << [ "Post-processing", "#{pricing.postprocessing_time_minutes} min @ #{format_currency_with_symbol(pricing.postprocessing_cost_per_hour, pricing.default_currency)}/hour" ]
      end
      sections << { title: "Labor", items: labor_items }
    end

    # Machine costs (if applicable)
    if has_machine_costs?(pricing)
      sections << {
        title: "Machine & Upkeep",
        items: [
          [ "Printer Cost", format_currency_with_symbol(pricing.printer.cost, pricing.default_currency) ],
          [ "Payoff Goal", "#{pricing.printer.payoff_goal_years} years" ],
          [ "Daily Usage", "#{pricing.printer.daily_usage_hours} hours" ],
          [ "Repair Factor", "#{pricing.printer&.repair_cost_percentage || 0}%" ]
        ]
      }
    end

    sections
  end

  def format_currency_with_symbol(amount, currency)
    "#{currency_symbol(currency)}#{format_currency(amount, currency)}"
  end

  private

  def has_labor_costs?(pricing)
    (pricing.prep_time_minutes && pricing.prep_cost_per_hour) ||
    (pricing.postprocessing_time_minutes && pricing.postprocessing_cost_per_hour)
  end

  def has_machine_costs?(pricing)
    pricing.printer&.cost && pricing.printer&.payoff_goal_years && pricing.printer&.daily_usage_hours
  end
end
