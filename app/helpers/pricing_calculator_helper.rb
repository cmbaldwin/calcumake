# frozen_string_literal: true

module PricingCalculatorHelper
  # Returns array of calculator features for display
  def calculator_features
    [
      t("advanced_calculator.features.multi_plate"),
      t("advanced_calculator.features.multi_filament"),
      t("advanced_calculator.features.auto_save"),
      t("advanced_calculator.features.pdf_csv_export"),
      t("advanced_calculator.features.real_time"),
      t("advanced_calculator.features.no_signup")
    ]
  end

  # Data attributes for the calculator controller
  def calculator_data_attributes
    {
      data: {
        controller: "advanced-calculator",
        "advanced-calculator-energy-cost-value": 0.12,
        "advanced-calculator-currency-value": "USD",
        "advanced-calculator-locale-value": I18n.locale.to_s.gsub("_", "-"),
        "advanced-calculator-max-plates-value": 10
      }
    }
  end

  # Meta tags for calculator page
  def calculator_meta_title
    t("advanced_calculator.meta.title", default: "Free 3D Print Pricing Calculator | CalcuMake")
  end

  def calculator_meta_description
    t("advanced_calculator.meta.description",
      default: "Calculate 3D printing costs accurately. Multi-plate support, PDF export, no signup required. Free forever.")
  end

  def calculator_meta_keywords
    t("advanced_calculator.meta.keywords",
      default: "3d printing cost calculator, filament cost, print pricing, batch calculator")
  end
end
