require "test_helper"

module Analytics
  class ChartComponentTest < ViewComponent::TestCase
    test "renders chart canvas with title" do
      chart_data = {
        labels: ["Jan", "Feb", "Mar"],
        datasets: [{
          label: "Revenue",
          data: [100, 200, 150]
        }]
      }

      render_inline(Analytics::ChartComponent.new(
        title: "Revenue Over Time",
        chart_data: chart_data
      ))

      assert_selector "h5", text: "Revenue Over Time"
      assert_selector "canvas[data-controller='chart']"
    end

    test "sets chart type via data attribute" do
      chart_data = { labels: [], datasets: [] }

      render_inline(Analytics::ChartComponent.new(
        title: "Test Chart",
        chart_data: chart_data,
        chart_type: "bar"
      ))

      assert_selector "canvas[data-chart-type-value='bar']"
    end

    test "defaults to line chart type" do
      chart_data = { labels: [], datasets: [] }

      render_inline(Analytics::ChartComponent.new(
        title: "Test Chart",
        chart_data: chart_data
      ))

      assert_selector "canvas[data-chart-type-value='line']"
    end

    test "passes chart data as JSON" do
      chart_data = {
        labels: ["A", "B"],
        datasets: [{
          label: "Test",
          data: [10, 20]
        }]
      }

      render_inline(Analytics::ChartComponent.new(
        title: "Test",
        chart_data: chart_data
      ))

      # Verify canvas has data attribute with JSON
      assert_selector "canvas[data-chart-data-value]"
    end

    test "sets custom height" do
      chart_data = { labels: [], datasets: [] }

      render_inline(Analytics::ChartComponent.new(
        title: "Test",
        chart_data: chart_data,
        height: "400px"
      ))

      assert_selector "canvas[style*='max-height: 400px']"
    end

    test "wraps in card with header and body" do
      chart_data = { labels: [], datasets: [] }

      render_inline(Analytics::ChartComponent.new(
        title: "Test Chart",
        chart_data: chart_data
      ))

      assert_selector ".card > .card-header"
      assert_selector ".card > .card-body"
    end
  end
end
