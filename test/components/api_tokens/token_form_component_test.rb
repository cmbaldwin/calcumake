# frozen_string_literal: true

require "test_helper"

module ApiTokens
  class TokenFormComponentTest < ViewComponent::TestCase
    include Rails.application.routes.url_helpers

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

      assert_selector "a[href='#{api_tokens_path}']", text: /Cancel/i
    end

    test "expiration select has correct number of options" do
      render_inline(TokenFormComponent.new(token: @token))

      # Should have 4 options for 30_days, 90_days, 1_year, never
      assert_selector "select[name='api_token[expiration]'] option", count: 4
    end

    test "expiration select includes all expiration values" do
      render_inline(TokenFormComponent.new(token: @token))

      # Check that all expected values are present as option values
      ApiToken::EXPIRATION_OPTIONS.keys.each do |key|
        assert_selector "select[name='api_token[expiration]'] option[value='#{key}']"
      end
    end

    test "form does not include turbo frame attribute" do
      render_inline(TokenFormComponent.new(token: @token))

      # Form should NOT have turbo-frame attribute since we're using redirect flow
      assert_no_selector "form[data-turbo-frame='api_tokens_list']"
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
