# frozen_string_literal: true

require "test_helper"

class Cards::FeatureCardComponentTest < ViewComponent::TestCase
  test "renders icon with correct Bootstrap icon class" do
    render_inline(Cards::FeatureCardComponent.new(
      icon: "calculator",
      title: "Test Feature",
      description: "Test description"
    ))

    assert_selector "i.bi.bi-calculator-fill.fs-1"
  end

  test "renders title" do
    render_inline(Cards::FeatureCardComponent.new(
      icon: "calculator",
      title: "Accurate Calculation",
      description: "Test description"
    ))

    assert_selector "h4.text-primary", text: "Accurate Calculation"
  end

  test "renders description" do
    render_inline(Cards::FeatureCardComponent.new(
      icon: "calculator",
      title: "Test Feature",
      description: "Calculate costs accurately"
    ))

    assert_selector "p.text-muted", text: "Calculate costs accurately"
  end

  test "renders features list when features provided" do
    features = ["Feature 1", "Feature 2", "Feature 3"]

    render_inline(Cards::FeatureCardComponent.new(
      icon: "calculator",
      title: "Test Feature",
      description: "Test description",
      features: features
    ))

    assert_selector "ul.list-unstyled"
    assert_selector "li", count: 3
    assert_selector "li", text: "Feature 1"
    assert_selector "li", text: "Feature 2"
    assert_selector "li", text: "Feature 3"
  end

  test "each feature has check circle icon" do
    features = ["Feature 1", "Feature 2"]

    render_inline(Cards::FeatureCardComponent.new(
      icon: "calculator",
      title: "Test Feature",
      description: "Test description",
      features: features
    ))

    assert_selector "li i.bi.bi-check-circle.text-success.me-2", count: 2
  end

  test "does not render features list when no features provided" do
    render_inline(Cards::FeatureCardComponent.new(
      icon: "calculator",
      title: "Test Feature",
      description: "Test description"
    ))

    refute_selector "ul.list-unstyled"
  end

  test "does not render features list when empty array" do
    render_inline(Cards::FeatureCardComponent.new(
      icon: "calculator",
      title: "Test Feature",
      description: "Test description",
      features: []
    ))

    refute_selector "ul.list-unstyled"
  end

  test "renders card with shadow and border classes" do
    render_inline(Cards::FeatureCardComponent.new(
      icon: "calculator",
      title: "Test Feature",
      description: "Test description"
    ))

    assert_selector ".card.border-0.shadow-sm.h-100"
  end

  test "renders with responsive column wrapper" do
    render_inline(Cards::FeatureCardComponent.new(
      icon: "calculator",
      title: "Test Feature",
      description: "Test description"
    ))

    assert_selector ".col-lg-6"
  end

  test "renders with feature-card wrapper" do
    render_inline(Cards::FeatureCardComponent.new(
      icon: "calculator",
      title: "Test Feature",
      description: "Test description"
    ))

    assert_selector ".feature-card.h-100"
  end

  test "applies custom html_options class" do
    render_inline(Cards::FeatureCardComponent.new(
      icon: "calculator",
      title: "Test Feature",
      description: "Test description",
      html_options: { class: "custom-class" }
    ))

    assert_selector ".card.custom-class"
  end

  test "icon class handles different icon names" do
    render_inline(Cards::FeatureCardComponent.new(
      icon: "printer",
      title: "Test Feature",
      description: "Test description"
    ))

    assert_selector "i.bi.bi-printer-fill"
  end

  test "renders card body with padding" do
    render_inline(Cards::FeatureCardComponent.new(
      icon: "calculator",
      title: "Test Feature",
      description: "Test description"
    ))

    assert_selector ".card-body.p-4"
  end

  test "icon has text-primary and mb-3 classes" do
    render_inline(Cards::FeatureCardComponent.new(
      icon: "calculator",
      title: "Test Feature",
      description: "Test description"
    ))

    assert_selector ".feature-icon.text-primary.mb-3"
  end

  test "description has mb-3 class" do
    render_inline(Cards::FeatureCardComponent.new(
      icon: "calculator",
      title: "Test Feature",
      description: "Test description"
    ))

    assert_selector "p.text-muted.mb-3"
  end
end

