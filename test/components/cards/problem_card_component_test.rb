# frozen_string_literal: true

require "test_helper"

class Cards::ProblemCardComponentTest < ViewComponent::TestCase
  test "renders icon with correct Bootstrap icon class" do
    render_inline(Cards::ProblemCardComponent.new(
      icon: "exclamation-triangle-fill",
      icon_color: "warning",
      title: "Test Problem",
      description: "Test description"
    ))

    assert_selector "i.bi.bi-exclamation-triangle-fill"
  end

  test "renders icon with correct color class" do
    render_inline(Cards::ProblemCardComponent.new(
      icon: "exclamation-triangle-fill",
      icon_color: "warning",
      title: "Test Problem",
      description: "Test description"
    ))

    assert_selector "i.text-warning"
  end

  test "renders icon with fs-1 and mb-3 classes" do
    render_inline(Cards::ProblemCardComponent.new(
      icon: "exclamation-triangle-fill",
      icon_color: "warning",
      title: "Test Problem",
      description: "Test description"
    ))

    assert_selector "i.fs-1.mb-3"
  end

  test "renders title" do
    render_inline(Cards::ProblemCardComponent.new(
      icon: "exclamation-triangle-fill",
      icon_color: "warning",
      title: "Manual Errors",
      description: "Test description"
    ))

    assert_selector "h5", text: "Manual Errors"
  end

  test "renders description" do
    render_inline(Cards::ProblemCardComponent.new(
      icon: "exclamation-triangle-fill",
      icon_color: "warning",
      title: "Test Problem",
      description: "Prone to calculation mistakes"
    ))

    assert_selector "p.text-muted", text: "Prone to calculation mistakes"
  end

  test "renders card with correct classes" do
    render_inline(Cards::ProblemCardComponent.new(
      icon: "exclamation-triangle-fill",
      icon_color: "warning",
      title: "Test Problem",
      description: "Test description"
    ))

    assert_selector ".card.h-100.border-0.shadow-sm"
  end

  test "card body has text-center class" do
    render_inline(Cards::ProblemCardComponent.new(
      icon: "exclamation-triangle-fill",
      icon_color: "warning",
      title: "Test Problem",
      description: "Test description"
    ))

    assert_selector ".card-body.text-center"
  end

  test "renders with responsive column wrapper" do
    render_inline(Cards::ProblemCardComponent.new(
      icon: "exclamation-triangle-fill",
      icon_color: "warning",
      title: "Test Problem",
      description: "Test description"
    ))

    assert_selector ".col-md-6"
  end

  test "applies custom html_options class" do
    render_inline(Cards::ProblemCardComponent.new(
      icon: "exclamation-triangle-fill",
      icon_color: "warning",
      title: "Test Problem",
      description: "Test description",
      html_options: { class: "custom-class" }
    ))

    assert_selector ".card.custom-class"
  end

  test "renders with danger icon color" do
    render_inline(Cards::ProblemCardComponent.new(
      icon: "graph-down",
      icon_color: "danger",
      title: "Test Problem",
      description: "Test description"
    ))

    assert_selector "i.text-danger"
  end

  test "renders with info icon color" do
    render_inline(Cards::ProblemCardComponent.new(
      icon: "clock-fill",
      icon_color: "info",
      title: "Test Problem",
      description: "Test description"
    ))

    assert_selector "i.text-info"
  end

  test "handles different icon names" do
    render_inline(Cards::ProblemCardComponent.new(
      icon: "lightning-charge-fill",
      icon_color: "warning",
      title: "Test Problem",
      description: "Test description"
    ))

    assert_selector "i.bi.bi-lightning-charge-fill"
  end

  test "renders full card structure" do
    render_inline(Cards::ProblemCardComponent.new(
      icon: "exclamation-triangle-fill",
      icon_color: "warning",
      title: "Test Problem",
      description: "Test description"
    ))

    assert_selector ".col-md-6 > .card > .card-body"
  end
end
