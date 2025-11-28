module PrintersHelper
  def spec_card(icon, label, value, condition: true)
    return unless condition

    content_tag :div, class: "spec-card" do
      content_tag(:div, icon, class: "spec-icon") +
      content_tag(:div, class: "spec-details") do
        content_tag(:label, label) +
        content_tag(:span, value)
      end
    end
  end

  def printer_header(printer)
    content_tag :div, class: "printer-header" do
      content_tag(:div, class: "printer-title") do
        content_tag(:h1, printer.name) +
        content_tag(:span, printer.manufacturer, class: "manufacturer-badge")
      end +
      content_tag(:div, class: "printer-actions") do
        link_to(t("actions.edit"), edit_printer_path(printer), class: "primary-button") +
        link_to(t("actions.back"), printers_path, class: "secondary-button")
      end
    end
  end

  def printer_specs(printer)
    specs = [
      [
        "⚡",
        t("printers.card.power_consumption"),
        "#{printer.power_consumption}W"
      ],
      [
        "💰",
        t("printers.card.cost"),
        "#{currency_symbol(current_user.default_currency)}#{number_with_delimiter(printer.cost)}"
      ],
      [
        "⏰",
        t("printers.card.daily_usage"),
        "#{printer.daily_usage_hours} #{t('printers.card.hours')}"
      ],
      [
        "🎯",
        t("printers.card.payoff_goal"),
        "#{printer.payoff_goal_years} #{t('printers.card.years')}"
      ]
    ]

    if printer.repair_cost_percentage && printer.repair_cost_percentage > 0
      specs << [
        "🔧",
        t("printers.card.repair_cost_percentage"),
        "#{number_with_precision(printer.repair_cost_percentage, precision: 1)}%"
      ]
    end

    content_tag :div, class: "specs-section" do
      content_tag(:h2, t("printers.show.specifications")) +
      content_tag(:div, class: "specs-grid") do
        specs.map { |icon, label, value| spec_card(icon, label, value) }.join.html_safe
      end
    end
  end

  def printer_financial_status(printer)
    content_tag :div, class: "financial-section" do
      content_tag(:h2, t("printers.show.financial_status")) +
      content_tag(:div, class: "status-cards") do
        status_card_class = printer.paid_off? ? "paid-off" : "in-progress"
        status_icon = printer.paid_off? ? "✅" : "⏳"

        content_tag(:div, class: "status-card #{status_card_class}") do
          content_tag(:div, status_icon, class: "status-icon") +
          content_tag(:div, class: "status-content") do
            if printer.paid_off?
              content_tag(:h3, t("printers.card.paid_off")) +
              content_tag(:p, t("printers.show.fully_paid_off"))
            else
              content_tag(:h3, t("printers.show.payoff_progress")) +
              content_tag(:p, t("printers.card.months_to_payoff", months: printer.months_to_payoff))
            end
          end
        end
      end
    end
  end

  def printer_jobs_section_header(printer)
    content_tag :div, class: "section-header" do
      content_tag(:h2, t("printers.show.print_jobs")) +
      link_to(t("printers.show.new_print_job"), new_print_pricing_path(printer_id: printer.id), class: "primary-button")
    end
  end

  def printer_form_header(edit_mode = false)
    content_tag :div, class: "page-header" do
      if edit_mode
        content_tag(:h1, "Edit Printer") +
        content_tag(:p, "Update your 3D printer specifications")
      else
        content_tag(:h1, "Add New Printer") +
        content_tag(:p, "Register your 3D printer specifications for accurate cost calculations")
      end
    end
  end

  def printer_form_basic_information(form, printer)
    content_tag :div, class: "form-card" do
      content_tag(:h3, "Basic Information") +
      content_tag(:div, class: "field-group") do
        content_tag(:label, "Printer Name", class: "d-inline-block") +
        render(Shared::InfoPopupComponent.new(translation_key: "info_popups.printers.name")) +
        form.text_field(:name, placeholder: "e.g., My Prusa i3 MK3S+")
      end +
      content_tag(:div, class: "field-group") do
        content_tag(:label, "Manufacturer", class: "d-inline-block") +
        render(Shared::InfoPopupComponent.new(translation_key: "info_popups.printers.manufacturer")) +
        form.select(:manufacturer,
          options_for_select(Printer::MANUFACTURERS.map { |m| [ m, m ] }, printer.manufacturer),
          { prompt: "Select manufacturer" })
      end
    end
  end

  def printer_form_technical_specs(form)
    content_tag :div, class: "form-card" do
      content_tag(:h3, "Technical Specifications") +
      content_tag(:div, class: "field-group") do
        content_tag(:label, "Power Consumption (Watts)", class: "d-inline-block") +
        render(Shared::InfoPopupComponent.new(translation_key: "info_popups.printers.power_consumption")) +
        form.number_field(:power_consumption, step: 1, placeholder: "200") +
        content_tag(:small, "Typical range: 50W (small printers) to 500W (large printers)")
      end
    end
  end

  def printer_form_financial_info(form)
    content_tag :div, class: "form-card" do
      content_tag(:h3, "Financial Information") +
      content_tag(:div, class: "field-group currency-field") do
        content_tag(:label, "Printer Cost", class: "d-inline-block") +
        render(Shared::InfoPopupComponent.new(translation_key: "info_popups.printers.cost")) +
        content_tag(:div, class: "currency-input") do
          content_tag(:span, currency_symbol(current_user.default_currency), class: "currency-symbol") +
          form.number_field(:cost, step: 0.01, placeholder: "500.00")
        end
      end +
      content_tag(:div, class: "field-group") do
        content_tag(:label, "Payoff Goal (Years)", class: "d-inline-block") +
        render(Shared::InfoPopupComponent.new(translation_key: "info_popups.printers.payoff_goal_years")) +
        form.number_field(:payoff_goal_years, min: 1, step: 1, placeholder: "3") +
        content_tag(:small, "How many years do you want to recoup the printer cost?")
      end
    end
  end

  def printer_form_usage_info(form)
    content_tag :div, class: "form-card" do
      content_tag(:h3, "Usage Information") +
      content_tag(:div, class: "field-group") do
        content_tag(:label, "Daily Usage (Hours)", class: "d-inline-block") +
        render(Shared::InfoPopupComponent.new(translation_key: "info_popups.printers.daily_usage_hours")) +
        form.number_field(:daily_usage_hours, min: 1, step: 1, placeholder: "8") +
        content_tag(:small, "Average hours per day you plan to use this printer")
      end +
      content_tag(:div, class: "field-group") do
        content_tag(:label, "Repair Cost Factor (%)", class: "d-inline-block") +
        render(Shared::InfoPopupComponent.new(translation_key: "info_popups.printers.repair_cost_percentage")) +
        form.number_field(:repair_cost_percentage, step: 0.1, placeholder: "5.0") +
        content_tag(:small, "Additional cost factor for maintenance and repairs")
      end
    end
  end

  def printer_form_actions(form, edit_mode = false)
    content_tag :div, class: "form-actions" do
      if edit_mode
        form.submit("Update Printer", class: "primary-button") +
        link_to("Cancel", @printer, class: "secondary-button")
      else
        form.submit("Add Printer", class: "primary-button") +
        link_to("Cancel", printers_path, class: "secondary-button")
      end
    end
  end

  def printer_form_error_messages(printer)
    return unless printer.errors.any?

    content_tag :div, class: "error-messages" do
      content_tag(:h3, "#{pluralize(printer.errors.count, "error")} prohibited this printer from being saved:") +
      content_tag(:ul) do
        printer.errors.full_messages.map { |message| content_tag(:li, message) }.join.html_safe
      end
    end
  end
end
