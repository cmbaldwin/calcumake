# frozen_string_literal: true

module Shared
  class StatsCardComponent < ViewComponent::Base
    def initialize(value:, label:, color: "primary", col_class: "col-6 col-lg", trend: nil)
      @value = value
      @label = label
      @color = color
      @col_class = col_class
      @trend = trend
    end

    def bg_class
      "bg-#{@color}"
    end

    def trend_class
      return "" unless @trend

      if @trend > 0
        "text-success"
      elsif @trend < 0
        "text-danger"
      else
        "text-muted"
      end
    end

    def trend_icon
      return "" unless @trend

      if @trend > 0
        "↑"
      elsif @trend < 0
        "↓"
      else
        "→"
      end
    end

    def show_trend?
      @trend != nil
    end
  end
end
