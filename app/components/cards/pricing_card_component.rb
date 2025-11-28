# frozen_string_literal: true

class Cards::PricingCardComponent < ViewComponent::Base
  def initialize(pricing:, html_options: {})
    @pricing = pricing
    @html_options = html_options
  end

  private

  attr_reader :pricing, :html_options

  def col_classes
    classes = [ "col-12" ]
    classes.concat(Array(html_options[:class])) if html_options[:class]
    classes.join(" ")
  end

  def format_print_time
    total_minutes = pricing.total_printing_time_minutes
    hours = total_minutes / 60
    minutes = total_minutes % 60
    "#{hours}h #{minutes}m"
  end

  def format_creation_date
    pricing.created_at.strftime("%b %d, %Y")
  end

  def plate_count
    pricing.plates.count
  end

  def plate_text
    count = plate_count
    "#{count} plate#{'s' unless count == 1}"
  end

  def filament_types
    pricing.plates.flat_map { |p| p.filament_types.split(", ") }.uniq
  end

  def total_filament_weight
    pricing.plates.sum(&:total_filament_weight).round(1)
  end

  def formatted_price
    "#{pricing.default_currency} #{format_currency(pricing.final_price, pricing.default_currency)}"
  end

  def show_per_unit_price?
    pricing.units && pricing.units > 1
  end

  def formatted_per_unit_price
    return nil unless show_per_unit_price?
    "#{pricing.default_currency} #{format_currency(pricing.per_unit_price, pricing.default_currency)}/unit"
  end

  def format_currency(amount, currency)
    helpers.number_to_currency(amount, unit: "", precision: 2)
  end

  def translate_filament_type(type)
    I18n.t("filament_types.#{type.downcase}", default: type)
  end

  def actions_dropdown_button_attrs
    {
      class: "btn btn-outline-secondary btn-sm dropdown-toggle",
      type: "button",
      data: {
        "bs-toggle": "dropdown",
        "bs-boundary": "viewport",
        "bs-container": "body"
      },
      "aria-expanded": "false"
    }
  end

  def delete_link_attrs
    {
      class: "dropdown-item text-danger",
      data: {
        confirm: I18n.t("print_pricing.confirm_delete", name: pricing.job_name),
        turbo_method: :delete,
        turbo_frame: "_top"
      }
    }
  end
end
