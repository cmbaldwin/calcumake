# frozen_string_literal: true

module OAuth
  # Handles OAuth 2.1 token issuance and revocation.
  #
  # POST /oauth/token   — Exchange auth code for Bearer token
  # POST /oauth/revoke  — Revoke a Bearer token
  class TokensController < ApplicationController
    skip_before_action :verify_authenticity_token

    # POST /oauth/token
    def create
      validate_grant_type!

      auth_code = find_and_validate_auth_code!

      # Verify PKCE
      auth_code.verify_pkce!(params[:code_verifier].to_s)

      # Mark code as used (single-use)
      auth_code.mark_used!

      # Issue an ApiToken — reuses the same token infrastructure as the REST API
      api_token = auth_code.user.api_tokens.create!(name: "MCP OAuth (#{auth_code.client_id})")

      render json: {
        access_token: api_token.plain_token,
        token_type:   "bearer",
        expires_in:   ApiToken::EXPIRATION_OPTIONS[ApiToken::DEFAULT_EXPIRATION]&.to_i,
        scope:        auth_code.scope
      }
    rescue OAuthError => e
      render json: { error: e.error_code, error_description: e.message }, status: :bad_request
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: "server_error", error_description: e.message }, status: :internal_server_error
    end

    # POST /oauth/revoke
    def revoke
      token_value = params[:token].to_s
      return head :ok if token_value.blank?

      api_token = ApiToken.authenticate(token_value)
      api_token&.revoke!

      head :ok
    end

    private

    def validate_grant_type!
      return if params[:grant_type] == "authorization_code"

      raise OAuthError.new("unsupported_grant_type", error_code: "unsupported_grant_type")
    end

    def find_and_validate_auth_code!
      code = params[:code].to_s
      raise OAuthError.new("code is required", error_code: "invalid_request") if code.blank?

      redirect_uri = params[:redirect_uri].to_s
      raise OAuthError.new("redirect_uri is required", error_code: "invalid_request") if redirect_uri.blank?

      auth_code = OAuthAuthorizationCode.find_active(code)
      raise OAuthError.new("Authorization code is invalid or expired", error_code: "invalid_grant") unless auth_code

      unless auth_code.redirect_uri == redirect_uri
        raise OAuthError.new("redirect_uri mismatch", error_code: "invalid_grant")
      end

      unless auth_code.client_id == params[:client_id].to_s
        raise OAuthError.new("client_id mismatch", error_code: "invalid_client")
      end

      auth_code
    end
  end
end
