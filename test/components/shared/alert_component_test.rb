# frozen_string_literal: true

require "test_helper"

module Shared
  class AlertComponentTest < ViewComponent::TestCase
    test "renders basic alert with message" do
      render_inline(Shared::AlertComponent.new(message: "Alert message"))
      
      assert_selector "div.alert.alert-info[role='alert']", text: "Alert message"
    end

    test "renders success alert" do
      render_inline(Shared::AlertComponent.new(message: "Success!", variant: "success"))
      
      assert_selector "div.alert.alert-success"
    end

    test "renders info alert" do
      render_inline(Shared::AlertComponent.new(message: "Info", variant: "info"))
      
      assert_selector "div.alert.alert-info"
    end

    test "renders warning alert" do
      render_inline(Shared::AlertComponent.new(message: "Warning", variant: "warning"))
      
      assert_selector "div.alert.alert-warning"
    end

    test "renders danger alert" do
      render_inline(Shared::AlertComponent.new(message: "Error", variant: "danger"))
      
      assert_selector "div.alert.alert-danger"
    end

    test "renders dismissible alert by default" do
      render_inline(Shared::AlertComponent.new(message: "Dismissible"))
      
      assert_selector "div.alert.alert-dismissible.fade.show"
      assert_selector "button.btn-close[data-bs-dismiss='alert']"
    end

    test "renders non-dismissible alert" do
      render_inline(Shared::AlertComponent.new(message: "Not dismissible", dismissible: false))
      
      assert_selector "div.alert"
      assert_no_selector "div.alert-dismissible"
      assert_no_selector "button.btn-close"
    end

    test "renders alert with icon" do
      render_inline(Shared::AlertComponent.new(message: "With icon", icon: "check-circle"))
      
      assert_selector "div.alert" do
        assert_selector "i.bi.bi-check-circle"
        assert_text "With icon"
      end
    end

    test "icon appears before message" do
      result = render_inline(Shared::AlertComponent.new(message: "Message", icon: "info-circle"))
      
      # Icon should come before text in HTML
      assert_match(/bi-info-circle.*Message/m, result.to_html)
    end

    test "renders alert with block content" do
      render_inline(Shared::AlertComponent.new(variant: "success")) do
        "<strong>Success!</strong> Changes saved.".html_safe
      end
      
      assert_selector "div.alert.alert-success" do
        assert_selector "strong", text: "Success!"
        assert_text "Changes saved."
      end
    end

    test "block content takes precedence over message parameter" do
      render_inline(Shared::AlertComponent.new(message: "Ignored", variant: "info")) do
        "Block content"
      end
      
      assert_selector "div.alert", text: "Block content"
      assert_no_text "Ignored"
    end

    test "alert has role attribute" do
      render_inline(Shared::AlertComponent.new(message: "Message"))
      
      assert_selector "div.alert[role='alert']"
    end

    test "accepts additional html_options" do
      render_inline(Shared::AlertComponent.new(
        message: "Custom",
        html_options: { id: "custom-alert", data: { controller: "alert" } }
      ))
      
      assert_selector "div.alert#custom-alert[data-controller='alert']"
    end

    test "merges custom class from html_options" do
      render_inline(Shared::AlertComponent.new(
        message: "Custom class",
        html_options: { class: "mt-4 mb-0" }
      ))
      
      assert_selector "div.alert.alert-info.mt-4.mb-0"
    end

    test "combines variant, dismissible, and icon" do
      render_inline(Shared::AlertComponent.new(
        message: "Complete alert",
        variant: "warning",
        dismissible: true,
        icon: "exclamation-triangle"
      ))
      
      assert_selector "div.alert.alert-warning.alert-dismissible.fade.show" do
        assert_selector "i.bi.bi-exclamation-triangle"
        assert_text "Complete alert"
        assert_selector "button.btn-close"
      end
    end

    test "dismissible alert has proper Bootstrap classes" do
      render_inline(Shared::AlertComponent.new(message: "Dismissible", dismissible: true))
      
      # Must have all three classes for Bootstrap dismissible alerts
      assert_selector "div.alert-dismissible.fade.show"
    end

    test "close button has proper attributes" do
      render_inline(Shared::AlertComponent.new(message: "Close me", dismissible: true))
      
      assert_selector "button.btn-close[type='button'][data-bs-dismiss='alert'][aria-label='Close']"
    end

    test "handles empty message" do
      render_inline(Shared::AlertComponent.new(message: ""))
      
      assert_selector "div.alert"
    end

    test "handles nil message with block" do
      render_inline(Shared::AlertComponent.new) do
        "Block content"
      end
      
      assert_selector "div.alert", text: "Block content"
    end

    test "alert with icon and dismissible button" do
      render_inline(Shared::AlertComponent.new(
        message: "Message",
        icon: "info-circle",
        dismissible: true
      ))
      
      assert_selector "div.alert" do
        assert_selector "i.bi.bi-info-circle"
        assert_text "Message"
        assert_selector "button.btn-close"
      end
    end

    test "non-dismissible alert with icon" do
      render_inline(Shared::AlertComponent.new(
        message: "No close",
        icon: "check",
        dismissible: false
      ))
      
      assert_selector "div.alert" do
        assert_selector "i.bi.bi-check"
      end
      assert_no_selector "button.btn-close"
    end

    test "primary variant" do
      render_inline(Shared::AlertComponent.new(message: "Primary", variant: "primary"))
      
      assert_selector "div.alert.alert-primary"
    end

    test "secondary variant" do
      render_inline(Shared::AlertComponent.new(message: "Secondary", variant: "secondary"))
      
      assert_selector "div.alert.alert-secondary"
    end
  end
end
