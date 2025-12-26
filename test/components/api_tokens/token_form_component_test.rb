# frozen_string_literal: true

require "test_helper"

module ApiTokens
  class TokenFormComponentTest < ViewComponent::TestCase
    setup do
      @user = users(:one)
      @token = @user.api_tokens.build
    end

    test "renders form element" do
      render_inline(TokenFormComponent.new(token: @token))

      assert_selector "form[action='#{api_tokens_path}']"
    end

    test "renders name field" do
      render_inline(TokenFormComponent.new(token: @token))

      assert_selector "input[name='api_token[name]']"
    end

    test "renders expiration select" do
      render_inline(TokenFormComponent.new(token: @token))

      assert_selector "select[name='api_token[expiration]']"
    end

    test "renders all expiration options" do
      render_inline(TokenFormComponent.new(token: @token))

      assert_selector "option", text: "30 days"
      assert_selector "option", text: "90 days"
      assert_selector "option", text: "1 year"
      assert_selector "option", text: /Never expires/i
    end

    test "renders submit button" do
      render_inline(TokenFormComponent.new(token: @token))

      assert_selector "input[type='submit']"
    end

    test "renders cancel link" do
      render_inline(TokenFormComponent.new(token: @token))

      assert_selector "a[href*='profile']", text: /Cancel/i
    end

    test "expiration_options returns correct format" do
      component = TokenFormComponent.new(token: @token)
      options = component.expiration_options

      assert_kind_of Array, options
      assert_equal 4, options.length

      # Each option should be [label, value]
      options.each do |option|
        assert_kind_of Array, option
        assert_equal 2, option.length
      end
    end

    test "expiration_options includes all EXPIRATION_OPTIONS keys" do
      component = TokenFormComponent.new(token: @token)
      options = component.expiration_options
      values = options.map(&:last)

      ApiToken::EXPIRATION_OPTIONS.keys.each do |key|
        assert_includes values, key
      end
    end

    test "form includes turbo frame attribute" do
      render_inline(TokenFormComponent.new(token: @token))

      assert_selector "form[data-turbo-frame='api_tokens_list']"
    end

    test "name field has autofocus" do
      render_inline(TokenFormComponent.new(token: @token))

      assert_selector "input[name='api_token[name]'][autofocus]"
    end

    test "renders form with errors when token has errors" do
      @token.errors.add(:name, "can't be blank")
      render_inline(TokenFormComponent.new(token: @token))

      # The Forms::ErrorsComponent should display errors
      assert_selector ".alert" # Error alert container
    end
  end
end
