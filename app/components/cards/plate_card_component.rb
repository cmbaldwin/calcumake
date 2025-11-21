# frozen_string_literal: true

module Cards
  class PlateCardComponent < ViewComponent::Base
    def initialize(index:, defaults: {})
      @index = index
      @defaults = default_values.merge(defaults)
    end

    def plate_number
      @index + 1
    end

    def default_values
      {
        print_time: 2.5,
        power_consumption: 200,
        machine_cost: 500,
        payoff_years: 3,
        prep_time: 0.25,
        post_time: 0.25,
        prep_rate: 20,
        post_rate: 20,
        filament_weight: 45,
        filament_price: 25
      }
    end

    def field_config
      {
        print_time: { label: "advanced_calculator.plate_fields.print_time", unit: "(hrs)", min: 0.1, step: 0.1 },
        power_consumption: { label: "advanced_calculator.plate_fields.power_consumption", unit: "(W)", min: 1, step: 1 },
        machine_cost: { label: "advanced_calculator.plate_fields.machine_cost", unit: "", min: 0, step: 1 },
        payoff_years: { label: "advanced_calculator.plate_fields.payoff_years", unit: "", min: 0.5, step: 0.5 },
        prep_time: { label: "advanced_calculator.plate_fields.prep_time", unit: "(hrs)", min: 0, step: 0.05 },
        post_time: { label: "advanced_calculator.plate_fields.post_time", unit: "(hrs)", min: 0, step: 0.05 },
        prep_rate: { label: "advanced_calculator.plate_fields.prep_rate", unit: "($/hr)", min: 0, step: 0.5 },
        post_rate: { label: "advanced_calculator.plate_fields.post_rate", unit: "($/hr)", min: 0, step: 0.5 }
      }
    end
  end
end
