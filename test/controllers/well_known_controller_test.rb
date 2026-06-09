# frozen_string_literal: true

require "test_helper"

class WellKnownControllerTest < ActionDispatch::IntegrationTest
  test "oauth_protected_resource returns valid metadata" do
    get "/.well-known/oauth-protected-resource"
    assert_response :success
    json = JSON.parse(response.body)
    assert json["resource"].present?
    assert json["authorization_servers"].is_a?(Array)
    assert_includes json["bearer_methods_supported"], "header"
    assert_includes json["scopes_supported"], "mcp"
    assert json["resource_documentation"].present?
  end

  test "oauth_authorization_server returns valid metadata" do
    get "/.well-known/oauth-authorization-server"
    assert_response :success
    json = JSON.parse(response.body)
    assert json["issuer"].present?
    assert json["authorization_endpoint"].include?("/oauth/authorize")
    assert json["token_endpoint"].include?("/oauth/token")
    assert json["revocation_endpoint"].include?("/oauth/revoke")
    assert_includes json["response_types_supported"], "code"
    assert_includes json["grant_types_supported"], "authorization_code"
    assert_includes json["code_challenge_methods_supported"], "S256"
    assert_includes json["token_endpoint_auth_methods_supported"], "none"
  end

  test "oauth_authorization_server indicates PKCE is required" do
    get "/.well-known/oauth-authorization-server"
    json = JSON.parse(response.body)
    assert_includes json["code_challenge_methods_supported"], "S256"
    assert_includes json["token_endpoint_auth_methods_supported"], "none"
  end
end
