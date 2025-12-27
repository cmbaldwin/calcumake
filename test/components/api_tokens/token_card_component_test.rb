# frozen_string_literal: true

require "test_helper"

module ApiTokens
  class TokenCardComponentTest < ViewComponent::TestCase
    setup do
      @user = users(:one)
      @active_token = api_tokens(:active_token)
      @expired_token = api_tokens(:expired_token)
      @revoked_token = api_tokens(:revoked_token)
      @never_expires_token = api_tokens(:never_expires_token)
    end

    test "renders token name" do
      render_inline(TokenCardComponent.new(token: @active_token))

      assert_selector "h5.card-title", text: @active_token.name
    end

    test "renders token hint" do
      render_inline(TokenCardComponent.new(token: @active_token))

      assert_selector "code", text: @active_token.token_hint
    end

    test "renders active badge for active token" do
      render_inline(TokenCardComponent.new(token: @active_token))

      assert_selector "span.badge.bg-success", text: /Active/i
    end

    test "renders expired badge for expired token" do
      render_inline(TokenCardComponent.new(token: @expired_token))

      assert_selector "span.badge.bg-warning", text: /Expired/i
    end

    test "renders revoked badge for revoked token" do
      render_inline(TokenCardComponent.new(token: @revoked_token))

      assert_selector "span.badge.bg-danger", text: /Revoked/i
    end

    test "renders revoke button for active token" do
      render_inline(TokenCardComponent.new(token: @active_token))

      assert_selector "form[action*='#{@active_token.id}']"
      assert_selector "button", text: /Revoke/i
    end

    test "does not render revoke button for revoked token" do
      render_inline(TokenCardComponent.new(token: @revoked_token))

      assert_no_selector "button", text: /Revoke/i
    end

    test "does not render revoke button for expired token" do
      render_inline(TokenCardComponent.new(token: @expired_token))

      assert_no_selector "button", text: /Revoke/i
    end

    test "renders created date" do
      render_inline(TokenCardComponent.new(token: @active_token))

      assert_selector ".text-muted.small", text: /Created/i
    end

    test "renders expires date for token with expiration" do
      render_inline(TokenCardComponent.new(token: @active_token))

      assert_selector ".text-muted.small", text: /Expires/i
    end

    test "renders never expires for token without expiration" do
      render_inline(TokenCardComponent.new(token: @never_expires_token))

      assert_selector ".text-muted.small", text: /Never expires/i
    end

    test "renders expired on date for expired token" do
      render_inline(TokenCardComponent.new(token: @expired_token))

      assert_selector ".text-muted.small", text: /Expired/i
    end

    test "renders never used for token with no last_used_at" do
      @active_token.update_column(:last_used_at, nil)
      render_inline(TokenCardComponent.new(token: @active_token))

      assert_selector ".text-muted.small", text: /Never used/i
    end

    test "renders last used time for token with last_used_at" do
      @active_token.update_column(:last_used_at, 1.hour.ago)
      render_inline(TokenCardComponent.new(token: @active_token))

      assert_selector ".text-muted.small", text: /Last used/i
    end

    test "wraps card in turbo frame" do
      render_inline(TokenCardComponent.new(token: @active_token))

      assert_selector "turbo-frame[id='api_token_#{@active_token.id}']"
    end

    test "includes confirm dialog on revoke button" do
      render_inline(TokenCardComponent.new(token: @active_token))

      assert_selector "form[data-turbo-confirm]"
    end
  end
end
