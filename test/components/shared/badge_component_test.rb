# frozen_string_literal: true

require "test_helper"

module Shared
  class BadgeComponentTest < ViewComponent::TestCase
    test "renders basic badge with default variant" do
      render_inline(Shared::BadgeComponent.new(text: "Default"))

      assert_selector "span.badge.bg-primary", text: "Default"
    end

    test "renders badge with secondary variant" do
      render_inline(Shared::BadgeComponent.new(text: "Secondary", variant: "secondary"))

      assert_selector "span.badge.bg-secondary", text: "Secondary"
    end

    test "renders badge with success variant" do
      render_inline(Shared::BadgeComponent.new(text: "Success", variant: "success"))

      assert_selector "span.badge.bg-success", text: "Success"
    end

    test "renders badge with danger variant" do
      render_inline(Shared::BadgeComponent.new(text: "Error", variant: "danger"))

      assert_selector "span.badge.bg-danger", text: "Error"
    end

    test "renders badge with warning variant" do
      render_inline(Shared::BadgeComponent.new(text: "Warning", variant: "warning"))

      assert_selector "span.badge.bg-warning", text: "Warning"
    end

    test "renders badge with info variant" do
      render_inline(Shared::BadgeComponent.new(text: "Info", variant: "info"))

      assert_selector "span.badge.bg-info", text: "Info"
    end

    test "renders pill-shaped badge" do
      render_inline(Shared::BadgeComponent.new(text: "Pill", pill: true))

      assert_selector "span.badge.rounded-pill", text: "Pill"
    end

    test "renders small badge" do
      render_inline(Shared::BadgeComponent.new(text: "Small", size: "sm"))

      assert_selector "span.badge.fs-7.px-2.py-1", text: "Small"
    end

    test "renders medium badge (default size)" do
      render_inline(Shared::BadgeComponent.new(text: "Medium", size: "md"))

      assert_selector "span.badge", text: "Medium"
      assert_no_selector "span.fs-7"
      assert_no_selector "span.fs-5"
    end

    test "renders large badge" do
      render_inline(Shared::BadgeComponent.new(text: "Large", size: "lg"))

      assert_selector "span.badge.fs-5.px-3.py-2", text: "Large"
    end

    test "renders badge with icon" do
      render_inline(Shared::BadgeComponent.new(text: "With Icon", icon: "check-circle"))

      assert_selector "span.badge" do
        assert_selector "i.bi.bi-check-circle"
        assert_text "With Icon"
      end
    end

    test "badge with icon uses small size for icon" do
      render_inline(Shared::BadgeComponent.new(text: "Active", icon: "check", variant: "success"))

      assert_selector "span.badge.bg-success" do
        assert_selector "i.bi.bi-check.fs-6" # IconComponent size="sm" applies fs-6
      end
    end

    test "accepts additional html_options" do
      render_inline(Shared::BadgeComponent.new(
        text: "Custom",
        html_options: { id: "custom-badge", data: { controller: "tooltip" } }
      ))

      assert_selector "span.badge#custom-badge[data-controller='tooltip']", text: "Custom"
    end

    test "merges custom class from html_options" do
      render_inline(Shared::BadgeComponent.new(
        text: "Custom Class",
        html_options: { class: "my-custom-class" }
      ))

      assert_selector "span.badge.bg-primary.my-custom-class", text: "Custom Class"
    end

    test "combines multiple options" do
      render_inline(Shared::BadgeComponent.new(
        text: "Complete",
        variant: "success",
        size: "lg",
        pill: true,
        icon: "check-circle"
      ))

      assert_selector "span.badge.bg-success.rounded-pill.fs-5.px-3.py-2" do
        assert_selector "i.bi.bi-check-circle"
        assert_text "Complete"
      end
    end

    test "handles empty text" do
      render_inline(Shared::BadgeComponent.new(text: ""))

      assert_selector "span.badge"
    end

    test "handles numeric text" do
      render_inline(Shared::BadgeComponent.new(text: "42", variant: "info", pill: true))

      assert_selector "span.badge.bg-info.rounded-pill", text: "42"
    end
  end
end
