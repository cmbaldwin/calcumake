# frozen_string_literal: true

module Mcp
  # JSON-RPC 2.0 dispatcher for the Model Context Protocol.
  #
  # Speaks the subset of MCP needed to expose CalcuMake's API as an agent
  # toolbelt: initialize handshake, tools/list, tools/call, ping, plus the
  # notifications/initialized lifecycle notification.
  class Server
    SUPPORTED_PROTOCOL_VERSIONS = %w[2024-11-05 2025-03-26 2025-06-18].freeze
    DEFAULT_PROTOCOL_VERSION = "2025-06-18"
    SERVER_NAME = "calcumake-mcp"
    SERVER_VERSION = "1.0.0"

    JSONRPC_PARSE_ERROR = -32_700
    JSONRPC_INVALID_REQUEST = -32_600
    JSONRPC_METHOD_NOT_FOUND = -32_601
    JSONRPC_INVALID_PARAMS = -32_602
    JSONRPC_INTERNAL_ERROR = -32_603

    attr_reader :user, :api_token

    def initialize(user, api_token = nil)
      @user = user
      @api_token = api_token
    end

    # Returns a JSON-RPC response hash, or nil for notifications.
    def handle(message)
      return invalid_request(nil) unless message.is_a?(Hash)

      id = message["id"]
      method = message["method"]
      params = message["params"] || {}

      return invalid_request(id) if method.blank?

      # Notifications (no `id` field) must not be responded to.
      notification = !message.key?("id")

      case method
      when "initialize"
        success(id, initialize_result(params))
      when "notifications/initialized", "notifications/cancelled"
        nil # acknowledge silently
      when "ping"
        success(id, {})
      when "tools/list"
        success(id, { tools: registry.list })
      when "tools/call"
        handle_tool_call(id, params)
      when "resources/list"
        success(id, { resources: [] })
      when "prompts/list"
        success(id, { prompts: [] })
      else
        return nil if notification

        error(id, JSONRPC_METHOD_NOT_FOUND, "Method not found: #{method}")
      end
    rescue StandardError => e
      Rails.logger.error("[MCP] dispatch error: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
      error(message.is_a?(Hash) ? message["id"] : nil, JSONRPC_INTERNAL_ERROR, "Internal error: #{e.message}")
    end

    private

    def registry
      @registry ||= ToolRegistry.new(user)
    end

    def initialize_result(params)
      client_version = params["protocolVersion"]
      protocol_version = SUPPORTED_PROTOCOL_VERSIONS.include?(client_version) ? client_version : DEFAULT_PROTOCOL_VERSION

      {
        protocolVersion: protocol_version,
        capabilities: {
          tools: { listChanged: false },
          resources: {},
          prompts: {}
        },
        serverInfo: {
          name: SERVER_NAME,
          version: SERVER_VERSION
        },
        instructions: "CalcuMake MCP exposes 3D-print pricing, printers, materials, clients, " \
                      "and invoices for the authenticated user. Every action is scoped to that " \
                      "user's account. Use tools/list to discover the full toolset."
      }
    end

    def handle_tool_call(id, params)
      tool_name = params["name"]
      arguments = params["arguments"] || {}

      return error(id, JSONRPC_INVALID_PARAMS, "Missing tool name") if tool_name.blank?

      result = registry.call(tool_name, arguments)
      success(id, result)
    rescue ToolRegistry::UnknownToolError => e
      error(id, JSONRPC_METHOD_NOT_FOUND, e.message)
    rescue ToolRegistry::ToolError => e
      # Tool-level errors are reported in-band per MCP convention so the agent
      # can read them and respond, rather than aborting the JSON-RPC call.
      success(id, {
        content: [ { type: "text", text: e.message } ],
        isError: true
      })
    end

    def success(id, result)
      { jsonrpc: "2.0", id: id, result: result }
    end

    def error(id, code, message, data = nil)
      err = { code: code, message: message }
      err[:data] = data if data
      { jsonrpc: "2.0", id: id, error: err }
    end

    def invalid_request(id)
      error(id, JSONRPC_INVALID_REQUEST, "Invalid Request")
    end
  end
end
