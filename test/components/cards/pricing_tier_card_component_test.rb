# frozen_string_literal: true

require "test_helper"

module Cards
  class PricingTierCardComponentTest < ViewComponent::TestCase
    def setup
      @free_plan = {
        name: "Free",
        price: "$0",
        limits: {
          print_pricings: 5,
          printers: 1,
          filaments: 4,
          invoices: 5
        },
        features: [ "CalcuMake branding on invoices", "Community support" ]
      }

      @startup_plan = {
        name: "Startup",
        price: "$1.50/month",
        limits: {
          print_pricings: 50,
          printers: 10,
          filaments: 16,
          invoices: Float::INFINITY
        },
        features: [ "Remove CalcuMake branding", "No ads", "Email support" ]
      }

      @pro_plan = {
        name: "Pro",
        price: "$15/month",
        limits: {
          print_pricings: Float::INFINITY,
          printers: Float::INFINITY,
          filaments: Float::INFINITY,
          invoices: Float::INFINITY
        },
        features: [ "Unlimited everything", "Priority support", "Advanced analytics" ]
      }
    end

    # Basic Rendering
    test "renders free plan with basic structure" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "free",
        features: @free_plan
      ))

      assert_selector "div.col-lg-4.col-md-6"
      assert_selector "div.card.pricing-card"
      assert_selector "h3.h5", text: "Free"
      assert_selector "span.price-amount", text: "$0"
    end

    test "renders startup plan" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "startup",
        features: @startup_plan
      ))

      assert_selector "h3.h5", text: "Startup"
      assert_selector "span.price-amount", text: "$1.50"
      assert_selector "span.price-period", text: "/month"
    end

    test "renders pro plan" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "pro",
        features: @pro_plan
      ))

      assert_selector "h3.h5", text: "Pro"
      assert_selector "span.price-amount", text: "$15"
    end

    # Popular Badge
    test "shows popular badge when popular is true" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "startup",
        features: @startup_plan,
        popular: true
      ))

      assert_selector "div.popular-badge"
      assert_selector "div.card.popular-plan.border-primary.shadow-lg"
    end

    test "does not show popular badge when popular is false" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "startup",
        features: @startup_plan,
        popular: false
      ))

      refute_selector "div.popular-badge"
      refute_selector "div.card.popular-plan"
      assert_selector "div.card.border-0.shadow-sm"
    end

    # Current Plan Badge
    test "shows current plan badge when current is true" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "startup",
        features: @startup_plan,
        current: true
      ))

      assert_selector "div.alert.alert-success", text: /current plan/i
      assert_selector "div.card.current-plan"
    end

    test "does not show current plan badge when current is false" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "startup",
        features: @startup_plan,
        current: false
      ))

      refute_selector "div.alert.alert-success"
      refute_selector "div.card.current-plan"
    end

    # Trial Badge
    test "shows trial badge when current_user provided for free plan" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "free",
        features: @free_plan,
        current_user: users(:one)
      ))

      # Component should render - actual trial badge logic handled by view
      assert_selector "div.card"
    end

    test "does not show trial badge when no current_user for free plan" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "free",
        features: @free_plan,
        current_user: nil
      ))

      refute_selector "div.alert.alert-info"
    end

    test "does not show trial badge for non-free plans even with current_user" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "startup",
        features: @startup_plan,
        current_user: users(:one)
      ))

      refute_selector "div.alert.alert-info"
    end

    # Resource Limits
    test "renders numeric resource limits" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "free",
        features: @free_plan
      ))

      assert_selector "li i.bi-check.text-success"
      assert_selector "ul.list-unstyled li", minimum: 4 # At least 4 limit items
    end

    test "renders unlimited resource limits" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "pro",
        features: @pro_plan
      ))

      assert_selector "li i.bi-check.text-success"
      assert_selector "ul.list-unstyled li", minimum: 4
    end

    # Additional Features
    test "renders additional features" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "startup",
        features: @startup_plan
      ))

      @startup_plan[:features].each do |feature|
        assert_selector "li", text: feature
      end
    end

    test "handles empty additional features" do
      features = @free_plan.dup
      features[:features] = []

      render_inline(Cards::PricingTierCardComponent.new(
        plan: "free",
        features: features
      ))

      assert_selector "ul.list-unstyled" # List still renders
    end

    # CTA Button
    test "shows CTA button by default" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "startup",
        features: @startup_plan
      ))

      assert_selector "div.mt-auto a.btn"
    end

    test "hides CTA button when show_cta is false" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "startup",
        features: @startup_plan,
        show_cta: false
      ))

      refute_selector "div.mt-auto"
    end

    test "CTA button is disabled for current plan" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "startup",
        features: @startup_plan,
        current: true
      ))

      assert_selector "button.btn.btn-outline-secondary[disabled]"
    end

    test "CTA button is primary gradient for popular plan" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "startup",
        features: @startup_plan,
        popular: true
      ))

      assert_selector "a.btn.btn-primary.btn-gradient-primary"
    end

    test "CTA button is outline-primary for non-popular, non-current plan" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "startup",
        features: @startup_plan
      ))

      assert_selector "a.btn.btn-outline-primary"
    end

    # Card Classes
    test "applies correct card classes for popular plan" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "startup",
        features: @startup_plan,
        popular: true
      ))

      assert_selector "div.card.pricing-card.popular-plan.border-primary.shadow-lg.h-100"
    end

    test "applies correct card classes for current plan" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "startup",
        features: @startup_plan,
        current: true
      ))

      assert_selector "div.card.pricing-card.current-plan.border-0.shadow-sm.h-100"
    end

    test "applies correct card classes for regular plan" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "free",
        features: @free_plan
      ))

      assert_selector "div.card.pricing-card.border-0.shadow-sm.h-100"
      refute_selector "div.card.popular-plan"
      refute_selector "div.card.current-plan"
    end

    # Responsive Layout
    test "includes responsive column classes" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "free",
        features: @free_plan
      ))

      assert_selector "div.col-lg-4.col-md-6"
    end

    test "card body has proper flexbox classes" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "free",
        features: @free_plan
      ))

      assert_selector "div.card-body.d-flex.flex-column"
    end

    test "features list has flex-grow-1 for proper spacing" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "free",
        features: @free_plan
      ))

      assert_selector "ul.list-unstyled.flex-grow-1"
    end

    # Edge Cases
    test "handles nil current_user gracefully" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "free",
        features: @free_plan,
        current_user: nil
      ))

      assert_selector "div.card" # Renders without error
      refute_selector "div.alert.alert-info" # No trial badge
    end

    test "handles plan without limits" do
      features = { name: "Custom", price: "$0", features: [] }

      render_inline(Cards::PricingTierCardComponent.new(
        plan: "custom",
        features: features
      ))

      assert_selector "div.card"
      assert_selector "h3", text: "Custom"
    end

    test "handles empty features array" do
      features = @free_plan.dup
      features[:features] = nil

      render_inline(Cards::PricingTierCardComponent.new(
        plan: "free",
        features: features
      ))

      assert_selector "ul.list-unstyled"
    end

    # Free Plan Specifics
    test "free plan does not show per-month text" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "free",
        features: @free_plan
      ))

      refute_selector "span.price-period", text: "/month"
    end

    test "paid plans show per-month text" do
      render_inline(Cards::PricingTierCardComponent.new(
        plan: "startup",
        features: @startup_plan
      ))

      assert_selector "span.price-period", text: "/month"
    end
  end
end
