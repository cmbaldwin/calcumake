# frozen_string_literal: true

module Mcp
  # Registers every MCP tool the user can invoke and dispatches calls to the
  # corresponding handler. Each tool mirrors a concrete capability of the
  # CalcuMake REST API so an AI agent can do anything the user can do.
  class ToolRegistry
    class ToolError < StandardError; end
    class UnknownToolError < ToolError; end
    class InvalidArgumentsError < ToolError; end

    attr_reader :user

    def initialize(user)
      @user = user
      @handlers = Tools.handlers
    end

    # Returns tool descriptors for tools/list.
    def list
      @handlers.map do |name, handler|
        {
          name: name,
          description: handler[:description],
          inputSchema: handler[:input_schema]
        }
      end
    end

    # Executes a tool and returns the MCP `content`/`isError` structure.
    def call(name, arguments)
      handler = @handlers[name]
      raise UnknownToolError, "Unknown tool: #{name}" unless handler

      args = arguments.is_a?(Hash) ? arguments.deep_stringify_keys : {}
      result = handler[:run].call(user, args)
      Tools.text_result(result)
    rescue ActiveRecord::RecordNotFound => e
      raise ToolError, "Not found: #{e.message}"
    rescue ActiveRecord::RecordInvalid => e
      raise ToolError, "Validation failed: #{e.record.errors.full_messages.join('; ')}"
    rescue ActionController::ParameterMissing => e
      raise InvalidArgumentsError, "Missing required argument: #{e.param}"
    rescue ArgumentError => e
      raise InvalidArgumentsError, e.message
    end
  end
end
