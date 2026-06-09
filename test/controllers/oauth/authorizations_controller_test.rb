# frozen_string_literal: true

require "test_helper"

module OAuth
  class AuthorizationsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:one)
      sign_in @user
    end

    # --- GET /oauth/authorize -------------------------------------------------

    test "shows authorization form with valid params" do
      get oauth_authorize_url, params: valid_params
      assert_response :success
    end

    test "stores oauth params in session" do
      get oauth_authorize_url, params: valid_params
      assert_equal valid_params[:client_id], session[:oauth_params]["client_id"]
      assert_equal valid_params[:redirect_uri], session[:oauth_params]["redirect_uri"]
    end

    test "requires authentication — redirects to sign in" do
      sign_out @user
      get oauth_authorize_url, params: valid_params
      assert_response :redirect
      assert_redirected_to new_user_session_path
    end

    test "rejects unsupported response_type" do
      get oauth_authorize_url, params: valid_params.merge(response_type: "token")
      assert_response :bad_request
    end

    test "rejects unknown client_id" do
      get oauth_authorize_url, params: valid_params.merge(client_id: "unknown_client")
      assert_response :bad_request
    end

    test "rejects missing redirect_uri" do
      get oauth_authorize_url, params: valid_params.except(:redirect_uri)
      assert_response :bad_request
    end

    test "rejects missing code_challenge" do
      get oauth_authorize_url, params: valid_params.except(:code_challenge)
      assert_response :bad_request
    end

    test "rejects non-HTTPS redirect_uri (except localhost)" do
      get oauth_authorize_url, params: valid_params.merge(redirect_uri: "http://evil.com/cb")
      assert_response :bad_request
    end

    test "accepts localhost redirect_uri" do
      get oauth_authorize_url, params: valid_params.merge(redirect_uri: "http://localhost:4000/callback")
      assert_response :success
    end

    test "accepts 127.0.0.1 redirect_uri" do
      get oauth_authorize_url, params: valid_params.merge(redirect_uri: "http://127.0.0.1:8080/cb")
      assert_response :success
    end

    # --- POST /oauth/authorize — user approves --------------------------------

    test "creates auth code and redirects when user approves" do
      get oauth_authorize_url, params: valid_params  # seed session

      assert_difference("OAuthAuthorizationCode.count") do
        post oauth_authorize_url, params: { approved: "true" }
      end

      assert_response :redirect
      redirect_uri = response.location
      assert_includes redirect_uri, valid_params[:redirect_uri]
      assert_match(/code=/, redirect_uri)
      assert_match(/state=#{valid_params[:state]}/, redirect_uri)
    end

    test "redirects with access_denied when user denies" do
      get oauth_authorize_url, params: valid_params

      assert_no_difference("OAuthAuthorizationCode.count") do
        post oauth_authorize_url, params: { approved: "false" }
      end

      assert_response :redirect
      assert_includes response.location, "error=access_denied"
    end

    test "created auth code belongs to current user" do
      get oauth_authorize_url, params: valid_params
      post oauth_authorize_url, params: { approved: "true" }

      code = OAuthAuthorizationCode.last
      assert_equal @user, code.user
    end

    test "created auth code stores the redirect_uri" do
      get oauth_authorize_url, params: valid_params
      post oauth_authorize_url, params: { approved: "true" }

      code = OAuthAuthorizationCode.last
      assert_equal valid_params[:redirect_uri], code.redirect_uri
    end

    test "created auth code stores the code_challenge" do
      get oauth_authorize_url, params: valid_params
      post oauth_authorize_url, params: { approved: "true" }

      code = OAuthAuthorizationCode.last
      assert_equal valid_params[:code_challenge], code.code_challenge
    end

    private

    def valid_params
      {
        response_type: "code",
        client_id:     "mcp",
        redirect_uri:  "https://example.com/callback",
        code_challenge: Base64.urlsafe_encode64(
          Digest::SHA256.digest("test_verifier_for_auth_controller"),
          padding: false
        ),
        code_challenge_method: "S256",
        state: "test_state_abc123"
      }
    end

    def sign_in(user)
      post user_session_path, params: {
        user: { email: user.email, password: "password123" }
      }
    end

    def sign_out(user)
      delete destroy_user_session_path
    end
  end
end
