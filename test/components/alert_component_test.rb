# frozen_string_literal: true

require "test_helper"

class AlertComponentTest < ViewComponent::TestCase
  test "renders with required message" do
    render_inline(AlertComponent.new(message: "This is an alert"))

    assert_selector "div.alert", text: "This is an alert"
  end

  test "applies default variant" do
    render_inline(AlertComponent.new(message: "Info message"))

    assert_selector "div.alert-info"
  end

  test "renders with success variant" do
    render_inline(AlertComponent.new(message: "Success!", variant: "success"))

    assert_selector "div.alert-success", text: "Success!"
  end

  test "renders with warning variant" do
    render_inline(AlertComponent.new(message: "Warning!", variant: "warning"))

    assert_selector "div.alert-warning", text: "Warning!"
  end

  test "renders with danger variant" do
    render_inline(AlertComponent.new(message: "Error!", variant: "danger"))

    assert_selector "div.alert-danger", text: "Error!"
  end

  test "renders with primary variant" do
    render_inline(AlertComponent.new(message: "Primary", variant: "primary"))

    assert_selector "div.alert-primary"
  end

  test "renders as dismissible by default" do
    render_inline(AlertComponent.new(message: "Dismissible"))

    assert_selector "div.alert-dismissible.fade.show"
    assert_selector "button.btn-close[data-bs-dismiss='alert']"
  end

  test "renders as non-dismissible when specified" do
    render_inline(AlertComponent.new(message: "Not dismissible", dismissible: false))

    refute_selector "div.alert-dismissible"
    refute_selector "button.btn-close"
  end

  test "renders with default success icon" do
    render_inline(AlertComponent.new(message: "Success", variant: "success"))

    assert_selector "i.bi-check-circle-fill"
  end

  test "renders with default info icon" do
    render_inline(AlertComponent.new(message: "Info", variant: "info"))

    assert_selector "i.bi-info-circle-fill"
  end

  test "renders with default warning icon" do
    render_inline(AlertComponent.new(message: "Warning", variant: "warning"))

    assert_selector "i.bi-exclamation-triangle-fill"
  end

  test "renders with default danger icon" do
    render_inline(AlertComponent.new(message: "Danger", variant: "danger"))

    assert_selector "i.bi-x-circle-fill"
  end

  test "renders with custom icon" do
    render_inline(AlertComponent.new(
      message: "Custom",
      variant: "success",
      icon: "star-fill"
    ))

    assert_selector "i.bi-star-fill"
    refute_selector "i.bi-check-circle-fill"
  end

  test "renders without icon when icon is nil for primary variant" do
    render_inline(AlertComponent.new(message: "No icon", variant: "primary"))

    refute_selector "i.bi"
  end

  test "renders with block content" do
    render_inline(AlertComponent.new(variant: "info")) do
      "<strong>Bold</strong> and regular text".html_safe
    end

    assert_selector "div.alert-info strong", text: "Bold"
    assert_selector "div.alert-info", text: "and regular text"
  end

  test "raises error for invalid variant" do
    error = assert_raises(ArgumentError) do
      AlertComponent.new(message: "Test", variant: "invalid")
    end

    assert_match(/Invalid variant/, error.message)
  end

  test "has proper accessibility attributes" do
    render_inline(AlertComponent.new(message: "Accessible"))

    assert_selector "div[role='alert']"
  end

  test "renders with custom html options" do
    render_inline(AlertComponent.new(
      message: "Custom",
      html_options: { class: "mb-4 custom-alert" }
    ))

    assert_selector "div.alert.mb-4.custom-alert"
  end

  test "combines all features" do
    render_inline(AlertComponent.new(
      message: "Complete alert with all features",
      variant: "success",
      dismissible: true,
      icon: "trophy-fill"
    ))

    assert_selector "div.alert.alert-success.alert-dismissible"
    assert_selector "i.bi-trophy-fill"
    assert_selector "button.btn-close"
    assert_selector "div", text: "Complete alert with all features"
  end
end
