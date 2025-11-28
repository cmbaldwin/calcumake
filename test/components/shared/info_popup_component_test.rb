# frozen_string_literal: true

require "test_helper"

module Shared
  class InfoPopupComponentTest < ViewComponent::TestCase
    test "renders info icon with default settings" do
      render_inline(Shared::InfoPopupComponent.new(
        translation_key: "info_popups.test.example"
      ))

      assert_selector "span.info-popup-icon.d-inline-block.ms-1" do
        assert_selector "i.bi.bi-info-circle.text-muted.fs-6"
      end
    end

    test "renders with data-controller attribute" do
      render_inline(Shared::InfoPopupComponent.new(
        translation_key: "info_popups.test.example"
      ))

      assert_selector "span[data-controller='info-popup']"
    end

    test "includes tooltip attributes" do
      render_inline(Shared::InfoPopupComponent.new(
        translation_key: "info_popups.test.example"
      ))

      assert_selector "span[data-bs-toggle='tooltip']"
      assert_selector "span[data-bs-placement='top']"
    end

    test "includes translation content in tooltip" do
      I18n.backend.store_translations :en, info_popups: { test: { example: "This is a test tooltip" } }

      render_inline(Shared::InfoPopupComponent.new(
        translation_key: "info_popups.test.example"
      ))

      assert_selector "span[data-bs-title='This is a test tooltip']"
    end

    test "renders with custom position" do
      render_inline(Shared::InfoPopupComponent.new(
        translation_key: "info_popups.test.example",
        position: "left"
      ))

      assert_selector "span[data-bs-placement='left']"
      assert_selector "span[data-info-popup-position-value='left']"
    end

    test "renders with bottom position" do
      render_inline(Shared::InfoPopupComponent.new(
        translation_key: "info_popups.test.example",
        position: "bottom"
      ))

      assert_selector "span[data-bs-placement='bottom']"
    end

    test "renders with right position" do
      render_inline(Shared::InfoPopupComponent.new(
        translation_key: "info_popups.test.example",
        position: "right"
      ))

      assert_selector "span[data-bs-placement='right']"
    end

    test "renders with small icon size (default)" do
      render_inline(Shared::InfoPopupComponent.new(
        translation_key: "info_popups.test.example",
        icon_size: "sm"
      ))

      assert_selector "i.fs-6"
    end

    test "renders with medium icon size" do
      render_inline(Shared::InfoPopupComponent.new(
        translation_key: "info_popups.test.example",
        icon_size: "md"
      ))

      assert_selector "i.fs-5"
    end

    test "renders with large icon size" do
      render_inline(Shared::InfoPopupComponent.new(
        translation_key: "info_popups.test.example",
        icon_size: "lg"
      ))

      assert_selector "i.fs-4"
    end

    test "includes role and tabindex for accessibility" do
      render_inline(Shared::InfoPopupComponent.new(
        translation_key: "info_popups.test.example"
      ))

      assert_selector "span[role='button']"
      assert_selector "span[tabindex='0']"
    end

    test "accepts additional html_options" do
      render_inline(Shared::InfoPopupComponent.new(
        translation_key: "info_popups.test.example",
        html_options: { id: "custom-info", data: { test: "value" } }
      ))

      assert_selector "span#custom-info[data-test='value']"
    end

    test "merges custom class from html_options" do
      render_inline(Shared::InfoPopupComponent.new(
        translation_key: "info_popups.test.example",
        html_options: { class: "my-custom-class" }
      ))

      assert_selector "span.info-popup-icon.d-inline-block.ms-1.my-custom-class"
    end

    test "handles missing translation gracefully" do
      render_inline(Shared::InfoPopupComponent.new(
        translation_key: "info_popups.nonexistent.key"
      ))

      # Should still render the component even if translation is missing
      assert_selector "span.info-popup-icon"
    end

    test "includes Stimulus value attributes" do
      I18n.backend.store_translations :en, info_popups: { test: { content: "Test content" } }

      render_inline(Shared::InfoPopupComponent.new(
        translation_key: "info_popups.test.content"
      ))

      assert_selector "span[data-info-popup-content-value='Test content']"
    end

    test "combines multiple custom options" do
      I18n.backend.store_translations :en, info_popups: { test: { custom: "Custom tooltip text" } }

      render_inline(Shared::InfoPopupComponent.new(
        translation_key: "info_popups.test.custom",
        position: "bottom",
        icon_size: "lg",
        html_options: { class: "custom-class", id: "custom-popup" }
      ))

      assert_selector "span#custom-popup.info-popup-icon.custom-class[data-bs-placement='bottom']" do
        assert_selector "i.bi.bi-info-circle.fs-4"
      end
    end
  end
end
