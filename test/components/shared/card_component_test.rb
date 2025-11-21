# frozen_string_literal: true

require "test_helper"

module Shared
  class CardComponentTest < ViewComponent::TestCase
    test "renders basic card with body slot" do
      render_inline(Shared::CardComponent.new) do |c|
        c.with_body { "Card content" }
      end

      assert_selector "div.card" do
        assert_selector "div.card-body", text: "Card content"
      end
    end

    test "renders card with header" do
      render_inline(Shared::CardComponent.new) do |c|
        c.with_header { "Card Title" }
        c.with_body { "Card content" }
      end

      assert_selector "div.card" do
        assert_selector "div.card-header", text: "Card Title"
        assert_selector "div.card-body", text: "Card content"
      end
    end

    test "renders card with footer" do
      render_inline(Shared::CardComponent.new) do |c|
        c.with_body { "Card content" }
        c.with_footer { "Footer actions" }
      end

      assert_selector "div.card" do
        assert_selector "div.card-body", text: "Card content"
        assert_selector "div.card-footer", text: "Footer actions"
      end
    end

    test "renders card with all slots" do
      render_inline(Shared::CardComponent.new) do |c|
        c.with_header { "Header" }
        c.with_body { "Body" }
        c.with_footer { "Footer" }
      end

      assert_selector "div.card" do
        assert_selector "div.card-header", text: "Header"
        assert_selector "div.card-body", text: "Body"
        assert_selector "div.card-footer", text: "Footer"
      end
    end

    test "renders card with primary variant" do
      render_inline(Shared::CardComponent.new(variant: "primary")) do |c|
        c.with_body { "Content" }
      end

      assert_selector "div.card.bg-primary.text-white" do
        assert_selector "div.card-body"
      end
    end

    test "renders card with success variant" do
      render_inline(Shared::CardComponent.new(variant: "success")) do |c|
        c.with_body { "Content" }
      end

      assert_selector "div.card.bg-success.text-white"
    end

    test "renders card with danger variant" do
      render_inline(Shared::CardComponent.new(variant: "danger")) do |c|
        c.with_body { "Content" }
      end

      assert_selector "div.card.bg-danger.text-white"
    end

    test "renders card with warning variant without white text" do
      render_inline(Shared::CardComponent.new(variant: "warning")) do |c|
        c.with_body { "Content" }
      end

      assert_selector "div.card.bg-warning"
      assert_no_selector "div.card.text-white"
    end

    test "renders card with small shadow" do
      render_inline(Shared::CardComponent.new(shadow: true)) do |c|
        c.with_body { "Content" }
      end

      assert_selector "div.card.shadow-sm"
    end

    test "renders card with large shadow" do
      render_inline(Shared::CardComponent.new(shadow: "lg")) do |c|
        c.with_body { "Content" }
      end

      assert_selector "div.card.shadow-lg"
    end

    test "renders card without shadow by default" do
      render_inline(Shared::CardComponent.new) do |c|
        c.with_body { "Content" }
      end

      assert_selector "div.card"
      assert_no_selector "div.shadow-sm"
      assert_no_selector "div.shadow-lg"
    end

    test "renders card without border" do
      render_inline(Shared::CardComponent.new(border: false)) do |c|
        c.with_body { "Content" }
      end

      assert_selector "div.card.border-0"
    end

    test "renders card with border by default" do
      render_inline(Shared::CardComponent.new) do |c|
        c.with_body { "Content" }
      end

      assert_selector "div.card"
      assert_no_selector "div.border-0"
    end

    test "variant applies to both card and header" do
      render_inline(Shared::CardComponent.new(variant: "primary")) do |c|
        c.with_header { "Header" }
        c.with_body { "Body" }
      end

      assert_selector "div.card.bg-primary.text-white"
      assert_selector "div.card-header.bg-primary.text-white"
    end

    test "accepts additional html_options" do
      render_inline(Shared::CardComponent.new(
        html_options: { id: "custom-card", data: { controller: "example" } }
      )) do |c|
        c.with_body { "Content" }
      end

      assert_selector "div.card#custom-card[data-controller='example']"
    end

    test "merges custom class from html_options" do
      render_inline(Shared::CardComponent.new(
        html_options: { class: "my-custom-card" }
      )) do |c|
        c.with_body { "Content" }
      end

      assert_selector "div.card.my-custom-card"
    end

    test "combines multiple options" do
      render_inline(Shared::CardComponent.new(
        variant: "success",
        shadow: "lg",
        border: false,
        html_options: { class: "mb-4" }
      )) do |c|
        c.with_header { "Success Card" }
        c.with_body { "Centered content" }
        c.with_footer { "Footer" }
      end

      assert_selector "div.card.bg-success.text-white.shadow-lg.border-0.mb-4" do
        assert_selector "div.card-header.bg-success.text-white"
        assert_selector "div.card-body"
        assert_selector "div.card-footer"
      end
    end

    test "renders empty card without slots" do
      render_inline(Shared::CardComponent.new)

      assert_selector "div.card"
      assert_no_selector "div.card-header"
      assert_no_selector "div.card-body"
      assert_no_selector "div.card-footer"
    end

    test "renders card with only header" do
      render_inline(Shared::CardComponent.new) do |c|
        c.with_header { "Header Only" }
      end

      assert_selector "div.card" do
        assert_selector "div.card-header", text: "Header Only"
      end
      assert_no_selector "div.card-body"
      assert_no_selector "div.card-footer"
    end

    test "renders card with html content in slots" do
      render_inline(Shared::CardComponent.new) do |c|
        c.with_body { "<strong>Bold</strong> text".html_safe }
      end

      assert_selector "div.card-body" do
        assert_selector "strong", text: "Bold"
        assert_text "text"
      end
    end
  end
end
