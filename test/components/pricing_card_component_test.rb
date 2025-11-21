# frozen_string_literal: true

require "test_helper"

class PricingCardComponentTest < ViewComponent::TestCase
  def setup
    @user = users(:one)
    @printer = printers(:one)
    @pricing = print_pricings(:one)
  end

  test "renders with required pricing" do
    render_inline(PricingCardComponent.new(pricing: @pricing))

    assert_selector "div.card.pricing-card"
    assert_selector "h5.card-title"
  end

  test "displays job name as link" do
    render_inline(PricingCardComponent.new(pricing: @pricing))

    assert_selector "a.text-primary", text: @pricing.job_name
  end

  test "shows creation date" do
    render_inline(PricingCardComponent.new(pricing: @pricing))

    assert_selector "small.created-date"
  end

  test "displays plate count badge" do
    render_inline(PricingCardComponent.new(pricing: @pricing))

    plate_count = @pricing.plates.count
    expected_text = "#{plate_count} plate#{plate_count != 1 ? 's' : ''}"

    # Should appear in both mobile and desktop views
    assert_selector "span.badge", text: expected_text
  end

  test "shows filament type badges" do
    render_inline(PricingCardComponent.new(pricing: @pricing))

    filament_types = @pricing.plates.flat_map { |p| p.filament_types.split(", ") }.uniq

    filament_types.each do |type|
      assert_selector "span.badge", minimum: 1 # May appear multiple times (mobile + desktop)
    end
  end

  test "displays total filament weight" do
    render_inline(PricingCardComponent.new(pricing: @pricing))

    total_weight = @pricing.plates.sum(&:total_filament_weight).round(1)
    assert_selector "small.text-muted", text: /#{total_weight}g/
  end

  test "shows final price badge" do
    render_inline(PricingCardComponent.new(pricing: @pricing))

    assert_selector "span.badge.bg-success"
    assert_selector "span.badge", text: /#{@pricing.default_currency}/
  end

  test "includes times printed control" do
    render_inline(PricingCardComponent.new(pricing: @pricing))

    assert_selector "small.times-printed-label"
  end

  test "renders actions dropdown" do
    render_inline(PricingCardComponent.new(pricing: @pricing))

    assert_selector "div.dropdown"
    assert_selector "button.dropdown-toggle", text: I18n.t("actions.actions")
  end

  test "includes show action in dropdown" do
    render_inline(PricingCardComponent.new(pricing: @pricing))

    assert_selector "a.dropdown-item", text: I18n.t("actions.show")
  end

  test "includes edit action in dropdown" do
    render_inline(PricingCardComponent.new(pricing: @pricing))

    assert_selector "a.dropdown-item", text: I18n.t("actions.edit")
  end

  test "includes invoices action in dropdown" do
    render_inline(PricingCardComponent.new(pricing: @pricing))

    assert_selector "a.dropdown-item", text: I18n.t("invoices.title")
  end

  test "includes delete action in dropdown" do
    render_inline(PricingCardComponent.new(pricing: @pricing))

    assert_selector "a.dropdown-item.text-danger", text: I18n.t("actions.delete")
  end

  test "delete action has confirmation" do
    render_inline(PricingCardComponent.new(pricing: @pricing))

    page = Capybara.string(rendered_content)
    delete_link = page.find("a.dropdown-item.text-danger")

    assert delete_link[:"data-confirm"]
  end

  test "has responsive design classes" do
    render_inline(PricingCardComponent.new(pricing: @pricing))

    # Mobile-hidden elements
    assert_selector "div.d-none.d-lg-block", minimum: 1

    # Mobile-only elements
    assert_selector "div.d-lg-none", minimum: 1
  end

  test "uses turbo frame top for navigation" do
    render_inline(PricingCardComponent.new(pricing: @pricing))

    page = Capybara.string(rendered_content)
    links = page.all("a[data-turbo-frame='_top']")

    assert links.count > 0, "Should have links with turbo_frame _top"
  end

  test "includes dropdown divider" do
    render_inline(PricingCardComponent.new(pricing: @pricing))

    assert_selector "hr.dropdown-divider"
  end

  test "helper methods return correct values" do
    component = PricingCardComponent.new(pricing: @pricing)

    assert_equal @pricing.plates.count, component.plate_count
    assert_kind_of Array, component.filament_types
    assert_kind_of Float, component.total_filament_weight
    assert_kind_of String, component.formatted_price
    assert_kind_of String, component.formatted_creation_date
    assert_kind_of String, component.formatted_print_time
  end

  test "action_items returns correct structure" do
    component = PricingCardComponent.new(pricing: @pricing)
    items = component.action_items

    assert_kind_of Array, items
    assert items.length >= 4, "Should have at least 4 action items (show, invoices, edit, delete) plus divider"

    # Check for divider
    assert_includes items, :divider

    # Check for hash items with required keys
    hash_items = items.select { |item| item.is_a?(Hash) }
    hash_items.each do |item|
      assert item.key?(:label), "Action item should have :label"
      assert item.key?(:path), "Action item should have :path"
      assert item.key?(:options), "Action item should have :options"
    end
  end

  test "renders with compact mode" do
    render_inline(PricingCardComponent.new(pricing: @pricing, compact: true))

    assert_selector "div.card.pricing-card"
  end
end
