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
  end
end
