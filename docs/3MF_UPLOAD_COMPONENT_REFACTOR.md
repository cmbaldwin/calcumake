# 3MF Upload ViewComponent Refactoring Plan

**Status:** Planned (Post-Merge)
**Created:** 2025-11-18
**Related PR:** #52 (ViewComponent Migration)

---

## Overview

After merging master (which includes the ViewComponent infrastructure from PR #52), the inline 3MF upload UI should be refactored into a reusable ViewComponent following the established patterns.

## Current Implementation

**Location:** `app/views/print_pricings/form_sections/_basic_information.html.erb` (lines 37-95)

**Current Approach:**
- Inline ERB partial with embedded logic
- Status tracking via model helper methods
- Stimulus controller for client-side validation

**Problems:**
- Not reusable (hardcoded to print_pricings)
- Status badge logic embedded in view
- No unit testability
- Violates DRY if used elsewhere

---

## Proposed Component Structure

### 1. Forms::FileUploadFieldComponent (Reusable Base)

```ruby
# app/components/forms/file_upload_field_component.rb
# frozen_string_literal: true

module Forms
  # Renders a file upload field with optional status tracking and validation
  #
  # @example Basic usage
  #   <%= render Forms::FileUploadFieldComponent.new(
  #     form: f,
  #     attribute: :attachment,
  #     label: "Upload File",
  #     accept: ".pdf,.doc"
  #   ) %>
  #
  # @example With status tracking
  #   <%= render Forms::FileUploadFieldComponent.new(
  #     form: f,
  #     attribute: :three_mf_file,
  #     label: "Upload 3MF File",
  #     accept: ".3mf",
  #     show_status: true,
  #     status_attribute: :three_mf_import_status,
  #     error_attribute: :three_mf_import_error
  #   ) %>
  class FileUploadFieldComponent < ViewComponent::Base
    # @param form [ActionView::Helpers::FormBuilder] The form builder instance
    # @param attribute [Symbol] The attribute name for the file field
    # @param label [String] Label text for the field
    # @param accept [String, nil] File type restrictions (e.g., ".3mf,.stl")
    # @param hint [String, nil] Help text shown below the field
    # @param required [Boolean] Whether the field is required
    # @param show_status [Boolean] Whether to show upload/processing status
    # @param status_attribute [Symbol, nil] Attribute name for status tracking
    # @param error_attribute [Symbol, nil] Attribute name for error messages
    # @param title [String, nil] Optional title for the upload section
    # @param title_icon [String, nil] Optional Bootstrap icon name (without 'bi-' prefix)
    # @param wrapper_class [String] CSS classes for the wrapper div
    # @param stimulus_controller [String, nil] Optional Stimulus controller name
    def initialize(
      form:,
      attribute:,
      label:,
      accept: nil,
      hint: nil,
      required: false,
      show_status: false,
      status_attribute: nil,
      error_attribute: nil,
      title: nil,
      title_icon: nil,
      wrapper_class: "col-12",
      stimulus_controller: nil
    )
      @form = form
      @attribute = attribute
      @label = label
      @accept = accept
      @hint = hint
      @required = required
      @show_status = show_status
      @status_attribute = status_attribute
      @error_attribute = error_attribute
      @title = title
      @title_icon = title_icon
      @wrapper_class = wrapper_class
      @stimulus_controller = stimulus_controller
    end

    # Returns the record being edited
    # @return [ActiveRecord::Base]
    def record
      @form.object
    end

    # Whether the file is attached
    # @return [Boolean]
    def file_attached?
      record.public_send(@attribute).attached?
    end

    # Returns the attached file
    # @return [ActiveStorage::Attached::One, nil]
    def attached_file
      file_attached? ? record.public_send(@attribute) : nil
    end

    # Returns current status if status tracking is enabled
    # @return [String, nil]
    def current_status
      return nil unless @show_status && @status_attribute
      record.public_send(@status_attribute)
    end

    # Returns error message if available
    # @return [String, nil]
    def error_message
      return nil unless @error_attribute && record.respond_to?(@error_attribute)
      record.public_send(@error_attribute)
    end

    # Status badge variant based on status
    # @return [String]
    def status_variant
      case current_status
      when "processing" then "info"
      when "completed" then "success"
      when "failed" then "danger"
      else "secondary"
      end
    end

    # Status icon name
    # @return [String, nil]
    def status_icon
      case current_status
      when "processing" then nil # Uses spinner instead
      when "completed" then "check-circle"
      when "failed" then "exclamation-circle"
      else nil
      end
    end

    # Status text key for i18n
    # @return [String]
    def status_text_key
      case current_status
      when "processing" then "processing"
      when "completed" then "completed"
      when "failed" then "failed"
      else "pending"
      end
    end

    # Data attributes for the file field
    # @return [Hash]
    def field_data_attributes
      attrs = {}
      attrs[:controller] = @stimulus_controller if @stimulus_controller
      attrs[:action] = "change->#{@stimulus_controller}#handleFileSelect" if @stimulus_controller
      attrs
    end
  end
end
```

```erb
<%# app/components/forms/file_upload_field_component.html.erb %>
<div class="<%= @wrapper_class %>">
  <div class="card bg-light">
    <div class="card-body">
      <% if @title.present? %>
        <h6 class="card-title mb-3">
          <% if @title_icon.present? %>
            <%= render Shared::IconComponent.new(name: @title_icon) %>
          <% end %>
          <%= @title %>
        </h6>
      <% end %>

      <%= @form.label @attribute, @label, class: "form-label" %>
      <%= @form.file_field @attribute,
          class: "form-control",
          accept: @accept,
          required: @required,
          data: field_data_attributes %>

      <% if @hint.present? %>
        <div class="form-text mt-2">
          <%= @hint %>
        </div>
      <% end %>

      <% if @show_status && file_attached? %>
        <div class="mt-3 p-2 border rounded bg-white">
          <div class="d-flex align-items-center gap-2">
            <%= render Shared::IconComponent.new(
              name: "file-earmark-check",
              variant: "success"
            ) %>

            <span class="flex-grow-1">
              <strong><%= attached_file.filename %></strong>
              <small class="text-muted d-block">
                <%= number_to_human_size(attached_file.byte_size) %>
              </small>
            </span>

            <% if current_status == "processing" %>
              <%= render Shared::BadgeComponent.new(
                text: t("print_pricing.three_mf.status.#{status_text_key}"),
                variant: status_variant
              ) do %>
                <span class="spinner-border spinner-border-sm me-1"></span>
              <% end %>
            <% elsif current_status.present? %>
              <%= render Shared::BadgeComponent.new(
                text: t("print_pricing.three_mf.status.#{status_text_key}"),
                variant: status_variant,
                icon: status_icon
              ) %>
            <% end %>
          </div>

          <% if current_status == "failed" && error_message.present? %>
            <%= render Shared::AlertComponent.new(
              variant: "danger",
              dismissible: false,
              html_options: { class: "mt-2 mb-0 small" }
            ) do %>
              <%= error_message %>
            <% end %>
          <% end %>
        </div>
      <% end %>
    </div>
  </div>
</div>
```

### 2. Usage in Print Pricing Form

```erb
<%# app/views/print_pricings/form_sections/_basic_information.html.erb %>

<%= render Forms::FileUploadFieldComponent.new(
  form: f,
  attribute: :three_mf_file,
  label: t('print_pricing.three_mf.file_label'),
  accept: ".3mf",
  hint: t('print_pricing.three_mf.help_text'),
  show_status: true,
  status_attribute: :three_mf_import_status,
  error_attribute: :three_mf_import_error,
  title: t('print_pricing.three_mf.import_title'),
  title_icon: "file-earmark-zip",
  stimulus_controller: "three-mf-upload"
) %>
```

### 3. Component Test

```ruby
# test/components/forms/file_upload_field_component_test.rb
require "test_helper"

module Forms
  class FileUploadFieldComponentTest < ViewComponent::TestCase
    def setup
      @user = users(:one)
      @printer = printers(:one)
      @print_pricing = PrintPricing.new(
        user: @user,
        printer: @printer,
        job_name: "Test"
      )
      @form_builder = ActionView::Helpers::FormBuilder.new(
        :print_pricing,
        @print_pricing,
        view_context,
        {}
      )
    end

    test "renders basic file upload field" do
      render_inline(Forms::FileUploadFieldComponent.new(
        form: @form_builder,
        attribute: :three_mf_file,
        label: "Upload 3MF File"
      ))

      assert_selector "input[type='file'][name='print_pricing[three_mf_file]']"
      assert_selector "label", text: "Upload 3MF File"
    end

    test "renders with accept attribute" do
      render_inline(Forms::FileUploadFieldComponent.new(
        form: @form_builder,
        attribute: :three_mf_file,
        label: "Upload",
        accept: ".3mf"
      ))

      assert_selector "input[accept='.3mf']"
    end

    test "renders with hint text" do
      render_inline(Forms::FileUploadFieldComponent.new(
        form: @form_builder,
        attribute: :three_mf_file,
        label: "Upload",
        hint: "Only 3MF files are supported"
      ))

      assert_selector ".form-text", text: "Only 3MF files are supported"
    end

    test "renders title with icon" do
      render_inline(Forms::FileUploadFieldComponent.new(
        form: @form_builder,
        attribute: :three_mf_file,
        label: "Upload",
        title: "Import from 3MF",
        title_icon: "file-earmark-zip"
      ))

      assert_selector "h6.card-title", text: "Import from 3MF"
    end

    test "shows processing status badge" do
      @print_pricing.save!
      @print_pricing.update_column(:three_mf_import_status, "processing")

      render_inline(Forms::FileUploadFieldComponent.new(
        form: @form_builder,
        attribute: :three_mf_file,
        label: "Upload",
        show_status: true,
        status_attribute: :three_mf_import_status
      ))

      # Status section only shows when file is attached
      # This test needs a mock attached file
    end

    test "shows error message when failed" do
      @print_pricing.save!
      @print_pricing.update_columns(
        three_mf_import_status: "failed",
        three_mf_import_error: "Invalid file format"
      )

      render_inline(Forms::FileUploadFieldComponent.new(
        form: @form_builder,
        attribute: :three_mf_file,
        label: "Upload",
        show_status: true,
        status_attribute: :three_mf_import_status,
        error_attribute: :three_mf_import_error
      ))

      # Error message only shows when file is attached
      # This test needs a mock attached file
    end

    test "includes Stimulus controller data attributes" do
      render_inline(Forms::FileUploadFieldComponent.new(
        form: @form_builder,
        attribute: :three_mf_file,
        label: "Upload",
        stimulus_controller: "three-mf-upload"
      ))

      assert_selector "input[data-controller='three-mf-upload']"
      assert_selector "input[data-action='change->three-mf-upload#handleFileSelect']"
    end
  end
end
```

---

## Migration Checklist

**Phase 1: Create Base Component**
- [ ] Create `app/components/forms/file_upload_field_component.rb`
- [ ] Create `app/components/forms/file_upload_field_component.html.erb`
- [ ] Create `test/components/forms/file_upload_field_component_test.rb`
- [ ] Write comprehensive tests (90%+ coverage)
- [ ] Ensure all tests pass

**Phase 2: Replace Partial**
- [ ] Update `_basic_information.html.erb` to use component
- [ ] Remove inline HTML and logic
- [ ] Test form rendering manually
- [ ] Verify status tracking works
- [ ] Verify file validation works

**Phase 3: Documentation**
- [ ] Add YARD documentation to component class
- [ ] Add usage examples in comments
- [ ] Update CLAUDE.md with component patterns
- [ ] Document status tracking API

**Phase 4: Validation**
- [ ] Run full test suite
- [ ] Manual browser testing (upload, status, errors)
- [ ] Test with real 3MF files
- [ ] Verify Stimulus controller integration
- [ ] Check mobile responsiveness

---

## Benefits of Refactoring

### ✅ Reusability
- Can be used for any file upload (STL, PDF, images)
- Configurable status tracking works with any background job
- Generic error display

### ✅ Testability
- Unit testable in isolation
- No need for integration tests for simple rendering
- Easy to test edge cases

### ✅ Maintainability
- Self-contained logic
- Clear API via initializer
- Easy to update styling
- Single source of truth

### ✅ Consistency
- Follows ViewComponent patterns from PR #52
- Matches Forms:: namespace conventions
- Uses existing Shared:: components (Badge, Icon, Alert)

---

## Timeline

**Trigger:** After feature branch is merged to master
**Estimated Effort:** 2-3 hours
**Priority:** Medium (works fine as-is, but should be standardized)

---

## Related Components

This component will leverage existing components:
- `Shared::BadgeComponent` - For status badges
- `Shared::IconComponent` - For icons
- `Shared::AlertComponent` - For error messages

---

**Document Status:** PLANNED
**Last Updated:** 2025-11-18
**Owner:** Development Team
**Related:** PR #52 (ViewComponent Migration)
