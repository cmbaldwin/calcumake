# frozen_string_literal: true

require "test_helper"

class ModalComponentTest < ViewComponent::TestCase
  test "renders with required id" do
    render_inline(ModalComponent.new(id: "testModal")) do
      "Modal content"
    end

    assert_selector "div.modal#testModal"
    assert_selector "div.modal-body", text: "Modal content"
  end

  test "renders with title in header" do
    render_inline(ModalComponent.new(id: "testModal", title: "Modal Title")) do
      "Content"
    end

    assert_selector "div.modal-header h5.modal-title", text: "Modal Title"
  end

  test "renders with default size" do
    render_inline(ModalComponent.new(id: "testModal")) do
      "Content"
    end

    assert_selector "div.modal-dialog"
    refute_selector "div.modal-sm"
    refute_selector "div.modal-lg"
    refute_selector "div.modal-xl"
  end

  test "renders with small size" do
    render_inline(ModalComponent.new(id: "testModal", size: "sm")) do
      "Content"
    end

    assert_selector "div.modal-dialog.modal-sm"
  end

  test "renders with large size" do
    render_inline(ModalComponent.new(id: "testModal", size: "lg")) do
      "Content"
    end

    assert_selector "div.modal-dialog.modal-lg"
  end

  test "renders with extra large size" do
    render_inline(ModalComponent.new(id: "testModal", size: "xl")) do
      "Content"
    end

    assert_selector "div.modal-dialog.modal-xl"
  end

  test "renders centered when specified" do
    render_inline(ModalComponent.new(id: "testModal", centered: true)) do
      "Content"
    end

    assert_selector "div.modal-dialog.modal-dialog-centered"
  end

  test "renders scrollable when specified" do
    render_inline(ModalComponent.new(id: "testModal", scrollable: true)) do
      "Content"
    end

    assert_selector "div.modal-dialog.modal-dialog-scrollable"
  end

  test "renders with custom header slot" do
    render_inline(ModalComponent.new(id: "testModal")) do |component|
      component.with_header do
        "<strong>Custom Header</strong>".html_safe
      end
      "Body content"
    end

    assert_selector "div.modal-header strong", text: "Custom Header"
  end

  test "renders with custom body slot" do
    render_inline(ModalComponent.new(id: "testModal", title: "Title")) do |component|
      component.with_body do
        "<p>Custom body content</p>".html_safe
      end
    end

    assert_selector "div.modal-body p", text: "Custom body content"
  end

  test "renders with custom footer slot" do
    render_inline(ModalComponent.new(id: "testModal", title: "Title")) do |component|
      component.with_footer do
        "<button>Custom Footer</button>".html_safe
      end
      "Body"
    end

    assert_selector "div.modal-footer button", text: "Custom Footer"
    refute_selector "button.btn-secondary[data-bs-dismiss='modal']", text: "Close"
  end

  test "renders default footer when footer is true" do
    render_inline(ModalComponent.new(id: "testModal", title: "Title", footer: true)) do
      "Content"
    end

    assert_selector "div.modal-footer button.btn-secondary[data-bs-dismiss='modal']", text: "Close"
  end

  test "does not render footer when footer is false" do
    render_inline(ModalComponent.new(id: "testModal", title: "Title", footer: false)) do
      "Content"
    end

    refute_selector "div.modal-footer"
  end

  test "includes close button in header" do
    render_inline(ModalComponent.new(id: "testModal", title: "Title")) do
      "Content"
    end

    assert_selector "div.modal-header button.btn-close[data-bs-dismiss='modal']"
  end

  test "has proper accessibility attributes" do
    render_inline(ModalComponent.new(id: "testModal", title: "Accessible Modal")) do
      "Content"
    end

    assert_selector "div.modal[tabindex='-1'][aria-hidden='true']"
    assert_selector "h5.modal-title#testModalLabel"
    assert_selector "div.modal[aria-labelledby='testModalLabel']"
  end

  test "raises error for invalid size" do
    error = assert_raises(ArgumentError) do
      ModalComponent.new(id: "testModal", size: "xxl")
    end

    assert_match(/Invalid size/, error.message)
  end

  test "combines all features" do
    render_inline(ModalComponent.new(
      id: "complexModal",
      title: "Complex Modal",
      size: "lg",
      centered: true,
      scrollable: true
    )) do |component|
      component.with_footer do
        "<button class='btn btn-primary'>Save</button>".html_safe
      end
      "Complex content"
    end

    assert_selector "div.modal#complexModal"
    assert_selector "div.modal-dialog.modal-lg.modal-dialog-centered.modal-dialog-scrollable"
    assert_selector "h5.modal-title", text: "Complex Modal"
    assert_selector "div.modal-body", text: "Complex content"
    assert_selector "div.modal-footer button.btn-primary", text: "Save"
  end

  test "renders with all slots custom" do
    render_inline(ModalComponent.new(id: "allSlots")) do |component|
      component.with_header { "Custom Header" }
      component.with_body { "Custom Body" }
      component.with_footer { "Custom Footer" }
    end

    assert_selector "div.modal-header", text: "Custom Header"
    assert_selector "div.modal-body", text: "Custom Body"
    assert_selector "div.modal-footer", text: "Custom Footer"
  end
end
