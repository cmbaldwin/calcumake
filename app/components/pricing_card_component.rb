# frozen_string_literal: true

class PricingCardComponent < ViewComponent::Base
  include PrintPricingsHelper

  def initialize(pricing:, compact: false)
    @pricing = pricing
    @compact = compact
  end

  def plate_count
    @pricing.plates.count
  end

  def plate_count_text
    "#{plate_count} plate#{plate_count != 1 ? 's' : ''}"
  end

  def filament_types
    @pricing.plates.flat_map { |p| p.filament_types.split(", ") }.uniq
  end

  def total_filament_weight
    @pricing.plates.sum(&:total_filament_weight).round(1)
  end

  def formatted_price
    format_currency(@pricing.final_price, @pricing.default_currency)
  end

  def formatted_creation_date
    format_creation_date(@pricing)
  end

  def formatted_print_time
    format_print_time(@pricing)
  end

  def action_items
    [
      { label: I18n.t("actions.show"), path: @pricing, options: {} },
      { label: I18n.t("invoices.title"), path: Rails.application.routes.url_helpers.print_pricing_invoices_path(@pricing), options: {} },
      { label: I18n.t("actions.edit"), path: Rails.application.routes.url_helpers.edit_print_pricing_path(@pricing), options: {} },
      :divider,
      {
        label: I18n.t("actions.delete"),
        path: @pricing,
        options: {
          class: "text-danger",
          data: {
            confirm: I18n.t("print_pricing.confirm_delete", name: @pricing.job_name),
            turbo_method: :delete,
            turbo_frame: "_top"
          }
        }
      }
    ]
  end
end
