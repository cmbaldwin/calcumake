# frozen_string_literal: true

require "test_helper"

class CardComponentTest < ViewComponent::TestCase
  test "renders with default body content" do
    render_inline(CardComponent.new) do
      "Card content"
    end

    assert_selector "div.card div.card-body", text: "Card content"
  end

  test "applies default variant" do
    render_inline(CardComponent.new) do
      "Content"
    end

    assert_selector "div.card"
    refute_selector "div.border-primary"
  end

  test "renders with primary variant" do
    render_inline(CardComponent.new(variant: "primary")) do
      "Content"
    end

    assert_selector "div.card.border-primary"
  end

  test "renders with success variant" do
    render_inline(CardComponent.new(variant: "success")) do
      "Content"
    end

    assert_selector "div.card.border-success"
  end

  test "renders with danger variant" do
    render_inline(CardComponent.new(variant: "danger")) do
      "Content"
    end

    assert_selector "div.card.border-danger"
  end

  test "renders with transparent variant" do
    render_inline(CardComponent.new(variant: "transparent")) do
      "Content"
    end

    assert_selector "div.card.bg-transparent"
  end

  test "applies shadow by default" do
    render_inline(CardComponent.new) do
      "Content"
    end

    assert_selector "div.card.shadow"
  end

  test "renders without shadow when disabled" do
    render_inline(CardComponent.new(shadow: false)) do
      "Content"
    end

    assert_selector "div.card"
    refute_selector "div.shadow"
  end

  test "applies border by default" do
    render_inline(CardComponent.new) do
      "Content"
    end

    assert_selector "div.card"
    refute_selector "div.border-0"
  end

  test "renders without border when disabled" do
    render_inline(CardComponent.new(border: false)) do
      "Content"
    end

    assert_selector "div.card.border-0"
  end

  test "renders with custom header slot" do
    render_inline(CardComponent.new) do |component|
      component.with_header do
        "<h5>Custom Header</h5>".html_safe
      end
      "Body content"
    end

    assert_selector "div.card-header h5", text: "Custom Header"
    assert_selector "div.card-body", text: "Body content"
  end

  test "renders with custom body slot" do
    render_inline(CardComponent.new) do |component|
      component.with_body do
        "<p>Custom body</p>".html_safe
      end
    end

    assert_selector "div.card-body p", text: "Custom body"
  end

  test "renders with custom footer slot" do
    render_inline(CardComponent.new) do |component|
      component.with_footer do
        "<button>Action</button>".html_safe
      end
      "Body"
    end

    assert_selector "div.card-footer button", text: "Action"
  end

  test "applies custom header class" do
    render_inline(CardComponent.new(header_class: "bg-primary text-white")) do |component|
      component.with_header { "Header" }
      "Body"
    end

    assert_selector "div.card-header.bg-primary.text-white"
  end

  test "applies custom body class" do
    render_inline(CardComponent.new(body_class: "p-4 text-center")) do
      "Body"
    end

    assert_selector "div.card-body.p-4.text-center"
  end

  test "applies custom footer class" do
    render_inline(CardComponent.new(footer_class: "bg-light")) do |component|
      component.with_footer { "Footer" }
      "Body"
    end

    assert_selector "div.card-footer.bg-light"
  end

  test "renders without header when not provided" do
    render_inline(CardComponent.new) do
      "Content"
    end

    refute_selector "div.card-header"
  end

  test "renders without footer when not provided" do
    render_inline(CardComponent.new) do
      "Content"
    end

    refute_selector "div.card-footer"
  end

  test "renders with custom html options" do
    render_inline(CardComponent.new(html_options: { class: "mb-4 custom-card" })) do
      "Content"
    end

    assert_selector "div.card.mb-4.custom-card"
  end

  test "raises error for invalid variant" do
    error = assert_raises(ArgumentError) do
      CardComponent.new(variant: "invalid")
    end

    assert_match(/Invalid variant/, error.message)
  end

  test "combines all features" do
    render_inline(CardComponent.new(
      variant: "primary",
      shadow: true,
      border: true,
      header_class: "bg-primary text-white",
      body_class: "p-4",
      footer_class: "text-end"
    )) do |component|
      component.with_header { "Card Header" }
      component.with_body { "Card Body" }
      component.with_footer { "Card Footer" }
    end

    assert_selector "div.card.border-primary.shadow"
    assert_selector "div.card-header.bg-primary.text-white", text: "Card Header"
    assert_selector "div.card-body.p-4", text: "Card Body"
    assert_selector "div.card-footer.text-end", text: "Card Footer"
  end

  test "renders with all slots" do
    render_inline(CardComponent.new) do |component|
      component.with_header { "Header" }
      component.with_body { "Body" }
      component.with_footer { "Footer" }
    end

    assert_selector "div.card-header", text: "Header"
    assert_selector "div.card-body", text: "Body"
    assert_selector "div.card-footer", text: "Footer"
  end
end
