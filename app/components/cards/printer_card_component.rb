# frozen_string_literal: true

class Cards::PrinterCardComponent < ViewComponent::Base
  def initialize(printer:, current_user:, html_options: {})
    @printer = printer
    @current_user = current_user
    @html_options = html_options
  end

  private

  attr_reader :printer, :current_user, :html_options

  def col_classes
    classes = [ "col-lg-4", "col-md-6" ]
    classes.concat(Array(html_options[:class])) if html_options[:class]
    classes.join(" ")
  end

  def manufacturer_badge_text
    printer.manufacturer
  end

  def power_consumption_text
    "#{printer.power_consumption}W"
  end

  def cost_text
    "#{currency_symbol}#{printer.cost}"
  end

  def currency_symbol
    helpers.currency_symbol(current_user.default_currency)
  end

  def daily_usage_text
    "#{printer.daily_usage_hours} #{I18n.t('printers.card.hours')}"
  end

  def payoff_goal_text
    "#{printer.payoff_goal_years} #{I18n.t('printers.card.years')}"
  end

  def paid_off?
    printer.paid_off?
  end

  def paid_off_alert_text
    I18n.t("printers.card.paid_off")
  end

  def months_to_payoff_alert_text
    I18n.t("printers.card.months_to_payoff", months: printer.months_to_payoff)
  end

  def dropdown_button_attrs
    {
      class: "btn btn-outline-secondary btn-sm dropdown-toggle",
      type: "button",
      data: { "bs-toggle": "dropdown" },
      "aria-expanded": "false"
    }
  end

  def delete_link_attrs
    {
      class: "dropdown-item text-danger",
      data: { turbo_method: :delete }
    }
  end
end
