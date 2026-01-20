require "test_helper"

module Shared
  class DateRangeFilterComponentTest < ViewComponent::TestCase
    test "renders preset buttons" do
      form = mock_search_form

      render_inline(Shared::DateRangeFilterComponent.new(form: form))

      assert_selector "button[data-preset='last_7_days']", text: I18n.t("analytics.filters.last_7_days")
      assert_selector "button[data-preset='last_30_days']", text: I18n.t("analytics.filters.last_30_days")
      assert_selector "button[data-preset='last_90_days']", text: I18n.t("analytics.filters.last_90_days")
      assert_selector "button[data-preset='this_month']", text: I18n.t("analytics.filters.this_month")
      assert_selector "button[data-preset='last_month']", text: I18n.t("analytics.filters.last_month")
      assert_selector "button[data-preset='this_year']", text: I18n.t("analytics.filters.this_year")
    end

    test "renders date inputs with Stimulus targets" do
      form = mock_search_form

      render_inline(Shared::DateRangeFilterComponent.new(form: form))

      assert_selector "input[type='date'][data-date-range-filter-target='startDate']"
      assert_selector "input[type='date'][data-date-range-filter-target='endDate']"
    end

    test "renders clear filter button" do
      form = mock_search_form

      render_inline(Shared::DateRangeFilterComponent.new(form: form))

      assert_selector "button[data-action='click->date-range-filter#clearFilter']", text: I18n.t("analytics.filters.clear")
    end

    test "includes date-range-filter controller" do
      form = mock_search_form

      render_inline(Shared::DateRangeFilterComponent.new(form: form))

      assert_selector "[data-controller='date-range-filter']"
    end

    private

    def mock_search_form
      # Create a simple mock form object that responds to search_field
      form = Object.new
      form.define_singleton_method(:search_field) do |field, **options|
        "<input type='date' name='q[#{field}]' #{options.map { |k, v| "#{k.to_s.tr('_', '-')}='#{v}'" }.join(' ')} />".html_safe
      end
      form
    end
  end
end
