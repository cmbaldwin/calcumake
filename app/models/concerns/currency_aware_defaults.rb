# frozen_string_literal: true

# Provides currency-aware default values for pricing calculations
# Different currencies have vastly different scales, so we need realistic defaults per currency
module CurrencyAwareDefaults
  extend ActiveSupport::Concern

  # Currency exchange rates relative to USD (approximate)
  CURRENCY_SCALES = {
    "USD" => 1.0,      # US Dollar (base)
    "EUR" => 0.92,     # Euro
    "GBP" => 0.79,     # British Pound
    "JPY" => 150.0,    # Japanese Yen
    "CNY" => 7.2,      # Chinese Yuan
    "KRW" => 1300.0,   # Korean Won
    "INR" => 83.0,     # Indian Rupee
    "BRL" => 5.0,      # Brazilian Real
    "MXN" => 17.0,     # Mexican Peso
    "CAD" => 1.36,     # Canadian Dollar
    "AUD" => 1.52      # Australian Dollar
  }.freeze

  # Base defaults in USD
  BASE_DEFAULTS = {
    energy_cost_per_kwh: 0.12,          # $0.12/kWh (US average)
    other_costs: 3.0,                    # $3.00 per print (packaging, labels, etc.)
    prep_cost_per_hour: 20.0,           # $20/hour for prep work
    postprocessing_cost_per_hour: 20.0, # $20/hour for post-processing
    filament_markup_percentage: 20.0,   # 20% markup on filament (currency-independent)
    vat_percentage: 0.0,                # 0% VAT default (varies by country, not currency)
    listing_cost_percentage: 0.0,       # 0% marketplace fees default
    payment_processing_cost_percentage: 0.0 # 0% payment processing default
  }.freeze

  included do
    before_validation :set_currency_aware_defaults, on: :create
  end

  private

  def set_currency_aware_defaults
    currency = default_currency.presence || "USD"
    scale = CURRENCY_SCALES[currency] || 1.0

    # Override database defaults with currency-aware values
    # Only set if the value matches the old JPY-oriented defaults or is nil
    set_if_default(:default_energy_cost_per_kwh, BASE_DEFAULTS[:energy_cost_per_kwh] * scale, 0.12)
    set_if_default(:default_other_costs, BASE_DEFAULTS[:other_costs] * scale, 450.0)
    set_if_default(:default_prep_cost_per_hour, BASE_DEFAULTS[:prep_cost_per_hour] * scale, 1000.0)
    set_if_default(:default_postprocessing_cost_per_hour, BASE_DEFAULTS[:postprocessing_cost_per_hour] * scale, 1000.0)

    # Set percentage-based defaults (currency-independent)
    self.default_filament_markup_percentage ||= BASE_DEFAULTS[:filament_markup_percentage]
    self.default_vat_percentage ||= BASE_DEFAULTS[:vat_percentage]
    self.default_listing_cost_percentage ||= BASE_DEFAULTS[:listing_cost_percentage]
    self.default_payment_processing_cost_percentage ||= BASE_DEFAULTS[:payment_processing_cost_percentage]
  end

  # Set value if it's nil or matches the old database default
  # But only if this is a truly new record (not just unsaved with explicitly set values)
  def set_if_default(attribute, new_value, old_default)
    current_value = send(attribute)
    # Don't override if value was explicitly set to nil (for validation testing)
    return if current_value.nil? && attribute_changed?(attribute)

    if current_value.nil? || current_value.to_f == old_default.to_f
      send("#{attribute}=", new_value.round(attribute == :default_energy_cost_per_kwh ? 4 : 2))
    end
  end
end
