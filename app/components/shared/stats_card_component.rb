# frozen_string_literal: true

module Shared
  class StatsCardComponent < ViewComponent::Base
    def initialize(value:, label:, color: "primary", col_class: "col-6 col-lg")
      @value = value
      @label = label
      @color = color
      @col_class = col_class
    end

    def bg_class
      "bg-#{@color}"
    end
  end
end
