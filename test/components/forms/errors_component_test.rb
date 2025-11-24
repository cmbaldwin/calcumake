# frozen_string_literal: true

require "test_helper"

class Forms::ErrorsComponentTest < ViewComponent::TestCase
  def setup
    @model = User.new
    @model.errors.add(:email, "can't be blank")
    @model.errors.add(:password, "is too short")
  end

  test "renders with errors" do
    render_inline(Forms::ErrorsComponent.new(model: @model))

    assert_selector "div.alert.alert-danger"
    assert_text "can't be blank"
    assert_text "is too short"
  end

  test "renders error count in header" do
    render_inline(Forms::ErrorsComponent.new(model: @model))

    assert_selector "h6.fw-bold", text: /2/
  end

  test "renders each error in list" do
    render_inline(Forms::ErrorsComponent.new(model: @model))

    assert_selector "ul.mb-0.ps-3 li", count: 2
  end

  test "does not render when no errors" do
    model_without_errors = User.new
    render_inline(Forms::ErrorsComponent.new(model: model_without_errors))

    refute_selector "div.alert"
  end

  test "uses custom model name from I18n" do
    render_inline(Forms::ErrorsComponent.new(model: @model))

    # Should use I18n translation for model name
    assert_text @model.class.model_name.human.downcase
  end

  test "renders full error messages" do
    render_inline(Forms::ErrorsComponent.new(model: @model))

    # Full messages include attribute name
    assert_selector "li", text: "Email can't be blank"
    assert_selector "li", text: "Password is too short"
  end

  test "applies custom CSS classes via html_options" do
    render_inline(Forms::ErrorsComponent.new(
      model: @model,
      html_options: { class: "custom-class" }
    ))

    assert_selector "div.alert.alert-danger.custom-class"
  end

  test "supports dismissible option" do
    render_inline(Forms::ErrorsComponent.new(
      model: @model,
      dismissible: true
    ))

    assert_selector "button.btn-close"
  end

  test "non-dismissible by default" do
    render_inline(Forms::ErrorsComponent.new(model: @model))

    refute_selector "button.btn-close"
  end
end
