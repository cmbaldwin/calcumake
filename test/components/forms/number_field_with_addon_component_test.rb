# frozen_string_literal: true

require "test_helper"

module Forms
  class NumberFieldWithAddonComponentTest < ViewComponent::TestCase
    def setup
      @filament = Filament.new(spool_price: 25.00, spool_weight: 1000.0)
      @form_builder = ActionView::Helpers::FormBuilder.new(:filament, @filament, vc_test_controller.view_context, {})
    end

    # Basic rendering tests
    test "renders number field with prepend addon" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_price,
        prepend: "$"
      ))

      assert_selector "input[type='number'].form-control[name='filament[spool_price]']"
      assert_selector ".input-group-text", text: "$"
    end

    test "renders number field with append addon" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_weight,
        append: "g"
      ))

      assert_selector "input[type='number'].form-control[name='filament[spool_weight]']"
      assert_selector ".input-group-text", text: "g"
    end

    test "renders number field with both prepend and append" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_price,
        prepend: "$",
        append: "/kg"
      ))

      assert_selector ".input-group-text", text: "$"
      assert_selector ".input-group-text", text: "/kg"
    end

    # Label tests
    test "renders label by default" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_price,
        prepend: "$"
      ))

      assert_selector "label.form-label", text: "Spool price"
    end

    test "renders custom label text" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_price,
        label: "Price per Spool",
        prepend: "$"
      ))

      assert_selector "label.form-label", text: "Price per Spool"
    end

    test "hides label when label is false" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_price,
        label: false,
        prepend: "$"
      ))

      refute_selector "label"
    end

    # Input group size tests
    test "renders with small input group" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_price,
        prepend: "$",
        input_group_size: "sm"
      ))

      assert_selector ".input-group.input-group-sm"
    end

    test "renders with large input group" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_price,
        prepend: "$",
        input_group_size: "lg"
      ))

      assert_selector ".input-group.input-group-lg"
    end

    # Number field attributes
    test "sets step attribute" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_price,
        prepend: "$",
        step: 0.01
      ))

      assert_selector "input[step='0.01']"
    end

    test "sets min attribute" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_price,
        prepend: "$",
        min: 0
      ))

      assert_selector "input[min='0']"
    end

    test "sets max attribute" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_price,
        prepend: "$",
        max: 1000
      ))

      assert_selector "input[max='1000']"
    end

    test "sets placeholder" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_price,
        prepend: "$",
        placeholder: "0.00"
      ))

      assert_selector "input[placeholder='0.00']"
    end

    # Required field
    test "marks field as required" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_price,
        prepend: "$",
        required: true
      ))

      assert_selector "input[required='required']"
    end

    # Hint text
    test "renders hint text" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_price,
        prepend: "$",
        hint: "Enter the price per spool"
      ))

      assert_selector ".form-text", text: "Enter the price per spool"
    end

    test "does not render hint when not provided" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_price,
        prepend: "$"
      ))

      refute_selector ".form-text"
    end

    # Wrapper options
    test "wraps in div with default class" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_price,
        prepend: "$"
      ))

      assert_selector "div.col-12 .input-group"
    end

    test "wraps in div with custom class" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_price,
        prepend: "$",
        wrapper_class: "col-md-6"
      ))

      assert_selector "div.col-md-6 .input-group"
    end

    test "does not wrap when wrapper is false" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_price,
        prepend: "$",
        wrapper: false
      ))

      refute_selector "div.col-12"
      assert_selector ".input-group"
    end

    # Custom options
    test "applies custom options to input" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_price,
        prepend: "$",
        options: { data: { controller: "price" }, class: "custom-class" }
      ))

      assert_selector "input.form-control.custom-class[data-controller='price']"
    end

    # Error handling
    test "displays validation errors" do
      @filament.errors.add(:spool_price, "must be greater than 0")

      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_price,
        prepend: "$"
      ))

      assert_selector ".invalid-feedback", text: "must be greater than 0"
    end

    test "does not show error feedback when no errors" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_price,
        prepend: "$"
      ))

      refute_selector ".invalid-feedback"
    end

    # Edge cases
    test "renders without addons" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :spool_price
      ))

      assert_selector ".input-group"
      assert_selector "input.form-control"
      refute_selector ".input-group-text"
    end

    test "handles complex addon text" do
      render_inline(NumberFieldWithAddonComponent.new(
        form: @form_builder,
        attribute: :density,
        append: "g/cm³"
      ))

      assert_selector ".input-group-text", text: "g/cm³"
    end
  end
end
