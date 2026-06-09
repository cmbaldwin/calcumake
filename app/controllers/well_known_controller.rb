# frozen_string_literal: true

# Serves OAuth 2.1 discovery documents per RFC 8414 and the MCP spec.
# These endpoints let MCP clients auto-discover authentication requirements.
class WellKnownController < ApplicationController
  skip_before_action :verify_authenticity_token

  # GET /.well-known/oauth-protected-resource
  # RFC 9728 — tells clients where to find the auth server for this resource.
  def oauth_protected_resource
    render json: {
      resource: "#{request.base_url}/mcp",
      authorization_servers: [ request.base_url ],
      bearer_methods_supported: [ "header" ],
      scopes_supported: [ "mcp" ],
      resource_documentation: "#{request.base_url}/docs/mcp"
    }
  end

  # GET /.well-known/oauth-authorization-server
  # RFC 8414 — OAuth Authorization Server Metadata.
  def oauth_authorization_server
    base = request.base_url
    render json: {
      issuer: base,
      authorization_endpoint: "#{base}/oauth/authorize",
      token_endpoint: "#{base}/oauth/token",
      revocation_endpoint: "#{base}/oauth/revoke",
      response_types_supported: [ "code" ],
      grant_types_supported: [ "authorization_code" ],
      code_challenge_methods_supported: [ "S256" ],
      token_endpoint_auth_methods_supported: [ "none" ],
      scopes_supported: [ "mcp" ],
      service_documentation: "#{base}/docs/mcp"
    }
  end
end
