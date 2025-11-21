# frozen_string_literal: true

require "test_helper"

class IconComponentTest < ViewComponent::TestCase
  test "renders with required name" do
    render_inline(IconComponent.new(name: "check-circle"))

    assert_selector "i.bi.bi-check-circle"
  end

  test "renders with default size" do
    render_inline(IconComponent.new(name: "star"))

    assert_selector "i.bi.bi-star"
    refute_selector "i.icon-sm"
    refute_selector "i.icon-lg"
    refute_selector "i.icon-xl"
  end

  test "renders with small size" do
    render_inline(IconComponent.new(name: "heart", size: "sm"))

    assert_selector "i.bi.bi-heart.icon-sm"
  end

  test "renders with large size" do
    render_inline(IconComponent.new(name: "exclamation", size: "lg"))

    assert_selector "i.bi.bi-exclamation.icon-lg"
  end

  test "renders with extra large size" do
    render_inline(IconComponent.new(name: "info", size: "xl"))

    assert_selector "i.bi.bi-info.icon-xl"
  end

  test "renders with custom color" do
    render_inline(IconComponent.new(name: "star-fill", color: "#ffc107"))

    assert_selector "i.bi-star-fill[style*='color: #ffc107']"
  end

  test "renders without color by default" do
    render_inline(IconComponent.new(name: "circle"))

    assert_selector "i.bi-circle"
    page = Capybara.string(rendered_content)
    icon = page.find("i")
    assert_nil icon[:style]
  end

  test "renders with spin animation" do
    render_inline(IconComponent.new(name: "arrow-clockwise", spin: true))

    assert_selector "i.bi.bi-arrow-clockwise.icon-spin"
  end

  test "renders without spin by default" do
    render_inline(IconComponent.new(name: "check"))

    assert_selector "i.bi.bi-check"
    refute_selector "i.icon-spin"
  end

  test "renders with custom html options class" do
    render_inline(IconComponent.new(
      name: "gear",
      html_options: { class: "me-2 custom-icon" }
    ))

    assert_selector "i.bi.bi-gear.me-2.custom-icon"
  end

  test "renders with custom html options style" do
    render_inline(IconComponent.new(
      name: "house",
      html_options: { style: "font-size: 24px" }
    ))

    assert_selector "i.bi-house[style*='font-size: 24px']"
  end

  test "combines color and custom style" do
    render_inline(IconComponent.new(
      name: "star",
      color: "red",
      html_options: { style: "font-size: 20px" }
    ))

    assert_selector "i.bi-star[style*='color: red']"
    assert_selector "i.bi-star[style*='font-size: 20px']"
  end

  test "raises error for invalid size" do
    error = assert_raises(ArgumentError) do
      IconComponent.new(name: "test", size: "xxl")
    end

    assert_match(/Invalid size/, error.message)
  end

  test "renders different bootstrap icon names" do
    %w[check-circle x-circle info-circle exclamation-triangle star-fill heart].each do |icon_name|
      render_inline(IconComponent.new(name: icon_name))
      assert_selector "i.bi-#{icon_name}"
    end
  end

  test "combines all features" do
    render_inline(IconComponent.new(
      name: "trophy-fill",
      size: "lg",
      color: "#ffc107",
      spin: true,
      html_options: { class: "me-3" }
    ))

    assert_selector "i.bi.bi-trophy-fill.icon-lg.icon-spin.me-3"
    assert_selector "i[style*='color: #ffc107']"
  end
end
