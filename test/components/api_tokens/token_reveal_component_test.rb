# frozen_string_literal: true

require "test_helper"

module ApiTokens
  class TokenRevealComponentTest < ViewComponent::TestCase
    setup do
      @user = users(:one)
      @token = @user.api_tokens.create!(name: "Test Reveal Token")
      @plain_token = @token.plain_token
    end

    test "renders component with token and plain_token" do
      render_inline(TokenRevealComponent.new(token: @token, plain_token: @plain_token))

      assert_selector ".card.border-warning"
    end

    test "displays warning header" do
      render_inline(TokenRevealComponent.new(token: @token, plain_token: @plain_token))

      assert_selector ".card-header.bg-warning", text: /Your New API Token/i
    end

    test "displays security warning alert" do
      render_inline(TokenRevealComponent.new(token: @token, plain_token: @plain_token))

      assert_selector ".alert.alert-danger", text: /Copy this token now/i
    end

    test "displays warning detail" do
      render_inline(TokenRevealComponent.new(token: @token, plain_token: @plain_token))

      assert_selector ".alert.alert-danger", text: /you won't be able to see it again/i
    end

    test "displays plain token" do
      render_inline(TokenRevealComponent.new(token: @token, plain_token: @plain_token))

      assert_selector "[data-api-token-target='tokenDisplay']", text: @plain_token
    end

    test "renders copy button" do
      render_inline(TokenRevealComponent.new(token: @token, plain_token: @plain_token))

      assert_selector "button[data-action='click->api-token#copy']", text: /Copy/i
    end

    test "displays auto-hide notice" do
      render_inline(TokenRevealComponent.new(token: @token, plain_token: @plain_token))

      assert_selector ".alert.alert-info", text: /hidden automatically/i
    end

    test "includes Stimulus controller data attributes" do
      render_inline(TokenRevealComponent.new(token: @token, plain_token: @plain_token))

      assert_selector "[data-controller='api-token']"
      assert_selector "[data-api-token-revealed-value='true']"
    end

    test "includes reveal section target" do
      render_inline(TokenRevealComponent.new(token: @token, plain_token: @plain_token))

      assert_selector "[data-api-token-target='revealSection']"
    end

    test "token display has monospace font" do
      render_inline(TokenRevealComponent.new(token: @token, plain_token: @plain_token))

      assert_selector "code.font-monospace", text: @plain_token
    end

    test "token display allows text selection" do
      render_inline(TokenRevealComponent.new(token: @token, plain_token: @plain_token))

      assert_selector "code.user-select-all", text: @plain_token
    end

    test "copy button has correct target" do
      render_inline(TokenRevealComponent.new(token: @token, plain_token: @plain_token))

      assert_selector "button[data-api-token-target='copyButton']"
    end

    test "renders your token label" do
      render_inline(TokenRevealComponent.new(token: @token, plain_token: @plain_token))

      assert_selector "label.form-label.fw-bold", text: /Your Token/i
    end
  end
end
