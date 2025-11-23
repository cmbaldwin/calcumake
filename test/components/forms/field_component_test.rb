# frozen_string_literal: true

require "test_helper"

module Forms
  class FieldComponentTest < ViewComponent::TestCase
    # Test helper to create a form builder
    def form_builder_for(model)
      ActionView::Helpers::FormBuilder.new(
        model.model_name.param_key,
        model,
        vc_test_controller.view_context,
        {}
      )
    end

    # Basic rendering tests
    test "renders text field with label" do
      filament = Filament.new
      form = form_builder_for(filament)

      render_inline(Forms::FieldComponent.new(
        form: form,
        attribute: :name,
        type: :text
      ))

      assert_selector "label.form-label", text: "Name"
      assert_selector "input[type='text'][name='filament[name]']"
      assert_selector "input.form-control"
    end

    test "renders with custom label" do
      filament = Filament.new
      form = form_builder_for(filament)

      render_inline(Forms::FieldComponent.new(
        form: form,
        attribute: :name,
        type: :text,
        label: "Custom Label"
      ))

      assert_selector "label", text: "Custom Label"
    end

    test "renders email field" do
      user = User.new
      form = form_builder_for(user)

      render_inline(Forms::FieldComponent.new(
        form: form,
        attribute: :email,
        type: :email
      ))

      assert_selector "input[type='email']"
    end

    test "renders number field" do
      filament = Filament.new
      form = form_builder_for(filament)

      render_inline(Forms::FieldComponent.new(
        form: form,
        attribute: :spool_weight,
        type: :number
      ))

      assert_selector "input[type='number']"
    end

    test "renders textarea" do
      filament = Filament.new
      form = form_builder_for(filament)

      render_inline(Forms::FieldComponent.new(
        form: form,
        attribute: :notes,
        type: :textarea
      ))

      assert_selector "textarea.form-control"
    end

    test "renders password field" do
      user = User.new
      form = form_builder_for(user)

      render_inline(Forms::FieldComponent.new(
        form: form,
        attribute: :password,
        type: :password
      ))

      assert_selector "input[type='password']"
    end

    test "renders date field" do
      invoice = invoices(:one)
      form = form_builder_for(invoice)

      render_inline(Forms::FieldComponent.new(
        form: form,
        attribute: :invoice_date,
        type: :date
      ))

      assert_selector "input[type='date'].form-control[name='invoice[invoice_date]']"
      assert_selector "label.form-label", text: "Invoice date"
    end

    test "renders telephone field" do
      user = User.new
      form = form_builder_for(user)

      render_inline(Forms::FieldComponent.new(
        form: form,
        attribute: :default_company_phone,
        type: :tel
      ))

      assert_selector "input[type='tel'].form-control[name='user[default_company_phone]']"
      assert_selector "label.form-label", text: "Default company phone"
    end

    # Options tests
    test "applies placeholder option" do
      filament = Filament.new
      form = form_builder_for(filament)

      render_inline(Forms::FieldComponent.new(
        form: form,
        attribute: :name,
        type: :text,
        options: { placeholder: "Enter name" }
      ))

      assert_selector "input[placeholder='Enter name']"
    end

    test "applies required option" do
      filament = Filament.new
      form = form_builder_for(filament)

      render_inline(Forms::FieldComponent.new(
        form: form,
        attribute: :name,
        type: :text,
        required: true
      ))

      assert_selector "input[required='required']"
    end

    test "applies step and min options for number fields" do
      filament = Filament.new
      form = form_builder_for(filament)

      render_inline(Forms::FieldComponent.new(
        form: form,
        attribute: :spool_weight,
        type: :number,
        options: { step: 0.01, min: 0 }
      ))

      assert_selector "input[step='0.01'][min='0']"
    end

    test "applies rows option for textarea" do
      filament = Filament.new
      form = form_builder_for(filament)

      render_inline(Forms::FieldComponent.new(
        form: form,
        attribute: :notes,
        type: :textarea,
        options: { rows: 5 }
      ))

      assert_selector "textarea[rows='5']"
    end

    test "applies custom class in addition to form-control" do
      filament = Filament.new
      form = form_builder_for(filament)

      render_inline(Forms::FieldComponent.new(
        form: form,
        attribute: :name,
        type: :text,
        options: { class: "custom-class" }
      ))

      assert_selector "input.form-control.custom-class"
    end

    # Hint text tests
    test "renders hint text when provided" do
      filament = Filament.new
      form = form_builder_for(filament)

      render_inline(Forms::FieldComponent.new(
        form: form,
        attribute: :name,
        type: :text,
        hint: "Enter the filament name"
      ))

      assert_selector "small.form-text.text-muted", text: "Enter the filament name"
    end

    test "does not render hint when not provided" do
      filament = Filament.new
      form = form_builder_for(filament)

      render_inline(Forms::FieldComponent.new(
        form: form,
        attribute: :name,
        type: :text
      ))

      refute_selector "small.form-text"
    end

    # Wrapper tests
    test "wraps field in div with default column class" do
      filament = Filament.new
      form = form_builder_for(filament)

      render_inline(Forms::FieldComponent.new(
        form: form,
        attribute: :name,
        type: :text
      ))

      assert_selector "div.col-12"
    end

    test "applies custom wrapper class" do
      filament = Filament.new
      form = form_builder_for(filament)

      render_inline(Forms::FieldComponent.new(
        form: form,
        attribute: :name,
        type: :text,
        wrapper_class: "col-md-6"
      ))

      assert_selector "div.col-md-6"
    end

    test "does not wrap when wrapper is false" do
      filament = Filament.new
      form = form_builder_for(filament)

      render_inline(Forms::FieldComponent.new(
        form: form,
        attribute: :name,
        type: :text,
        wrapper: false
      ))

      refute_selector "div.col-12"
      assert_selector "label"
      assert_selector "input"
    end

    # Helper method tests
    test "field_options merges default class with custom options" do
      filament = Filament.new
      form = form_builder_for(filament)

      component = Forms::FieldComponent.new(
        form: form,
        attribute: :name,
        type: :text,
        options: { placeholder: "test", class: "custom" }
      )

      opts = component.field_options
      assert_equal "form-control custom", opts[:class]
      assert_equal "test", opts[:placeholder]
    end

    test "label_text returns humanized attribute name by default" do
      filament = Filament.new
      form = form_builder_for(filament)

      component = Forms::FieldComponent.new(
        form: form,
        attribute: :spool_weight,
        type: :number
      )

      assert_equal "Spool weight", component.label_text
    end

    test "label_text returns custom label when provided" do
      filament = Filament.new
      form = form_builder_for(filament)

      component = Forms::FieldComponent.new(
        form: form,
        attribute: :name,
        type: :text,
        label: "Custom Label"
      )

      assert_equal "Custom Label", component.label_text
    end

    # Edge cases
    test "handles nil options gracefully" do
      filament = Filament.new
      form = form_builder_for(filament)

      render_inline(Forms::FieldComponent.new(
        form: form,
        attribute: :name,
        type: :text,
        options: nil
      ))

      assert_selector "input.form-control"
    end

    test "defaults to text type" do
      filament = Filament.new
      form = form_builder_for(filament)

      render_inline(Forms::FieldComponent.new(
        form: form,
        attribute: :name
      ))

      assert_selector "input[type='text']"
    end
  end
end
