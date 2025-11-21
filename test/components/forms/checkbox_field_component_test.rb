# frozen_string_literal: true

require "test_helper"

module Forms
  class CheckboxFieldComponentTest < ViewComponent::TestCase
    def setup
      @filament = Filament.new(moisture_sensitive: false)
      @form_builder = ActionView::Helpers::FormBuilder.new(:filament, @filament, vc_test_controller.view_context, {})
    end

    # Basic rendering tests
    test "renders checkbox with label" do
      render_inline(CheckboxFieldComponent.new(
        form: @form_builder,
        attribute: :moisture_sensitive
      ))

      assert_selector "input[type='checkbox'].form-check-input[name='filament[moisture_sensitive]']"
      assert_selector "label.form-check-label", text: "Moisture sensitive"
    end

    test "renders with custom label text" do
      render_inline(CheckboxFieldComponent.new(
        form: @form_builder,
        attribute: :moisture_sensitive,
        label: "Is moisture sensitive?"
      ))

      assert_selector "label.form-check-label", text: "Is moisture sensitive?"
    end

    test "hides label when label is false" do
      render_inline(CheckboxFieldComponent.new(
        form: @form_builder,
        attribute: :moisture_sensitive,
        label: false
      ))

      refute_selector "label"
      assert_selector "input[type='checkbox']"
    end

    # Checkbox state tests
    test "renders unchecked checkbox" do
      @filament.moisture_sensitive = false

      render_inline(CheckboxFieldComponent.new(
        form: @form_builder,
        attribute: :moisture_sensitive
      ))

      refute_selector "input[checked]"
    end

    test "renders checked checkbox" do
      @filament.moisture_sensitive = true

      render_inline(CheckboxFieldComponent.new(
        form: @form_builder,
        attribute: :moisture_sensitive
      ))

      assert_selector "input[checked='checked']"
    end

    # Hint text tests
    test "renders hint text" do
      render_inline(CheckboxFieldComponent.new(
        form: @form_builder,
        attribute: :moisture_sensitive,
        hint: "Check if filament absorbs moisture"
      ))

      assert_selector ".form-text", text: "Check if filament absorbs moisture"
    end

    test "does not render hint when not provided" do
      render_inline(CheckboxFieldComponent.new(
        form: @form_builder,
        attribute: :moisture_sensitive
      ))

      refute_selector ".form-text"
    end

    # Wrapper tests
    test "wraps in div with default class" do
      render_inline(CheckboxFieldComponent.new(
        form: @form_builder,
        attribute: :moisture_sensitive
      ))

      assert_selector "div.col-12 .form-check"
    end

    test "wraps in div with custom class" do
      render_inline(CheckboxFieldComponent.new(
        form: @form_builder,
        attribute: :moisture_sensitive,
        wrapper_class: "col-md-6"
      ))

      assert_selector "div.col-md-6 .form-check"
    end

    test "does not wrap when wrapper is false" do
      render_inline(CheckboxFieldComponent.new(
        form: @form_builder,
        attribute: :moisture_sensitive,
        wrapper: false
      ))

      refute_selector "div.col-12"
      assert_selector ".form-check"
    end

    # Custom options tests
    test "applies custom options to checkbox" do
      render_inline(CheckboxFieldComponent.new(
        form: @form_builder,
        attribute: :moisture_sensitive,
        options: { data: { controller: "checkbox" }, class: "custom-check" }
      ))

      assert_selector "input.form-check-input.custom-check[data-controller='checkbox']"
    end

    # Error handling tests
    test "displays validation errors" do
      @filament.errors.add(:moisture_sensitive, "must be accepted")

      render_inline(CheckboxFieldComponent.new(
        form: @form_builder,
        attribute: :moisture_sensitive
      ))

      assert_selector ".invalid-feedback", text: "must be accepted"
    end

    test "does not show error feedback when no errors" do
      render_inline(CheckboxFieldComponent.new(
        form: @form_builder,
        attribute: :moisture_sensitive
      ))

      refute_selector ".invalid-feedback"
    end

    # Non-model form support tests
    test "works without form object" do
      form_builder = ActionView::Helpers::FormBuilder.new(:search, nil, vc_test_controller.view_context, {})

      render_inline(CheckboxFieldComponent.new(
        form: form_builder,
        attribute: :include_archived
      ))

      assert_selector "input[type='checkbox']"
      refute_selector ".invalid-feedback"
    end

    # Bootstrap form-check structure test
    test "uses correct Bootstrap form-check structure" do
      render_inline(CheckboxFieldComponent.new(
        form: @form_builder,
        attribute: :moisture_sensitive
      ))

      assert_selector ".form-check" do
        assert_selector "input.form-check-input"
        assert_selector "label.form-check-label"
      end
    end
  end
end
