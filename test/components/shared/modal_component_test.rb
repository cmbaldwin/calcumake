# frozen_string_literal: true

require "test_helper"

module Shared
  class ModalComponentTest < ViewComponent::TestCase
    test "renders basic modal with title and body" do
      render_inline(Shared::ModalComponent.new(id: "test-modal", title: "Test Modal")) do |c|
        c.with_body { "Modal content" }
      end
      
      assert_selector "div.modal.fade#test-modal[role='dialog'][tabindex='-1']"
      assert_selector "h5.modal-title", text: "Test Modal"
      assert_selector "div.modal-body", text: "Modal content"
    end

    test "modal has proper ARIA attributes" do
      render_inline(Shared::ModalComponent.new(id: "aria-modal", title: "Title")) do |c|
        c.with_body { "Content" }
      end
      
      assert_selector "div.modal[aria-labelledby='aria-modalTitle'][aria-hidden='true']"
      assert_selector "h5#aria-modalTitle"
    end

    test "renders modal with footer" do
      render_inline(Shared::ModalComponent.new(id: "footer-modal", title: "Title")) do |c|
        c.with_body { "Body" }
        c.with_footer { "Footer content" }
      end
      
      assert_selector "div.modal-footer", text: "Footer content"
    end

    test "renders modal without footer when not provided" do
      render_inline(Shared::ModalComponent.new(id: "no-footer", title: "Title")) do |c|
        c.with_body { "Body" }
      end
      
      assert_no_selector "div.modal-footer"
    end

    test "renders close button in header" do
      render_inline(Shared::ModalComponent.new(id: "closable", title: "Title")) do |c|
        c.with_body { "Content" }
      end
      
      assert_selector "div.modal-header" do
        assert_selector "button.btn-close[type='button'][data-bs-dismiss='modal'][aria-label='Close']"
      end
    end

    test "renders small modal" do
      render_inline(Shared::ModalComponent.new(id: "small", title: "Title", size: "sm")) do |c|
        c.with_body { "Content" }
      end
      
      assert_selector "div.modal-dialog.modal-sm"
    end

    test "renders medium modal (default)" do
      render_inline(Shared::ModalComponent.new(id: "medium", title: "Title", size: "md")) do |c|
        c.with_body { "Content" }
      end
      
      assert_selector "div.modal-dialog"
      assert_no_selector "div.modal-sm"
      assert_no_selector "div.modal-lg"
      assert_no_selector "div.modal-xl"
    end

    test "renders large modal" do
      render_inline(Shared::ModalComponent.new(id: "large", title: "Title", size: "lg")) do |c|
        c.with_body { "Content" }
      end
      
      assert_selector "div.modal-dialog.modal-lg"
    end

    test "renders extra large modal" do
      render_inline(Shared::ModalComponent.new(id: "xlarge", title: "Title", size: "xl")) do |c|
        c.with_body { "Content" }
      end
      
      assert_selector "div.modal-dialog.modal-xl"
    end

    test "renders fullscreen modal" do
      render_inline(Shared::ModalComponent.new(id: "full", title: "Title", size: "fullscreen")) do |c|
        c.with_body { "Content" }
      end
      
      assert_selector "div.modal-dialog.modal-fullscreen"
    end

    test "renders centered modal" do
      render_inline(Shared::ModalComponent.new(id: "centered", title: "Title", centered: true)) do |c|
        c.with_body { "Content" }
      end
      
      assert_selector "div.modal-dialog.modal-dialog-centered"
    end

    test "renders scrollable modal" do
      render_inline(Shared::ModalComponent.new(id: "scrollable", title: "Title", scrollable: true)) do |c|
        c.with_body { "Content" }
      end
      
      assert_selector "div.modal-dialog.modal-dialog-scrollable"
    end

    test "renders static backdrop modal" do
      render_inline(Shared::ModalComponent.new(id: "static", title: "Title", static_backdrop: true)) do |c|
        c.with_body { "Content" }
      end
      
      assert_selector "div.modal[data-bs-backdrop='static'][data-bs-keyboard='false']"
    end

    test "combines size, centered, and scrollable" do
      render_inline(Shared::ModalComponent.new(
        id: "combined",
        title: "Title",
        size: "lg",
        centered: true,
        scrollable: true
      )) do |c|
        c.with_body { "Content" }
      end
      
      assert_selector "div.modal-dialog.modal-lg.modal-dialog-centered.modal-dialog-scrollable"
    end

    test "accepts additional html_options" do
      render_inline(Shared::ModalComponent.new(
        id: "custom",
        title: "Title",
        html_options: { data: { controller: "modal-custom" } }
      )) do |c|
        c.with_body { "Content" }
      end
      
      assert_selector "div.modal#custom[data-controller='modal-custom']"
    end

    test "merges custom class from html_options" do
      render_inline(Shared::ModalComponent.new(
        id: "custom-class",
        title: "Title",
        html_options: { class: "custom-modal" }
      )) do |c|
        c.with_body { "Content" }
      end
      
      assert_selector "div.modal.fade.custom-modal"
    end

    test "modal has proper Bootstrap structure" do
      render_inline(Shared::ModalComponent.new(id: "structure", title: "Title")) do |c|
        c.with_body { "Content" }
      end
      
      assert_selector "div.modal > div.modal-dialog > div.modal-content"
      assert_selector "div.modal-content > div.modal-header"
      assert_selector "div.modal-content > div.modal-body"
    end

    test "renders body with HTML content" do
      render_inline(Shared::ModalComponent.new(id: "html-body", title: "Title")) do |c|
        c.with_body { "<strong>Bold</strong> text".html_safe }
      end
      
      assert_selector "div.modal-body" do
        assert_selector "strong", text: "Bold"
        assert_text "text"
      end
    end

    test "renders footer with HTML content" do
      render_inline(Shared::ModalComponent.new(id: "html-footer", title: "Title")) do |c|
        c.with_body { "Body" }
        c.with_footer { "<button class='btn btn-primary'>Save</button>".html_safe }
      end
      
      assert_selector "div.modal-footer button.btn.btn-primary", text: "Save"
    end

    test "modal without body slot" do
      render_inline(Shared::ModalComponent.new(id: "no-body", title: "Title"))
      
      assert_selector "div.modal"
      assert_selector "div.modal-header"
      assert_no_selector "div.modal-body"
      assert_no_selector "div.modal-footer"
    end

    test "modal with all features" do
      render_inline(Shared::ModalComponent.new(
        id: "full-featured",
        title: "Complete Modal",
        size: "lg",
        centered: true,
        scrollable: true,
        static_backdrop: true,
        html_options: { class: "custom", data: { test: "value" } }
      )) do |c|
        c.with_body { "Body content" }
        c.with_footer { "Footer content" }
      end
      
      assert_selector "div.modal.fade.custom#full-featured[data-test='value'][data-bs-backdrop='static']"
      assert_selector "div.modal-dialog.modal-lg.modal-dialog-centered.modal-dialog-scrollable"
      assert_selector "h5.modal-title", text: "Complete Modal"
      assert_selector "div.modal-body", text: "Body content"
      assert_selector "div.modal-footer", text: "Footer content"
    end

    test "title ID matches aria-labelledby" do
      render_inline(Shared::ModalComponent.new(id: "aria-test", title: "Test")) do |c|
        c.with_body { "Content" }
      end
      
      assert_selector "div.modal[aria-labelledby='aria-testTitle']"
      assert_selector "h5.modal-title#aria-testTitle"
    end
  end
end
