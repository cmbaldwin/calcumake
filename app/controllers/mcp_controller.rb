# frozen_string_literal: true

# MCP (Model Context Protocol) server endpoint.
#
# Implements the MCP 2024-11-05 specification over HTTP transport.
# All requests use JSON-RPC 2.0 via POST /mcp.
#
# Authentication: Bearer token (same ApiToken used by /api/v1).
# Unauthenticated requests receive a 401 with discovery headers so clients
# can initiate the OAuth 2.1 PKCE flow at /oauth/authorize.
#
# Supported methods:
#   initialize        - Handshake; returns server capabilities
#   ping              - Keep-alive / health check
#   tools/list        - Returns all available tool definitions
#   tools/call        - Executes a tool
#   notifications/*   - Accepted silently (no response)
class McpController < ApplicationController
  include ActionController::HttpAuthentication::Token::ControllerMethods

  skip_before_action :verify_authenticity_token
  before_action :parse_json_body, only: :handle
  before_action :authenticate!, only: :handle

  MCP_VERSION    = "2024-11-05"
  SERVER_NAME    = "CalcuMake MCP"
  SERVER_VERSION = "1.0"

  # POST /mcp
  def handle
    if @body.is_a?(Array)
      results = @body.filter_map { |req| process_request(req) }
      render json: results
    else
      result = process_request(@body)
      result ? render(json: result) : head(:no_content)
    end
  end

  # GET /mcp/schema
  # Returns the full JSON Schema for all MCP tools. Useful for AI agents
  # that want to discover capabilities without a full MCP handshake.
  def schema
    render json: {
      schema_version: "1.0",
      server: { name: SERVER_NAME, version: SERVER_VERSION },
      protocol_version: MCP_VERSION,
      tools: Mcp::Tools.definitions,
      authentication: {
        type: "oauth2",
        flows: {
          authorization_code: {
            authorization_url: "#{request.base_url}/oauth/authorize",
            token_url: "#{request.base_url}/oauth/token",
            scopes: { mcp: "Full MCP access" }
          }
        },
        bearer_token_url: "#{request.base_url}/api_tokens/new"
      },
      documentation_url: "#{request.base_url}/docs/mcp"
    }
  end

  private

  def parse_json_body
    @body = JSON.parse(request.body.read)
  rescue JSON::ParserError
    render json: jsonrpc_error(nil, -32700, "Parse error"), status: :bad_request
  end

  def authenticate!
    authenticate_with_http_token do |token, _|
      api_token = ApiToken.authenticate(token)
      if api_token
        @current_user = api_token.user
        return
      end
    end

    # Allow initialize and ping without auth so the client can discover the server
    # and determine it needs to authenticate before proceeding.
    methods_without_auth = %w[initialize ping]
    req     = @body.is_a?(Array) ? @body.first : @body
    method  = req.is_a?(Hash) ? req["method"] : nil

    return if methods_without_auth.include?(method)

    response.headers["WWW-Authenticate"] =
      'Bearer realm="CalcuMake", resource_metadata_uri="/.well-known/oauth-protected-resource"'

    id = req.is_a?(Hash) ? req["id"] : nil
    render json: jsonrpc_error(id, -32001, "Authentication required. " \
      "Obtain a Bearer token via /api_tokens or the OAuth flow at /oauth/authorize."),
           status: :unauthorized
  end

  def process_request(req)
    return nil unless req.is_a?(Hash)

    method  = req["method"]
    params  = req["params"] || {}
    id      = req["id"]

    # Notifications have no id and require no response
    return nil if id.nil? && method.to_s.start_with?("notifications/")

    case method
    when "initialize"    then handle_initialize(id, params)
    when "ping"          then handle_ping(id)
    when "tools/list"    then handle_tools_list(id)
    when "tools/call"    then handle_tools_call(id, params)
    else jsonrpc_error(id, -32601, "Method not found: #{method}")
    end
  rescue StandardError => e
    jsonrpc_error(req["id"], -32603, "Internal error: #{e.message}")
  end

  def handle_initialize(id, params)
    client_version = params.dig("protocolVersion")
    {
      jsonrpc: "2.0",
      id: id,
      result: {
        protocolVersion: MCP_VERSION,
        capabilities: { tools: { listChanged: false } },
        serverInfo: { name: SERVER_NAME, version: SERVER_VERSION },
        instructions: "CalcuMake MCP Server for 3D print project management. " \
          "Use tools/list to discover available tools. " \
          "Authenticate via Bearer token from #{request.base_url}/api_tokens " \
          "or the OAuth 2.1 flow at #{request.base_url}/oauth/authorize. " \
          "Full documentation: #{request.base_url}/docs/mcp",
        _meta: { clientProtocolVersion: client_version }
      }
    }
  end

  def handle_ping(id)
    { jsonrpc: "2.0", id: id, result: {} }
  end

  def handle_tools_list(id)
    {
      jsonrpc: "2.0",
      id: id,
      result: { tools: Mcp::Tools.definitions }
    }
  end

  def handle_tools_call(id, params)
    name      = params["name"]
    arguments = params["arguments"] || {}

    return jsonrpc_error(id, -32602, "Invalid params: 'name' is required") if name.blank?

    result = Mcp::Tools.call(name, arguments, user: @current_user)

    { jsonrpc: "2.0", id: id, result: result }
  rescue Mcp::Tools::ToolNotFoundError => e
    jsonrpc_error(id, -32601, e.message)
  rescue Mcp::Tools::ToolError => e
    {
      jsonrpc: "2.0",
      id: id,
      result: { content: [ { type: "text", text: "Error: #{e.message}" } ], isError: true }
    }
  end

  def jsonrpc_error(id, code, message)
    { jsonrpc: "2.0", id: id, error: { code: code, message: message } }
  end
end
