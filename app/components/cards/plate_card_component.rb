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
        filament_weight: 45,
        filament_price: 25
      }
    end

    def field_config
      {
        print_time: { label: "advanced_calculator.plate_fields.print_time", unit: "(hrs)", min: 0.1, step: 0.1 }
      }
    end
  end
end
