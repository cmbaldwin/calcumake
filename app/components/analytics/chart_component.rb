module Analytics
  class ChartComponent < ViewComponent::Base
    def initialize(title:, chart_data:, chart_type: "line", height: "300px")
      @title = title
      @chart_data = chart_data
      @chart_type = chart_type
      @height = height
    end

    def chart_data_json
      @chart_data.to_json.html_safe
    end
  end
end
