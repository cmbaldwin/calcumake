# frozen_string_literal: true

require "test_helper"

module OAuth
  class TokensControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user     = users(:one)
      @verifier = "test_pkce_verifier_secure_random_abc123"
      @challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(@verifier), padding: false)

      @auth_code = OAuthAuthorizationCode.create!(
        user:                  @user,
        redirect_uri:          "https://example.com/callback",
        client_id:             "mcp",
        code_challenge:        @challenge,
        code_challenge_method: "S256",
        state:                 "state_xyz"
      )
    end

    # --- POST /oauth/token — success -----------------------------------------

    test "issues an access token for a valid auth code" do
      assert_difference("ApiToken.count") do
        post oauth_token_url, params: valid_token_params
      end

      assert_response :success
      json = JSON.parse(response.body)
      assert json["access_token"].present?
      assert_equal "bearer", json["token_type"]
      assert json["expires_in"].present?
    end

    test "returned token starts with cm_ prefix" do
      post oauth_token_url, params: valid_token_params
      json = JSON.parse(response.body)
      assert_match(/\Acm_/, json["access_token"])
    end

    test "issued token can authenticate MCP requests" do
      post oauth_token_url, params: valid_token_params
      json     = JSON.parse(response.body)
      token    = json["access_token"]

      api_token = ApiToken.authenticate(token)
      assert_equal @user, api_token.user
    end

    test "auth code is marked as used after token issuance" do
      post oauth_token_url, params: valid_token_params
      @auth_code.reload
      assert_not_nil @auth_code.used_at
    end

    # --- POST /oauth/token — errors -----------------------------------------

    test "returns invalid_grant for unknown code" do
      post oauth_token_url, params: valid_token_params.merge(code: "nonexistent_code")
      assert_response :bad_request
      json = JSON.parse(response.body)
      assert_equal "invalid_grant", json["error"]
    end

    test "returns invalid_grant for expired code" do
      expired = OAuthAuthorizationCode.create!(
        user:         @user,
        redirect_uri: "https://example.com/callback",
        client_id:    "mcp",
        expires_at:   5.minutes.ago
      )

      post oauth_token_url, params: valid_token_params.merge(code: expired.code)
      assert_response :bad_request
      json = JSON.parse(response.body)
      assert_equal "invalid_grant", json["error"]
    end

    test "returns invalid_grant for used code" do
      @auth_code.mark_used!
      post oauth_token_url, params: valid_token_params
      assert_response :bad_request
      json = JSON.parse(response.body)
      assert_equal "invalid_grant", json["error"]
    end

    test "returns invalid_grant for redirect_uri mismatch" do
      post oauth_token_url, params: valid_token_params.merge(redirect_uri: "https://other.com/cb")
      assert_response :bad_request
      json = JSON.parse(response.body)
      assert_equal "invalid_grant", json["error"]
    end

    test "returns invalid_client for client_id mismatch" do
      post oauth_token_url, params: valid_token_params.merge(client_id: "wrong_client")
      assert_response :bad_request
      json = JSON.parse(response.body)
      assert_equal "invalid_client", json["error"]
    end

    test "returns invalid_grant for wrong PKCE verifier" do
      post oauth_token_url, params: valid_token_params.merge(code_verifier: "wrong_verifier")
      assert_response :bad_request
      json = JSON.parse(response.body)
      assert_equal "invalid_grant", json["error"]
    end

    test "returns unsupported_grant_type for non-authorization_code grant" do
      post oauth_token_url, params: valid_token_params.merge(grant_type: "client_credentials")
      assert_response :bad_request
      json = JSON.parse(response.body)
      assert_equal "unsupported_grant_type", json["error"]
    end

    test "returns invalid_request when code is missing" do
      post oauth_token_url, params: valid_token_params.except(:code)
      assert_response :bad_request
      json = JSON.parse(response.body)
      assert_equal "invalid_request", json["error"]
    end

    test "returns invalid_request when redirect_uri is missing" do
      post oauth_token_url, params: valid_token_params.except(:redirect_uri)
      assert_response :bad_request
      json = JSON.parse(response.body)
      assert_equal "invalid_request", json["error"]
    end

    # --- POST /oauth/revoke ---------------------------------------------------

    test "revoke returns 200 for a valid token" do
      api_token = @user.api_tokens.create!(name: "Revoke Test")
      post oauth_revoke_url, params: { token: api_token.plain_token }
      assert_response :ok
    end

    test "revoke invalidates the token" do
      api_token = @user.api_tokens.create!(name: "Revoke Test 2")
      plain     = api_token.plain_token

      post oauth_revoke_url, params: { token: plain }
      assert_nil ApiToken.authenticate(plain)
    end

    test "revoke is idempotent — 200 for unknown token" do
      post oauth_revoke_url, params: { token: "cm_nonexistent_token" }
      assert_response :ok
    end

    test "revoke is idempotent — 200 with blank token" do
      post oauth_revoke_url, params: { token: "" }
      assert_response :ok
    end

    private

    def valid_token_params
      {
        grant_type:    "authorization_code",
        code:          @auth_code.code,
        redirect_uri:  "https://example.com/callback",
        client_id:     "mcp",
        code_verifier: @verifier
      }
    end
  end
end
