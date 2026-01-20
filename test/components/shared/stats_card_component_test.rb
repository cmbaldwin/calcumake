# frozen_string_literal: true

require "test_helper"

module Shared
  class StatsCardComponentTest < ViewComponent::TestCase
    test "renders with required attributes" do
      render_inline(Shared::StatsCardComponent.new(value: "42", label: "Total Items"))

      assert_selector "h2.display-6", text: "42"
      assert_selector "p.mb-0", text: "Total Items"
    end

    test "applies default color class" do
      render_inline(Shared::StatsCardComponent.new(value: "100", label: "Count"))

      assert_selector "div.bg-primary"
    end

    test "applies custom color class" do
      render_inline(Shared::StatsCardComponent.new(value: "50", label: "Active", color: "success"))

      assert_selector "div.bg-success"
    end

    test "uses default column class" do
      render_inline(Shared::StatsCardComponent.new(value: "10", label: "Total"))

      assert_selector "div.col-6.col-lg"
    end

    test "applies custom column class" do
      render_inline(Shared::StatsCardComponent.new(value: "20", label: "Items", col_class: "col-12"))

      assert_selector "div.col-12"
    end

    test "renders with HTML value" do
      render_inline(Shared::StatsCardComponent.new(value: "100h", label: "Time"))

      assert_selector "h2", text: "100h"
    end

    test "shows positive trend in green with up arrow" do
      render_inline(Shared::StatsCardComponent.new(
        value: "$1,500",
        label: "Revenue",
        trend: 25.5
      ))

      assert_selector ".text-success", text: /↑/
      assert_selector "small", text: /25.5%/
    end

    test "shows negative trend in red with down arrow" do
      render_inline(Shared::StatsCardComponent.new(
        value: "$800",
        label: "Revenue",
        trend: -15.2
      ))

      assert_selector ".text-danger", text: /↓/
      assert_selector "small", text: /15.2%/
    end

    test "shows zero trend in muted with right arrow" do
      render_inline(Shared::StatsCardComponent.new(
        value: "$1,000",
        label: "Revenue",
        trend: 0
      ))

      assert_selector ".text-muted", text: /→/
      assert_selector "small", text: /0.0%/
    end

    test "does not show trend when nil" do
      render_inline(Shared::StatsCardComponent.new(
        value: "$1,000",
        label: "Revenue",
        trend: nil
      ))

      assert_no_selector "small"
    end

    test "displays trend comparison text" do
      render_inline(Shared::StatsCardComponent.new(
        value: "$1,200",
        label: "Revenue",
        trend: 10.5
      ))

      assert_selector "small .text-white-50", text: I18n.t("analytics.trends.vs_previous")
    end
  end
end
