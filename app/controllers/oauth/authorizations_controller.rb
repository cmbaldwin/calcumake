# frozen_string_literal: true

module OAuth
  # Handles the OAuth 2.1 Authorization Code flow (with PKCE).
  #
  # GET  /oauth/authorize  — Show authorization consent page
  # POST /oauth/authorize  — User approves or denies
  class AuthorizationsController < ApplicationController
    before_action :authenticate_user!
    before_action :validate_oauth_params, only: :new

    ALLOWED_CLIENT_IDS = [ "mcp" ].freeze

    # GET /oauth/authorize
    def new
      # Params already validated; store them in session so POST can retrieve them
      session[:oauth_params] = {
        "client_id"             => params[:client_id],
        "redirect_uri"          => params[:redirect_uri],
        "state"                 => params[:state],
        "code_challenge"        => params[:code_challenge],
        "code_challenge_method" => params[:code_challenge_method] || "S256",
        "scope"                 => params[:scope] || "mcp"
      }
    end

    # POST /oauth/authorize
    def create
      oauth = session.delete(:oauth_params) || {}

      if params[:approved] != "true"
        # User denied access — redirect with error
        return redirect_to_uri(oauth["redirect_uri"], oauth["state"],
                               error: "access_denied", error_description: "User denied access")
      end

      auth_code = OAuthAuthorizationCode.create!(
        user:                 current_user,
        redirect_uri:         oauth["redirect_uri"],
        client_id:            oauth["client_id"],
        state:                oauth["state"],
        code_challenge:       oauth["code_challenge"],
        code_challenge_method: oauth["code_challenge_method"] || "S256",
        scope:                oauth["scope"] || "mcp"
      )

      redirect_to_uri(oauth["redirect_uri"], oauth["state"], code: auth_code.code)
    end

    private

    def validate_oauth_params
      errors = []
      errors << "unsupported_response_type" if params[:response_type] != "code"
      errors << "invalid_client"            unless ALLOWED_CLIENT_IDS.include?(params[:client_id])
      errors << "invalid_request: redirect_uri is required" if params[:redirect_uri].blank?
      errors << "invalid_request: code_challenge is required (PKCE required)" if params[:code_challenge].blank?

      unless valid_redirect_uri?(params[:redirect_uri])
        errors << "invalid_request: redirect_uri must be HTTPS or localhost"
      end

      if errors.any?
        render plain: "OAuth error: #{errors.join(', ')}", status: :bad_request
      end
    end

    def valid_redirect_uri?(uri)
      return false if uri.blank?

      parsed = URI.parse(uri)
      parsed.scheme == "https" ||
        (parsed.scheme == "http" && %w[localhost 127.0.0.1].include?(parsed.host))
    rescue URI::InvalidURIError
      false
    end

    def redirect_to_uri(redirect_uri, state, **query_params)
      uri = URI.parse(redirect_uri)
      existing = URI.decode_www_form(uri.query || "").to_h
      merged   = existing.merge(query_params.transform_values(&:to_s))
      merged["state"] = state if state.present?
      uri.query = URI.encode_www_form(merged)
      redirect_to uri.to_s, allow_other_host: true
    end
  end
end
