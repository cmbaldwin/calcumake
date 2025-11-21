# frozen_string_literal: true

require "test_helper"

class UsageStatItemComponentTest < ViewComponent::TestCase
  test "renders with limited usage" do
    render_inline(UsageStatItemComponent.new(
      resource: :print_pricings,
      current: 5,
      limit: 10
    ))

    assert_selector "div.usage-stat"
    assert_selector "span.badge", text: "5/10"
  end

  test "renders resource label from I18n" do
    render_inline(UsageStatItemComponent.new(
      resource: :print_pricings,
      current: 5,
      limit: 10
    ))

    assert_selector "span.text-muted.small"
  end

  test "renders unlimited usage" do
    render_inline(UsageStatItemComponent.new(
      resource: :invoices,
      current: 100,
      limit: Float::INFINITY
    ))

    assert_selector "span.badge", text: I18n.t('usage_limits.unlimited')
    assert_selector "div.text-success"
    assert_selector "i.bi-infinity"
    refute_selector "div.progress"
  end

  test "shows progress bar for limited resources" do
    render_inline(UsageStatItemComponent.new(
      resource: :printers,
      current: 3,
      limit: 10
    ))

    assert_selector "div.progress"
    assert_selector "div.progress-bar"
  end

  test "does not show progress bar for unlimited resources" do
    render_inline(UsageStatItemComponent.new(
      resource: :printers,
      current: 100,
      limit: Float::INFINITY
    ))

    refute_selector "div.progress"
  end

  test "calculates percentage correctly" do
    component = UsageStatItemComponent.new(
      resource: :filaments,
      current: 7,
      limit: 10
    )

    assert_equal 70, component.percentage
  end

  test "percentage is 0 for unlimited" do
    component = UsageStatItemComponent.new(
      resource: :filaments,
      current: 100,
      limit: Float::INFINITY
    )

    assert_equal 0, component.percentage
  end

  test "shows success color when below threshold" do
    render_inline(UsageStatItemComponent.new(
      resource: :printers,
      current: 5,
      limit: 10,
      warning_threshold: 80
    ))

    assert_selector "div.progress-bar.bg-success"
  end

  test "shows warning color when at or above threshold" do
    render_inline(UsageStatItemComponent.new(
      resource: :printers,
      current: 9,
      limit: 10,
      warning_threshold: 80
    ))

    assert_selector "div.progress-bar.bg-warning"
  end

  test "shows warning color at exactly threshold" do
    render_inline(UsageStatItemComponent.new(
      resource: :printers,
      current: 8,
      limit: 10,
      warning_threshold: 80
    ))

    assert_selector "div.progress-bar.bg-warning"
  end

  test "displays percentage used text" do
    render_inline(UsageStatItemComponent.new(
      resource: :invoices,
      current: 30,
      limit: 100
    ))

    assert_selector "small.text-muted", text: "30% used"
  end

  test "caps progress bar at 100%" do
    component = UsageStatItemComponent.new(
      resource: :printers,
      current: 15,
      limit: 10
    )

    render_inline(component)

    page = Capybara.string(rendered_content)
    progress_bar = page.find("div.progress-bar")

    # Should cap at 100% even though actual is 150%
    assert_includes progress_bar[:style], "width: 100%"
  end

  test "uses custom warning threshold" do
    component = UsageStatItemComponent.new(
      resource: :filaments,
      current: 6,
      limit: 10,
      warning_threshold: 50
    )

    assert_equal "bg-warning", component.progress_color
  end

  test "unlimited? returns true for infinity limit" do
    component = UsageStatItemComponent.new(
      resource: :printers,
      current: 10,
      limit: Float::INFINITY
    )

    assert component.unlimited?
  end

  test "unlimited? returns false for finite limit" do
    component = UsageStatItemComponent.new(
      resource: :printers,
      current: 5,
      limit: 10
    )

    refute component.unlimited?
  end

  test "badge_text returns unlimited for infinity" do
    component = UsageStatItemComponent.new(
      resource: :printers,
      current: 10,
      limit: Float::INFINITY
    )

    assert_equal I18n.t('usage_limits.unlimited'), component.badge_text
  end

  test "badge_text returns current/limit for finite" do
    component = UsageStatItemComponent.new(
      resource: :printers,
      current: 5,
      limit: 10
    )

    assert_equal "5/10", component.badge_text
  end

  test "handles zero limit gracefully" do
    component = UsageStatItemComponent.new(
      resource: :printers,
      current: 0,
      limit: 0
    )

    assert_equal 0, component.percentage
  end

  test "has proper accessibility attributes" do
    render_inline(UsageStatItemComponent.new(
      resource: :invoices,
      current: 25,
      limit: 100
    ))

    assert_selector "div.progress-bar[role='progressbar']"
    assert_selector "div[aria-valuenow='25']"
    assert_selector "div[aria-valuemin='0']"
    assert_selector "div[aria-valuemax='100']"
  end
end
