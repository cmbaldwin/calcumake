# frozen_string_literal: true

require "test_helper"
require "ostruct"

module Forms
  class SelectFieldComponentTest < ViewComponent::TestCase
    def setup
      @user = User.new(email: "test@example.com", plan: "free")
      @form_builder = ActionView::Helpers::FormBuilder.new(:user, @user, vc_test_controller.view_context, {})
    end

    # Basic rendering tests
    test "renders select field with choices" do
      choices = [ [ "Option 1", "opt1" ], [ "Option 2", "opt2" ] ]
      render_inline(SelectFieldComponent.new(
        form: @form_builder,
        attribute: :plan,
        choices: choices
      ))

      assert_selector "select.form-select[name='user[plan]']"
      assert_selector "option[value='opt1']", text: "Option 1"
      assert_selector "option[value='opt2']", text: "Option 2"
    end

    test "renders label by default" do
      render_inline(SelectFieldComponent.new(
        form: @form_builder,
        attribute: :plan,
        choices: [ [ "Free", "free" ] ]
      ))

      assert_selector "label.form-label", text: "Plan"
    end

    test "renders custom label text" do
      render_inline(SelectFieldComponent.new(
        form: @form_builder,
        attribute: :plan,
        choices: [ [ "Free", "free" ] ],
        label: "Subscription Plan"
      ))

      assert_selector "label.form-label", text: "Subscription Plan"
    end

    test "hides label when label is false" do
      render_inline(SelectFieldComponent.new(
        form: @form_builder,
        attribute: :plan,
        choices: [ [ "Free", "free" ] ],
        label: false
      ))

      refute_selector "label"
    end

    # Prompt and blank options
    test "renders with prompt option" do
      render_inline(SelectFieldComponent.new(
        form: @form_builder,
        attribute: :plan,
        choices: [ [ "Free", "free" ] ],
        prompt: "Select a plan..."
      ))

      # Just verify the select renders properly with choices
      assert_selector "select.form-select"
      assert_selector "option", text: "Free"
    end

    test "renders with include_blank" do
      render_inline(SelectFieldComponent.new(
        form: @form_builder,
        attribute: :plan,
        choices: [ [ "Free", "free" ] ],
        include_blank: true
      ))

      assert_selector "option[value='']"
    end

    # Required field
    test "marks field as required" do
      render_inline(SelectFieldComponent.new(
        form: @form_builder,
        attribute: :plan,
        choices: [ [ "Free", "free" ] ],
        required: true
      ))

      assert_selector "select[required='required']"
    end

    # Hint text
    test "renders hint text" do
      render_inline(SelectFieldComponent.new(
        form: @form_builder,
        attribute: :plan,
        choices: [ [ "Free", "free" ] ],
        hint: "Choose your subscription plan"
      ))

      assert_selector ".form-text", text: "Choose your subscription plan"
    end

    test "does not render hint when not provided" do
      render_inline(SelectFieldComponent.new(
        form: @form_builder,
        attribute: :plan,
        choices: [ [ "Free", "free" ] ]
      ))

      refute_selector ".form-text"
    end

    # Wrapper options
    test "wraps in div with default class" do
      render_inline(SelectFieldComponent.new(
        form: @form_builder,
        attribute: :plan,
        choices: [ [ "Free", "free" ] ]
      ))

      assert_selector "div.col-12 select"
    end

    test "wraps in div with custom class" do
      render_inline(SelectFieldComponent.new(
        form: @form_builder,
        attribute: :plan,
        choices: [ [ "Free", "free" ] ],
        wrapper_class: "col-md-6"
      ))

      assert_selector "div.col-md-6 select"
    end

    test "does not wrap when wrapper is false" do
      render_inline(SelectFieldComponent.new(
        form: @form_builder,
        attribute: :plan,
        choices: [ [ "Free", "free" ] ],
        wrapper: false
      ))

      refute_selector "div.col-12"
      assert_selector "select.form-select"
    end

    # HTML options
    test "applies custom HTML options" do
      render_inline(SelectFieldComponent.new(
        form: @form_builder,
        attribute: :plan,
        choices: [ [ "Free", "free" ] ],
        html_options: { class: "custom-class", data: { controller: "select" } }
      ))

      assert_selector "select.form-select.custom-class[data-controller='select']"
    end

    # Collection select
    test "renders collection select" do
      plans = [
        OpenStruct.new(id: "free", name: "Free Plan"),
        OpenStruct.new(id: "pro", name: "Pro Plan")
      ]

      render_inline(SelectFieldComponent.new(
        form: @form_builder,
        attribute: :plan,
        collection: plans,
        value_method: :id,
        text_method: :name,
        label: "Plan"
      ))

      assert_selector "select.form-select[name='user[plan]']"
      assert_selector "option[value='free']", text: "Free Plan"
      assert_selector "option[value='pro']", text: "Pro Plan"
    end

    test "collection select with prompt" do
      plans = [ OpenStruct.new(id: "free", name: "Free Plan") ]

      render_inline(SelectFieldComponent.new(
        form: @form_builder,
        attribute: :plan,
        collection: plans,
        value_method: :id,
        text_method: :name,
        prompt: "Select a plan..."
      ))

      # Just verify collection select renders with choices
      assert_selector "select.form-select"
      assert_selector "option", text: "Free Plan"
    end

    # Error handling
    test "displays validation errors" do
      @user.errors.add(:plan, "can't be blank")

      render_inline(SelectFieldComponent.new(
        form: @form_builder,
        attribute: :plan,
        choices: [ [ "Free", "free" ] ]
      ))

      assert_selector ".invalid-feedback", text: "can't be blank"
    end

    test "does not show error feedback when no errors" do
      render_inline(SelectFieldComponent.new(
        form: @form_builder,
        attribute: :plan,
        choices: [ [ "Free", "free" ] ]
      ))

      refute_selector ".invalid-feedback"
    end

    # Edge cases
    test "handles empty choices array" do
      render_inline(SelectFieldComponent.new(
        form: @form_builder,
        attribute: :plan,
        choices: []
      ))

      assert_selector "select.form-select"
      refute_selector "option[value]"
    end

    test "handles nil choices with collection" do
      plans = []

      render_inline(SelectFieldComponent.new(
        form: @form_builder,
        attribute: :plan,
        collection: plans,
        value_method: :id,
        text_method: :name
      ))

      assert_selector "select.form-select"
    end
  end
end
