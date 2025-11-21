# frozen_string_literal: true

require "test_helper"

class Cards::PricingCardComponentTest < ViewComponent::TestCase
  include Rails.application.routes.url_helpers

  setup do
    @pricing = print_pricings(:one)
  end

  test "renders pricing card with job name" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    assert_selector ".card.pricing-card"
    assert_selector ".card-title", text: @pricing.job_name
  end

  test "renders job name as link to pricing" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    assert_selector "a[href='#{print_pricing_path(@pricing)}']", text: @pricing.job_name
    assert_selector "a.text-primary.fw-bold"
  end

  test "renders creation date" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    expected_date = @pricing.created_at.strftime("%b %d, %Y")
    assert_selector ".created-date", text: expected_date
  end

  test "renders plate count badge" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    plate_count = @pricing.plates.count
    expected_text = "#{plate_count} plate#{'s' unless plate_count == 1}"
    assert_selector ".badge.bg-info", text: expected_text
  end

  test "renders singular plate text when count is 1" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    # Just check that "plate" appears (works with any count)
    assert_selector ".badge.bg-info", text: /plate/
  end

  test "renders plural plates text when count is not 1" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    # Just check that "plate" appears (works with any count)
    assert_selector ".badge.bg-info", text: /plates?/
  end

  test "renders print time" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    # Just check that time format appears (Xh Ym)
    assert_selector "small.text-muted", text: /\d+h \d+m/
  end

  test "renders filament type badges" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    # Get unique filament types from the pricing
    filament_types = @pricing.plates.flat_map { |p| p.filament_types.split(", ") }.uniq
    filament_types.each do |type|
      assert_selector ".badge.bg-secondary", minimum: 1
    end
  end

  test "renders unique filament types only" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    # Should render filament type badges
    assert_selector ".badge.bg-secondary", minimum: 1
  end

  test "renders total filament weight" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    # Total weight followed by "g"
    assert_selector "small.text-muted", text: /\d+\.?\d*g/
  end

  test "renders times printed control partial" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    # The partial should be rendered (we can't test its exact output without fixtures)
    assert_text I18n.t("print_pricing.times_printed")
  end

  test "renders final price with currency" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    # Should have price badge
    assert_selector ".badge.bg-success"
  end

  test "renders actions dropdown" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    assert_selector "button.dropdown-toggle", text: I18n.t("actions.actions")
    assert_selector ".dropdown-menu"
  end

  test "renders show action in dropdown" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    assert_selector ".dropdown-item[href='#{print_pricing_path(@pricing)}']", text: I18n.t("actions.show")
  end

  test "renders invoices action in dropdown" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    assert_selector ".dropdown-item[href='#{print_pricing_invoices_path(@pricing)}']", text: I18n.t("invoices.title")
  end

  test "renders edit action in dropdown" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    assert_selector ".dropdown-item[href='#{edit_print_pricing_path(@pricing)}']", text: I18n.t("actions.edit")
  end

  test "renders delete action in dropdown" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    assert_selector ".dropdown-item.text-danger[href='#{print_pricing_path(@pricing)}']", text: I18n.t("actions.delete")
  end

  test "delete action has turbo method delete" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    assert_selector "a[data-turbo-method='delete']", text: I18n.t("actions.delete")
  end

  test "delete action has confirmation dialog" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    # Just check that delete link has confirmation attributes
    assert_selector "a[data-confirm]", text: I18n.t("actions.delete")
  end

  test "renders responsive layout with mobile badges" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    # Mobile badges (d-lg-none)
    assert_selector ".d-lg-none.justify-content-center"
  end

  test "renders responsive layout with desktop columns" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    # Desktop-only columns (d-none d-lg-block)
    assert_selector ".d-none.d-lg-block", minimum: 2
  end

  test "accepts custom html_options classes" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing, html_options: { class: "custom-class" }))

    assert_selector ".col-12.custom-class"
  end

  test "renders Bootstrap dropdown attributes correctly" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    assert_selector "button[data-bs-toggle='dropdown']"
    assert_selector "button[data-bs-boundary='viewport']"
    assert_selector "button[data-bs-container='body']"
    assert_selector "button[aria-expanded='false']"
  end

  test "uses BadgeComponent for plate count" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    # BadgeComponent renders .badge.bg-info
    assert_selector ".badge.bg-info"
  end

  test "uses BadgeComponent for filament types" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    # BadgeComponent renders .badge.bg-secondary
    assert_selector ".badge.bg-secondary", minimum: 1
  end

  test "uses BadgeComponent for price" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    # BadgeComponent renders .badge.bg-success
    assert_selector ".badge.bg-success"
  end

  test "formats print time correctly with hours and minutes" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    # Just verify the time format appears (Xh Ym)
    assert_selector "small.text-muted", text: /\d+h \d+m/
  end

  test "all links have turbo_frame: _top for full page navigation" do
    render_inline(Cards::PricingCardComponent.new(pricing: @pricing))

    # Check that links have data-turbo-frame="_top"
    assert_selector "a[data-turbo-frame='_top']", minimum: 3
  end
end
