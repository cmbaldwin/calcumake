# frozen_string_literal: true

require "test_helper"

class BadgeComponentTest < ViewComponent::TestCase
  test "renders with required attributes" do
    render_inline(BadgeComponent.new(text: "New"))

    assert_selector "span.badge.bg-primary", text: "New"
  end

  test "applies default variant" do
    render_inline(BadgeComponent.new(text: "Badge"))

    assert_selector "span.bg-primary"
  end

  test "renders with success variant" do
    render_inline(BadgeComponent.new(text: "Active", variant: "success"))

    assert_selector "span.badge.bg-success", text: "Active"
  end

  test "renders with danger variant" do
    render_inline(BadgeComponent.new(text: "Error", variant: "danger"))

    assert_selector "span.badge.bg-danger", text: "Error"
  end

  test "renders with warning variant" do
    render_inline(BadgeComponent.new(text: "Warning", variant: "warning"))

    assert_selector "span.badge.bg-warning", text: "Warning"
  end

  test "renders with info variant" do
    render_inline(BadgeComponent.new(text: "Info", variant: "info"))

    assert_selector "span.badge.bg-info", text: "Info"
  end

  test "renders with secondary variant" do
    render_inline(BadgeComponent.new(text: "Secondary", variant: "secondary"))

    assert_selector "span.badge.bg-secondary", text: "Secondary"
  end

  test "renders with light variant" do
    render_inline(BadgeComponent.new(text: "Light", variant: "light"))

    assert_selector "span.badge.bg-light", text: "Light"
  end

  test "renders with dark variant" do
    render_inline(BadgeComponent.new(text: "Dark", variant: "dark"))

    assert_selector "span.badge.bg-dark", text: "Dark"
  end

  test "renders as pill when pill is true" do
    render_inline(BadgeComponent.new(text: "Pill", pill: true))

    assert_selector "span.badge.rounded-pill", text: "Pill"
  end

  test "does not render as pill when pill is false" do
    render_inline(BadgeComponent.new(text: "Not Pill", pill: false))

    assert_selector "span.badge"
    refute_selector "span.rounded-pill"
  end

  test "renders with icon" do
    render_inline(BadgeComponent.new(text: "With Icon", icon: "check-circle"))

    assert_selector "span.badge i.bi-check-circle"
    assert_selector "span.badge", text: "With Icon"
  end

  test "renders without icon by default" do
    render_inline(BadgeComponent.new(text: "No Icon"))

    assert_selector "span.badge"
    refute_selector "i.bi"
  end

  test "renders with small size" do
    render_inline(BadgeComponent.new(text: "Small", size: "sm"))

    assert_selector "span.badge.badge-sm", text: "Small"
  end

  test "renders with large size" do
    render_inline(BadgeComponent.new(text: "Large", size: "lg"))

    assert_selector "span.badge.badge-lg", text: "Large"
  end

  test "renders without size class for medium" do
    render_inline(BadgeComponent.new(text: "Medium", size: "md"))

    assert_selector "span.badge"
    refute_selector "span.badge-md"
  end

  test "raises error for invalid variant" do
    error = assert_raises(ArgumentError) do
      BadgeComponent.new(text: "Test", variant: "invalid")
    end

    assert_match(/Invalid variant/, error.message)
  end

  test "raises error for invalid size" do
    error = assert_raises(ArgumentError) do
      BadgeComponent.new(text: "Test", size: "xl")
    end

    assert_match(/Invalid size/, error.message)
  end

  test "renders with custom html options" do
    render_inline(BadgeComponent.new(
      text: "Custom",
      html_options: { class: "custom-class" }
    ))

    assert_selector "span.badge.custom-class", text: "Custom"
  end

  test "combines pill, icon, and custom variant" do
    render_inline(BadgeComponent.new(
      text: "Complete",
      variant: "success",
      icon: "check",
      pill: true
    ))

    assert_selector "span.badge.bg-success.rounded-pill"
    assert_selector "i.bi-check"
    assert_selector "span", text: "Complete"
  end
end
