# frozen_string_literal: true

require "test_helper"

module Shared
  class IconComponentTest < ViewComponent::TestCase
    test "renders with required name attribute" do
      render_inline(Shared::IconComponent.new(name: "check"))

      assert_selector "i.bi.bi-check"
    end

    test "applies default medium size" do
      render_inline(Shared::IconComponent.new(name: "check"))

      # Medium is default, no additional class
      assert_selector "i.bi.bi-check"
      refute_selector "i.fs-6" # Not small
      refute_selector "i.fs-4" # Not large
    end

    test "applies small size class" do
      render_inline(Shared::IconComponent.new(name: "check", size: "sm"))

      assert_selector "i.bi.bi-check.fs-6"
    end

    test "applies large size class" do
      render_inline(Shared::IconComponent.new(name: "check", size: "lg"))

      assert_selector "i.bi.bi-check.fs-4"
    end

    test "applies extra large size class" do
      render_inline(Shared::IconComponent.new(name: "check", size: "xl"))

      assert_selector "i.bi.bi-check.fs-2"
    end

    test "applies color class" do
      render_inline(Shared::IconComponent.new(name: "check", color: "success"))

      assert_selector "i.bi.bi-check.text-success"
    end

    test "applies danger color" do
      render_inline(Shared::IconComponent.new(name: "x-circle", color: "danger"))

      assert_selector "i.bi.bi-x-circle.text-danger"
    end

    test "renders without color when nil" do
      render_inline(Shared::IconComponent.new(name: "check", color: nil))

      assert_selector "i.bi.bi-check"
      refute_selector "i[class*='text-']"
    end

    test "applies spin class for loading states" do
      render_inline(Shared::IconComponent.new(name: "arrow-clockwise", spin: true))

      assert_selector "i.bi.bi-arrow-clockwise.icon-spin"
    end

    test "does not apply spin class when false" do
      render_inline(Shared::IconComponent.new(name: "check", spin: false))

      refute_selector "i.icon-spin"
    end

    test "combines size and color" do
      render_inline(Shared::IconComponent.new(
        name: "check-circle",
        size: "lg",
        color: "primary"
      ))

      assert_selector "i.bi.bi-check-circle.fs-4.text-primary"
    end

    test "combines all attributes" do
      render_inline(Shared::IconComponent.new(
        name: "arrow-clockwise",
        size: "xl",
        color: "warning",
        spin: true
      ))

      assert_selector "i.bi.bi-arrow-clockwise.fs-2.text-warning.icon-spin"
    end

    test "accepts additional html_options" do
      render_inline(Shared::IconComponent.new(
        name: "check",
        html_options: { id: "my-icon", data: { controller: "tooltip" } }
      ))

      assert_selector "i#my-icon.bi.bi-check[data-controller='tooltip']"
    end

    test "merges custom class from html_options" do
      render_inline(Shared::IconComponent.new(
        name: "check",
        html_options: { class: "custom-class" }
      ))

      assert_selector "i.bi.bi-check.custom-class"
    end

    test "handles hyphenated icon names" do
      render_inline(Shared::IconComponent.new(name: "arrow-up-circle-fill"))

      assert_selector "i.bi.bi-arrow-up-circle-fill"
    end

    test "handles numeric icon names" do
      render_inline(Shared::IconComponent.new(name: "1-circle"))

      assert_selector "i.bi.bi-1-circle"
    end

    test "css_classes method returns correct string" do
      component = Shared::IconComponent.new(
        name: "check",
        size: "lg",
        color: "success"
      )

      assert_equal "bi bi-check fs-4 text-success", component.css_classes
    end

    test "css_classes method with spin" do
      component = Shared::IconComponent.new(
        name: "arrow-clockwise",
        spin: true
      )

      assert_equal "bi bi-arrow-clockwise icon-spin", component.css_classes
    end
  end
end
