# frozen_string_literal: true

require "test_helper"

class UsageStatsComponentTest < ViewComponent::TestCase
  def setup
    @usage = {
      print_pricings: { current: 5, limit: 10, percentage: 50 },
      printers: { current: 2, limit: 5, percentage: 40 },
      filaments: { current: 8, limit: 10, percentage: 80 },
      invoices: { current: 3, limit: 10, percentage: 30 }
    }
  end

  test "renders with usage hash" do
    render_inline(UsageStatsComponent.new(usage: @usage))

    assert_selector "div.card"
    assert_selector "div.card-header"
    assert_selector "div.card-body"
  end

  test "displays usage summary title" do
    render_inline(UsageStatsComponent.new(usage: @usage))

    assert_selector "h3.h6", text: I18n.t("usage_limits.usage_summary")
  end

  test "renders all four resource usage items" do
    render_inline(UsageStatsComponent.new(usage: @usage))

    assert_selector "div.usage-stat", count: 4
  end

  test "shows approaching limits warning when threshold exceeded" do
    render_inline(UsageStatsComponent.new(usage: @usage))

    # filaments is at 80%, should trigger warning
    assert_selector "div.alert.alert-warning"
  end

  test "does not show warning when no resources approach limits" do
    safe_usage = {
      print_pricings: { current: 3, limit: 10, percentage: 30 },
      printers: { current: 1, limit: 5, percentage: 20 },
      filaments: { current: 5, limit: 10, percentage: 50 },
      invoices: { current: 2, limit: 10, percentage: 20 }
    }

    render_inline(UsageStatsComponent.new(usage: safe_usage))

    refute_selector "div.alert.alert-warning"
  end

  test "does not show warning for unlimited resources at high usage" do
    unlimited_usage = {
      print_pricings: { current: 1000, limit: Float::INFINITY, percentage: 0 },
      printers: { current: 100, limit: Float::INFINITY, percentage: 0 },
      filaments: { current: 500, limit: Float::INFINITY, percentage: 0 },
      invoices: { current: 200, limit: Float::INFINITY, percentage: 0 }
    }

    render_inline(UsageStatsComponent.new(usage: unlimited_usage))

    refute_selector "div.alert.alert-warning"
  end

  test "has_approaching_limits? returns true when limits approached" do
    component = UsageStatsComponent.new(usage: @usage)

    assert component.has_approaching_limits?
  end

  test "has_approaching_limits? returns false when limits not approached" do
    safe_usage = {
      print_pricings: { current: 3, limit: 10, percentage: 30 },
      printers: { current: 1, limit: 5, percentage: 20 },
      filaments: { current: 5, limit: 10, percentage: 50 },
      invoices: { current: 2, limit: 10, percentage: 20 }
    }

    component = UsageStatsComponent.new(usage: safe_usage)

    refute component.has_approaching_limits?
  end

  test "resources method returns array of resource hashes" do
    component = UsageStatsComponent.new(usage: @usage)
    resources = component.resources

    assert_kind_of Array, resources
    assert_equal 4, resources.length

    resources.each do |resource|
      assert resource.key?(:key)
      assert resource.key?(:data)
      assert_kind_of Hash, resource[:data]
      assert resource[:data].key?(:current)
      assert resource[:data].key?(:limit)
    end
  end

  test "handles string keys in usage hash" do
    string_key_usage = {
      "print_pricings" => { current: 5, limit: 10, percentage: 50 },
      "printers" => { current: 2, limit: 5, percentage: 40 },
      "filaments" => { current: 8, limit: 10, percentage: 80 },
      "invoices" => { current: 3, limit: 10, percentage: 30 }
    }

    render_inline(UsageStatsComponent.new(usage: string_key_usage))

    assert_selector "div.usage-stat", count: 4
  end

  test "displays icon in header" do
    render_inline(UsageStatsComponent.new(usage: @usage))

    assert_selector "i.bi-bar-chart"
  end

  test "warning message includes icon" do
    render_inline(UsageStatsComponent.new(usage: @usage))

    # Alert should be present with warning variant when approaching limits (filaments at 80%)
    assert_selector "div.alert.alert-warning"
    # Icon should be in the alert (either from default or in content)
    assert_selector "div.alert i.bi"
  end

  test "approaching_limits excludes unlimited resources" do
    mixed_usage = {
      print_pricings: { current: 9, limit: 10, percentage: 90 },
      printers: { current: 100, limit: Float::INFINITY, percentage: 0 },
      filaments: { current: 5, limit: 10, percentage: 50 },
      invoices: { current: 9, limit: 10, percentage: 90 }
    }

    component = UsageStatsComponent.new(usage: mixed_usage)
    approaching = component.approaching_limits

    # Should only include print_pricings and invoices (both at 90%)
    # printers is unlimited, filaments is at 50%
    assert_equal 2, approaching.length
  end
end
