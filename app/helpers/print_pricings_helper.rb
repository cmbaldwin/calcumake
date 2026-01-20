module PrintPricingsHelper
  def format_print_time(pricing)
    total_minutes = pricing.total_printing_time_minutes
    hours = total_minutes / 60
    minutes = total_minutes % 60
    "#{hours}h #{minutes}m"
  end

  def format_creation_date(pricing)
    pricing.created_at.strftime("%b %d, %Y")
  end

  def total_print_time_hours(print_pricings)
    print_pricings.sum { |p| p.total_actual_print_time_minutes } / 60
  end

  def total_filament_weight_grams(print_pricings)
    print_pricings.sum { |p| p.plates.sum(&:total_filament_weight) * (p.times_printed || 0) }
  end

  def total_estimated_sales(print_pricings)
    print_pricings.sum { |p| (p.final_price || 0) * (p.times_printed || 0) }
  end

  def total_estimated_profit(print_pricings)
    print_pricings.sum { |p|
      subtotal = p.calculate_subtotal
      profit_per_print = (p.final_price || 0) - subtotal
      profit_per_print * (p.times_printed || 0)
    }
  end

  def pricing_card_metadata_badges(pricing)
    content_tag :div, class: "d-flex gap-2 flex-wrap d-lg-none justify-content-center" do
      concat content_tag(:span, "#{pricing.plates.count} plate#{'s' unless pricing.plates.count == 1}", class: "badge bg-info")
      pricing.plates.flat_map { |p| p.filament_types.split(", ") }.uniq.each do |type|
        concat content_tag(:span, translate_filament_type(type), class: "badge bg-secondary")
      end
      total_weight = pricing.plates.sum(&:total_filament_weight).round(1)
      concat content_tag(:small, "#{total_weight}g | #{format_print_time(pricing)}", class: "text-muted")
    end
  end

  def pricing_card_actions(pricing)
    content_tag :div, class: "dropdown text-center" do
      button = content_tag(:button, t("actions.actions"), class: "btn btn-outline-secondary btn-sm dropdown-toggle", type: "button", data: { "bs-toggle": "dropdown", "bs-boundary": "viewport", "bs-container": "body" }, "aria-expanded": "false")

      menu_items = []
      menu_items << content_tag(:li, link_to(t("actions.show"), pricing, class: "dropdown-item", data: { turbo_frame: "_top" }))
      menu_items << content_tag(:li, link_to(t("invoices.title"), print_pricing_invoices_path(pricing), class: "dropdown-item", data: { turbo_frame: "_top" }))
      menu_items << content_tag(:li, link_to(t("actions.edit"), edit_print_pricing_path(pricing), class: "dropdown-item", data: { turbo_frame: "_top" }))
      menu_items << content_tag(:li, content_tag(:hr, "", class: "dropdown-divider"))
      menu_items << content_tag(:li, link_to(t("actions.delete"), pricing, method: :delete,
                                           class: "dropdown-item text-danger",
                                           data: {
                                             confirm: t("print_pricing.confirm_delete", name: pricing.job_name),
                                             turbo_method: :delete,
                                             turbo_frame: "_top"
                                           }))

      menu = content_tag(:ul, menu_items.join.html_safe, class: "dropdown-menu")

      button + menu
    end
  end

  def pricing_show_actions(pricing)
    content_tag :div, class: "dropdown" do
      button = content_tag(:button, t("actions.actions"), class: "btn btn-primary btn-sm dropdown-toggle", type: "button", data: { "bs-toggle": "dropdown" }, "aria-expanded": "false")

      menu_items = []
      menu_items << content_tag(:li, link_to(t("actions.edit"), edit_print_pricing_path(pricing),
                                           class: "dropdown-item", data: { turbo_frame: "_top" }))
      menu_items << content_tag(:li, link_to(t("actions.duplicate"), duplicate_print_pricing_path(pricing),
                                           method: :post, class: "dropdown-item",
                                           data: { turbo_method: :post, turbo_frame: "_top" }))
      menu_items << content_tag(:li, content_tag(:hr, "", class: "dropdown-divider"))
      menu_items << content_tag(:li, link_to(t("actions.delete"), pricing, method: :delete,
                                           class: "dropdown-item text-danger",
                                           data: {
                                             confirm: t("print_pricing.confirm_delete", name: pricing.job_name),
                                             turbo_method: :delete,
                                             turbo_frame: "_top"
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
    print_info_items = [
      [ "Currency", content_tag(:span, pricing.default_currency, class: "badge badge-currency") ],
      [ "Total Printing Time", format_print_time(pricing) ],
      [ "Number of Plates", pricing.plates.count.to_s ],
      [ "Times Printed", pricing.times_printed.to_s ]
    ]

    if pricing.units && pricing.units > 1
      print_info_items << [ "Units", pricing.units.to_s ]
      print_info_items << [ "Per Unit Price", format_currency_with_symbol(pricing.per_unit_price, pricing.default_currency) ]
    end

    if pricing.failure_rate_percentage && pricing.failure_rate_percentage > 0
      print_info_items << [ "Failure Rate", "#{pricing.failure_rate_percentage}%" ]
    end

    sections << {
      title: "Print Information",
      items: print_info_items
    }

    # Plates information
    pricing.plates.each_with_index do |plate, index|
      plate_items = [
        [ "Print Time", "#{plate.printing_time_hours}h #{plate.printing_time_minutes}m" ],
        [ "Total Filament Weight", "#{plate.total_filament_weight.round(1)}g" ],
        [ "Filament Types", plate.filament_types ]
      ]

      # Add each filament as a sub-item
      plate.plate_filaments.each do |pf|
        plate_items << [ "  - #{pf.filament.display_name}", "#{pf.filament_weight}g" ]
      end

      sections << {
        title: "Plate #{index + 1}",
        items: plate_items
      }
    end

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

  # Form helpers for DRYing up form sections
  def form_section_card(title:, columns: "col-12", height_class: nil, &block)
    col_class = columns
    col_class += " #{height_class}" if height_class

    content_tag :div, class: col_class do
      content_tag :div, class: "card" do
        concat(content_tag(:div, class: "card-header") do
          content_tag :h5, title, class: "mb-0"
        end)
        concat(content_tag(:div, class: "card-body", &block))
      end
    end
  end

  def currency_input_group(form, field, label: nil, placeholder: nil, **options)
    label_text = label || t("print_pricing.fields.#{field}")
    content_tag :div, class: "col-12" do
      concat(form.label(field, label_text, class: "form-label"))
      concat(content_tag(:div, class: "input-group") do
        concat(content_tag(:span, currency_symbol(current_user.default_currency), class: "input-group-text"))
        concat(form.number_field(field, { step: 0.01, placeholder: placeholder, class: "form-control" }.merge(options)))
      end)
    end
  end

  def revenue_chart_data(analytics)
    {
      labels: analytics.revenue_by_day.keys.map { |date| date.strftime("%b %d") },
      datasets: [
        {
          label: "Revenue",
          data: analytics.revenue_by_day.values,
          borderColor: "rgb(200, 16, 46)", # Primary red color
          backgroundColor: "rgba(200, 16, 46, 0.1)",
          tension: 0.3,
          fill: true
        }
      ]
    }
  end

  def prints_chart_data(analytics)
    {
      labels: analytics.prints_by_day.keys.map { |date| date.strftime("%b %d") },
      datasets: [
        {
          label: "Prints",
          data: analytics.prints_by_day.values,
          borderColor: "rgb(75, 192, 192)",
          backgroundColor: "rgba(75, 192, 192, 0.1)",
          tension: 0.3,
          fill: true
        }
      ]
    }
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
