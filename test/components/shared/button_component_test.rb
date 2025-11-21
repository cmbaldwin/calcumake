# frozen_string_literal: true

require "test_helper"

module Shared
  class ButtonComponentTest < ViewComponent::TestCase
    test "renders basic button with default variant" do
      render_inline(Shared::ButtonComponent.new(text: "Click Me"))

      assert_selector "button.btn.btn-primary[type='button']", text: "Click Me"
    end

    test "renders button with secondary variant" do
      render_inline(Shared::ButtonComponent.new(text: "Cancel", variant: "secondary"))

      assert_selector "button.btn.btn-secondary", text: "Cancel"
    end

    test "renders button with success variant" do
      render_inline(Shared::ButtonComponent.new(text: "Save", variant: "success"))

      assert_selector "button.btn.btn-success", text: "Save"
    end

    test "renders button with danger variant" do
      render_inline(Shared::ButtonComponent.new(text: "Delete", variant: "danger"))

      assert_selector "button.btn.btn-danger", text: "Delete"
    end

    test "renders button with outline variant" do
      render_inline(Shared::ButtonComponent.new(text: "More", variant: "outline-primary"))

      assert_selector "button.btn.btn-outline-primary", text: "More"
    end

    test "renders small button" do
      render_inline(Shared::ButtonComponent.new(text: "Small", size: "sm"))

      assert_selector "button.btn.btn-sm", text: "Small"
    end

    test "renders medium button (default)" do
      render_inline(Shared::ButtonComponent.new(text: "Medium", size: "md"))

      assert_selector "button.btn.btn-primary", text: "Medium"
      assert_no_selector "button.btn-sm"
      assert_no_selector "button.btn-lg"
    end

    test "renders large button" do
      render_inline(Shared::ButtonComponent.new(text: "Large", size: "lg"))

      assert_selector "button.btn.btn-lg", text: "Large"
    end

    test "renders button with icon on left (default position)" do
      render_inline(Shared::ButtonComponent.new(text: "Save", icon: "check"))

      assert_selector "button.btn" do
        assert_selector "i.bi.bi-check"
        assert_text "Save"
      end
    end

    test "renders button with icon on right" do
      render_inline(Shared::ButtonComponent.new(text: "Next", icon: "arrow-right", icon_position: :right))

      result = render_inline(Shared::ButtonComponent.new(text: "Next", icon: "arrow-right", icon_position: :right))

      # Icon should come after text
      assert_match(/Next.*bi-arrow-right/m, result.to_html)
    end

    test "renders disabled button" do
      render_inline(Shared::ButtonComponent.new(text: "Disabled", disabled: true))

      assert_selector "button.btn.disabled[disabled]", text: "Disabled"
    end

    test "renders loading button with spinner" do
      render_inline(Shared::ButtonComponent.new(text: "Loading...", loading: true))

      assert_selector "button.btn" do
        assert_selector "i.bi.bi-arrow-clockwise.icon-spin"
        assert_text "Loading..."
      end
    end

    test "loading state replaces icon" do
      render_inline(Shared::ButtonComponent.new(text: "Save", icon: "check", loading: true))

      assert_selector "button.btn" do
        assert_selector "i.bi-arrow-clockwise.icon-spin"
        assert_no_selector "i.bi-check"
      end
    end

    test "renders link button when url provided" do
      render_inline(Shared::ButtonComponent.new(text: "View", url: "/products/1"))

      assert_selector "a.btn.btn-primary[href='/products/1']", text: "View"
      assert_no_selector "button"
    end

    test "link button with non-get method adds turbo data attribute" do
      render_inline(Shared::ButtonComponent.new(text: "Delete", url: "/products/1", method: :delete))

      assert_selector "a.btn[data-turbo-method='delete']", text: "Delete"
    end

    test "link button with get method does not add turbo method" do
      render_inline(Shared::ButtonComponent.new(text: "View", url: "/products/1", method: :get))

      assert_selector "a.btn[href='/products/1']", text: "View"
      assert_no_selector "a[data-turbo-method]"
    end

    test "disabled link button has disabled class but not disabled attribute" do
      render_inline(Shared::ButtonComponent.new(text: "Disabled Link", url: "/test", disabled: true))

      assert_selector "a.btn.disabled[href='/test']", text: "Disabled Link"
      assert_no_selector "a[disabled]" # Links don't have disabled attribute
    end

    test "renders submit button" do
      render_inline(Shared::ButtonComponent.new(text: "Submit", type: "submit"))

      assert_selector "button.btn[type='submit']", text: "Submit"
    end

    test "renders reset button" do
      render_inline(Shared::ButtonComponent.new(text: "Reset", type: "reset"))

      assert_selector "button.btn[type='reset']", text: "Reset"
    end

    test "accepts additional html_options" do
      render_inline(Shared::ButtonComponent.new(
        text: "Custom",
        html_options: { id: "custom-btn", data: { controller: "click" } }
      ))

      assert_selector "button.btn#custom-btn[data-controller='click']", text: "Custom"
    end

    test "merges custom class from html_options" do
      render_inline(Shared::ButtonComponent.new(
        text: "Custom Class",
        html_options: { class: "my-custom-class" }
      ))

      assert_selector "button.btn.btn-primary.my-custom-class", text: "Custom Class"
    end

    test "renders button with block content" do
      render_inline(Shared::ButtonComponent.new(variant: "success")) do
        "<strong>Bold</strong> Text".html_safe
      end

      assert_selector "button.btn.btn-success" do
        assert_selector "strong", text: "Bold"
        assert_text "Text"
      end
    end

    test "combines all features" do
      render_inline(Shared::ButtonComponent.new(
        text: "Complete",
        variant: "success",
        size: "lg",
        icon: "check-circle",
        icon_position: :left,
        html_options: { id: "complete-btn" }
      ))

      assert_selector "button.btn.btn-success.btn-lg#complete-btn" do
        assert_selector "i.bi.bi-check-circle"
        assert_text "Complete"
      end
    end
  end
end
