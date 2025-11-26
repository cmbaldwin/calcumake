# frozen_string_literal: true

require "test_helper"

module Forms
  class FormSectionComponentTest < ViewComponent::TestCase
    # Basic Rendering Tests

    test "renders with required title" do
      render_inline(FormSectionComponent.new(title: "Test Section")) do
        "Form content"
      end

      assert_selector ".card .card-header h5", text: "Test Section"
      assert_selector ".card .card-body", text: "Form content"
    end

    test "renders without wrapper by default" do
      render_inline(FormSectionComponent.new(title: "Test Section")) do
        "Content"
      end

      # Should NOT have wrapper div, card should be at root
      assert_selector ".card"
      refute_selector "div > .card" # No parent div wrapping the card
    end

    test "renders with wrapper when wrapper_class provided" do
      render_inline(FormSectionComponent.new(
        title: "Test Section",
        wrapper_class: "col-md-6"
      )) do
        "Content"
      end

      assert_selector "div.col-md-6 > .card"
    end

    # Card Class Tests

    test "applies default card class" do
      render_inline(FormSectionComponent.new(title: "Test")) do
        "Content"
      end

      assert_selector ".card"
      refute_selector ".card.h-100"
    end

    test "applies custom card class" do
      render_inline(FormSectionComponent.new(
        title: "Test",
        card_class: "card h-100 shadow"
      )) do
        "Content"
      end

      assert_selector ".card.h-100.shadow"
    end

    # Header Class Tests

    test "applies default header class" do
      render_inline(FormSectionComponent.new(title: "Test")) do
        "Content"
      end

      assert_selector ".card-header h5.mb-0"
    end

    test "applies custom header class" do
      render_inline(FormSectionComponent.new(
        title: "Test",
        header_class: "card-header bg-primary"
      )) do
        "Content"
      end

      assert_selector ".card-header.bg-primary h5"
    end

    # Body Class Tests

    test "renders body content without wrapper by default" do
      render_inline(FormSectionComponent.new(title: "Test")) do
        "<div class='test-content'>Content</div>".html_safe
      end

      assert_selector ".card-body > .test-content"
      refute_selector ".card-body > div > .test-content"
    end

    test "wraps body content when body_class provided" do
      render_inline(FormSectionComponent.new(
        title: "Test",
        body_class: "row g-3"
      )) do
        "<div class='test-content'>Content</div>".html_safe
      end

      assert_selector ".card-body > .row.g-3 > .test-content"
    end

    # Help Text Tests

    test "renders without help text by default" do
      render_inline(FormSectionComponent.new(title: "Test")) do
        "Content"
      end

      refute_selector ".form-text"
    end

    test "renders help text when provided as parameter" do
      render_inline(FormSectionComponent.new(
        title: "Test",
        help_text: "This is help text"
      )) do
        "Content"
      end

      assert_selector ".card-body .form-text.mt-2", text: "This is help text"
    end

    test "renders help text when provided as slot" do
      render_inline(FormSectionComponent.new(title: "Test")) do |component|
        component.with_help { "Help via slot" }
        "Content"
      end

      assert_selector ".card-body .form-text.mt-2", text: "Help via slot"
    end

    test "slot help text takes precedence over parameter help text" do
      render_inline(FormSectionComponent.new(
        title: "Test",
        help_text: "Parameter help"
      )) do |component|
        component.with_help { "Slot help" }
        "Content"
      end

      assert_selector ".card-body .form-text", text: "Slot help"
      refute_selector ".card-body .form-text", text: "Parameter help"
    end

    # Complex Layout Tests

    test "renders complete form section with all options" do
      render_inline(FormSectionComponent.new(
        title: "Labor Costs",
        wrapper_class: "col-md-6",
        card_class: "card h-100",
        body_class: "row g-3",
        help_text: "All labor costs are calculated per hour"
      )) do
        "<div class='col-6'>Field 1</div><div class='col-6'>Field 2</div>".html_safe
      end

      assert_selector "div.col-md-6 > .card.h-100"
      assert_selector ".card-header h5", text: "Labor Costs"
      assert_selector ".card-body > .row.g-3"
      assert_selector ".card-body .col-6", count: 2
      assert_selector ".form-text", text: "All labor costs are calculated per hour"
    end

    # Edge Cases

    test "handles empty content block" do
      render_inline(FormSectionComponent.new(title: "Empty Section")) do
        ""
      end

      assert_selector ".card .card-header h5", text: "Empty Section"
      assert_selector ".card .card-body"
    end

    test "handles HTML in title" do
      render_inline(FormSectionComponent.new(
        title: "<i class='bi bi-gear'></i> Settings".html_safe
      )) do
        "Content"
      end

      assert_selector ".card-header h5 i.bi.bi-gear"
      assert_selector ".card-header h5", text: "Settings"
    end

    test "handles complex nested HTML content" do
      render_inline(FormSectionComponent.new(title: "Nested")) do
        <<~HTML.html_safe
          <div class="row g-3">
            <div class="col-6">
              <input type="text" class="form-control">
            </div>
            <div class="col-6">
              <select class="form-select"></select>
            </div>
          </div>
        HTML
      end

      assert_selector ".card-body .row.g-3"
      assert_selector ".card-body .form-control"
      assert_selector ".card-body .form-select"
    end

    # Real-World Pattern Tests

    test "matches print_pricing labor costs pattern" do
      render_inline(FormSectionComponent.new(
        title: "Labor Costs",
        wrapper_class: "col-md-6",
        card_class: "card h-100",
        body_class: "row g-3"
      )) do
        "<div class='col-6'>Prep Time</div><div class='col-6'>Prep Cost</div>".html_safe
      end

      assert_selector "div.col-md-6 > .card.h-100 > .card-header > h5", text: "Labor Costs"
      assert_selector ".card-body > .row.g-3 > .col-6", count: 2
    end

    test "matches invoice client selection pattern" do
      render_inline(FormSectionComponent.new(
        title: "Client Information"
      )) do
        "<div class='row g-3'><div class='col-12'>Client dropdown</div></div>".html_safe
      end

      assert_selector ".card > .card-header > h5", text: "Client Information"
      assert_selector ".card-body .row.g-3 .col-12"
    end
  end
end
