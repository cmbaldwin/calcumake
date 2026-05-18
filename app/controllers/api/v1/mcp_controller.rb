# frozen_string_literal: true

module Api
  module V1
    # Model Context Protocol (MCP) endpoint.
    #
    # Exposes a JSON-RPC 2.0 endpoint that lets AI agents perform any action a
    # CalcuMake user can perform via the REST API. Access is gated to paid
    # users (Startup, Pro, admins, and trial users with active access).
    #
    # Configure in an MCP-capable client (e.g. Claude Desktop / Claude Code)
    # with a remote HTTP transport pointing at:
    #   POST https://calcumake.com/api/v1/mcp
    #   Authorization: Bearer <api_token>
    class McpController < BaseController
      PAID_PLAN_REQUIRED_CODE = "paid_plan_required"

      before_action :authorize_paid_user!

      # Single JSON-RPC entry point. Handles:
      #   - initialize
      #   - notifications/initialized (no response)
      #   - tools/list
      #   - tools/call
      #   - ping
      def create
        payload = request_payload

        if payload.is_a?(Array)
          responses = payload.map { |msg| dispatch_jsonrpc(msg) }.compact
          render json: responses, status: :ok
        else
          response = dispatch_jsonrpc(payload)
          if response.nil?
            head :no_content
          else
            render json: response, status: :ok
          end
        end
      rescue JSON::ParserError
        render json: jsonrpc_error(nil, -32_700, "Parse error"), status: :bad_request
      end

      private

      def request_payload
        raw = request.raw_post
        raw.blank? ? {} : JSON.parse(raw)
      end

      def dispatch_jsonrpc(message)
        server = Mcp::Server.new(current_user, current_api_token)
        server.handle(message)
      end

      def jsonrpc_error(id, code, message, data = nil)
        error = { code: code, message: message }
        error[:data] = data if data
        { jsonrpc: "2.0", id: id, error: error }
      end

      def authorize_paid_user!
        return if current_user.blank? # BaseController already rendered 401
        return if paid_user?(current_user)

        render json: {
          errors: [ {
            status: "402",
            code: PAID_PLAN_REQUIRED_CODE,
            title: "Paid Plan Required",
            detail: "The MCP endpoint is available to Startup, Pro, and trial users. " \
                    "Upgrade your plan at https://calcumake.com/subscriptions/pricing to use AI agent access."
          } ]
        }, status: :payment_required
      end

      # A user has MCP access if they have an active paid subscription, are in
      # their trial window, or are an admin. Free-plan users (post-trial) are
      # denied.
      def paid_user?(user)
        return true if user.admin?
        return true if user.in_trial_period?
        return true if user.pro_plan? || user.startup_plan?

        false
      end
    end
  end
end
