# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

module Forms
  class FormActionsComponentTest < ViewComponent::TestCase
    def setup
      @user = users(:one)
      @form_builder = ActionView::Helpers::FormBuilder.new(
        :user,
        @user,
        ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil),
        {}
      )
    end

    # Basic Rendering Tests

    test "renders submit button with default text for new record" do
      user = User.new
      form = build_form_for(user)

      render_inline(FormActionsComponent.new(form: form))

      assert_selector 'input[type="submit"][value="Create"]'
      assert_selector "input.btn.btn-primary"
    end

    test "renders submit button with default text for persisted record" do
      render_inline(FormActionsComponent.new(form: @form_builder))

      assert_selector 'input[type="submit"][value="Update"]'
      assert_selector "input.btn.btn-primary"
    end

    test "renders submit button with custom text" do
      render_inline(FormActionsComponent.new(
        form: @form_builder,
        submit_text: "Save Changes"
      ))

      assert_selector 'input[type="submit"][value="Save Changes"]'
    end

    test "renders without cancel link when no cancel_url provided" do
      render_inline(FormActionsComponent.new(form: @form_builder))

      refute_selector "a.btn-outline-secondary"
    end

    test "renders cancel link when cancel_url provided" do
      render_inline(FormActionsComponent.new(
        form: @form_builder,
        cancel_url: "/users"
      ))

      assert_selector "a.btn-outline-secondary[href='/users']", text: "Cancel"
    end

    test "renders cancel link with custom text" do
      render_inline(FormActionsComponent.new(
        form: @form_builder,
        cancel_url: "/users",
        cancel_text: "Go Back"
      ))

      assert_selector "a[href='/users']", text: "Go Back"
    end

    # Custom Classes Tests

    test "applies custom submit button classes" do
      render_inline(FormActionsComponent.new(
        form: @form_builder,
        submit_class: "btn btn-success btn-lg"
      ))

      assert_selector "input.btn.btn-success.btn-lg"
      refute_selector "button.btn-primary"
    end

    test "applies custom cancel button classes" do
      render_inline(FormActionsComponent.new(
        form: @form_builder,
        cancel_url: "/users",
        cancel_class: "btn btn-link"
      ))

      assert_selector "a.btn.btn-link"
      refute_selector "a.btn-outline-secondary"
    end

    test "applies custom wrapper classes" do
      render_inline(FormActionsComponent.new(
        form: @form_builder,
        wrapper_class: "custom-wrapper text-end"
      ))

      assert_selector "div.custom-wrapper.text-end"
      refute_selector "div.d-flex"
    end

    # Data Attributes Tests

    test "applies data attributes to submit button" do
      render_inline(FormActionsComponent.new(
        form: @form_builder,
        submit_data: { turbo_confirm: "Are you sure?", action: "click->form#submit" }
      ))

      assert_selector "input[data-turbo-confirm='Are you sure?']"
      assert_selector "input[data-action='click->form#submit']"
    end

    test "applies data attributes to cancel link" do
      render_inline(FormActionsComponent.new(
        form: @form_builder,
        cancel_url: "/users",
        cancel_data: { turbo_method: "get", controller: "navigation" }
      ))

      assert_selector "a[data-turbo-method='get']"
      assert_selector "a[data-controller='navigation']"
    end

    # Layout Tests

    test "renders with default flexbox layout" do
      render_inline(FormActionsComponent.new(
        form: @form_builder,
        cancel_url: "/users"
      ))

      assert_selector "div.d-flex.justify-content-center.gap-3.mb-5"
    end

    test "renders buttons in correct order" do
      render_inline(FormActionsComponent.new(
        form: @form_builder,
        cancel_url: "/users"
      ))

      html = page.native.to_html
      submit_index = html.index('<input')
      cancel_index = html.index('<a')

      assert submit_index < cancel_index, "Submit button should appear before cancel link"
    end

    # Edge Cases

    test "handles nil form object gracefully" do
      form = build_form_for(nil)

      render_inline(FormActionsComponent.new(form: form))

      assert_selector 'input[type="submit"]'
    end

    test "handles form without object method" do
      mock_form = Minitest::Mock.new
      def mock_form.submit(text, **options)
        "<input type='submit' value='#{text}'>".html_safe
      end

      render_inline(FormActionsComponent.new(form: mock_form))

      assert_selector 'input[type="submit"]'
    end

    private

    def build_form_for(object)
      ActionView::Helpers::FormBuilder.new(
        :user,
        object,
        ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil),
        {}
      )
    end
  end
end
