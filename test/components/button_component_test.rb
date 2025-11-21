# frozen_string_literal: true

require "test_helper"

class ButtonComponentTest < ViewComponent::TestCase
  test "renders button with required attributes" do
    render_inline(ButtonComponent.new(text: "Click me"))

    assert_selector "button.btn.btn-primary", text: "Click me"
  end

  test "renders with default variant" do
    render_inline(ButtonComponent.new(text: "Button"))

    assert_selector "button.btn-primary"
  end

  test "renders with custom variant" do
    render_inline(ButtonComponent.new(text: "Delete", variant: "danger"))

    assert_selector "button.btn-danger", text: "Delete"
  end

  test "renders with outline variant" do
    render_inline(ButtonComponent.new(text: "Secondary", variant: "outline-secondary"))

    assert_selector "button.btn-outline-secondary", text: "Secondary"
  end

  test "renders with small size" do
    render_inline(ButtonComponent.new(text: "Small", size: "sm"))

    assert_selector "button.btn-sm", text: "Small"
  end

  test "renders with large size" do
    render_inline(ButtonComponent.new(text: "Large", size: "lg"))

    assert_selector "button.btn-lg", text: "Large"
  end

  test "renders without size class for medium" do
    render_inline(ButtonComponent.new(text: "Medium", size: "md"))

    assert_selector "button.btn"
    refute_selector "button.btn-md"
  end

  test "renders with icon" do
    render_inline(ButtonComponent.new(text: "Save", icon: "floppy"))

    assert_selector "button i.bi-floppy"
    assert_selector "button", text: "Save"
  end

  test "renders as link when url is provided" do
    render_inline(ButtonComponent.new(text: "Link", url: "/path"))

    assert_selector "a.btn.btn-primary[href='/path']", text: "Link"
    refute_selector "button"
  end

  test "renders link with method" do
    render_inline(ButtonComponent.new(text: "Delete", url: "/path", method: :delete, variant: "danger"))

    assert_selector "a.btn-danger[href='/path']"
  end

  test "renders with custom data attributes" do
    render_inline(ButtonComponent.new(
      text: "Action",
      data: { controller: "example", action: "click->example#handle" }
    ))

    assert_selector "button[data-controller='example']"
    assert_selector "button[data-action='click->example#handle']"
  end

  test "renders with block content" do
    render_inline(ButtonComponent.new(variant: "success")) do
      "Custom Content"
    end

    assert_selector "button.btn-success", text: "Custom Content"
  end

  test "raises error for invalid variant" do
    error = assert_raises(ArgumentError) do
      ButtonComponent.new(text: "Test", variant: "invalid")
    end

    assert_match(/Invalid variant/, error.message)
  end

  test "raises error for invalid size" do
    error = assert_raises(ArgumentError) do
      ButtonComponent.new(text: "Test", size: "xl")
    end

    assert_match(/Invalid size/, error.message)
  end

  test "renders with custom html options" do
    render_inline(ButtonComponent.new(
      text: "Disabled",
      html_options: { disabled: true, class: "custom-class" }
    ))

    assert_selector "button.btn.custom-class[disabled]"
  end

  test "renders submit button type" do
    render_inline(ButtonComponent.new(text: "Submit", type: "submit"))

    assert_selector "button[type='submit']"
  end
end
