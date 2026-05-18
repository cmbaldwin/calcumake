# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class McpControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        # Put the user firmly on the Pro plan with no trial leak so paid-tier
        # gating is unambiguous.
        @user.update_columns(plan: "pro", trial_ends_at: nil)

        @other_user = users(:two)
        @token = @user.api_tokens.create!(name: "MCP Test Token")
        @plain_token = @token.plain_token

        @printer = printers(:one)
      end

      # ============================================================
      # Authentication & paid-plan gating
      # ============================================================

      test "MCP requires authentication" do
        post api_v1_mcp_url, params: rpc("tools/list").to_json, headers: { "Content-Type" => "application/json" }
        assert_response :unauthorized
      end

      test "MCP rejects free-plan users with 402" do
        @user.update_columns(plan: "free", trial_ends_at: nil)

        post_rpc rpc("tools/list")
        assert_response :payment_required
        json = JSON.parse(response.body)
        assert_equal "paid_plan_required", json["errors"].first["code"]
      end

      test "MCP allows trial users (free plan, active trial)" do
        @user.update_columns(plan: "free", trial_ends_at: 7.days.from_now)

        post_rpc rpc("tools/list")
        assert_response :success
      end

      test "MCP allows startup-plan users" do
        @user.update_columns(plan: "startup", trial_ends_at: nil)

        post_rpc rpc("tools/list")
        assert_response :success
      end

      test "MCP allows pro-plan users" do
        post_rpc rpc("tools/list")
        assert_response :success
      end

      test "MCP allows admin users regardless of plan" do
        @user.update_columns(plan: "free", trial_ends_at: nil, admin: true)

        post_rpc rpc("tools/list")
        assert_response :success
      end

      # ============================================================
      # JSON-RPC protocol
      # ============================================================

      test "initialize returns server info and protocol version" do
        post_rpc rpc("initialize", params: { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "test", version: "1.0" } })

        assert_response :success
        json = JSON.parse(response.body)
        assert_equal "2.0", json["jsonrpc"]
        assert_equal 1, json["id"]
        assert_equal "2025-06-18", json["result"]["protocolVersion"]
        assert_equal "calcumake-mcp", json["result"]["serverInfo"]["name"]
        assert json["result"]["capabilities"]["tools"]
      end

      test "initialize falls back to default protocol version when client version is unknown" do
        post_rpc rpc("initialize", params: { protocolVersion: "1999-01-01" })

        json = JSON.parse(response.body)
        assert_equal Mcp::Server::DEFAULT_PROTOCOL_VERSION, json["result"]["protocolVersion"]
      end

      test "tools/list returns all registered tools with schemas" do
        post_rpc rpc("tools/list")

        assert_response :success
        json = JSON.parse(response.body)
        tools = json["result"]["tools"]

        assert tools.is_a?(Array)
        assert_equal Mcp::Tools.handlers.size, tools.length
        assert tools.all? { |t| t.key?("name") && t.key?("description") && t.key?("inputSchema") }

        names = tools.map { |t| t["name"] }
        %w[get_profile list_printers create_printer list_filaments create_print_pricing
           list_clients duplicate_print_pricing search_materials search_printer_profiles].each do |expected|
          assert_includes names, expected, "expected #{expected} in tool list"
        end
      end

      test "ping returns empty result" do
        post_rpc rpc("ping")
        json = JSON.parse(response.body)
        assert_equal({}, json["result"])
      end

      test "notifications/initialized returns 204 (no body)" do
        post api_v1_mcp_url,
             params: { jsonrpc: "2.0", method: "notifications/initialized" }.to_json,
             headers: auth_headers
        assert_response :no_content
      end

      test "unknown method returns method-not-found error" do
        post_rpc rpc("garbage/method")

        json = JSON.parse(response.body)
        assert_equal(-32_601, json["error"]["code"])
      end

      test "invalid JSON body returns parse error" do
        post api_v1_mcp_url, params: "{not json", headers: auth_headers
        assert_response :bad_request
        json = JSON.parse(response.body)
        assert_equal(-32_700, json["error"]["code"])
      end

      test "batch requests return array of responses" do
        body = [ rpc("ping", id: 1), rpc("tools/list", id: 2) ]
        post api_v1_mcp_url, params: body.to_json, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)
        assert json.is_a?(Array)
        assert_equal 2, json.length
        assert_equal 1, json[0]["id"]
        assert_equal 2, json[1]["id"]
      end

      # ============================================================
      # tools/call - account
      # ============================================================

      test "get_profile returns the authenticated user's data" do
        result = call_tool("get_profile")
        data = parse_tool_result(result)

        assert_equal @user.email, data["email"]
        assert_equal "pro", data["plan"]
        assert_equal @user.default_currency, data["default_currency"]
      end

      test "update_profile updates the authenticated user" do
        call_tool("update_profile", { default_currency: "JPY", default_energy_cost_per_kwh: 0.30 })

        @user.reload
        assert_equal "JPY", @user.default_currency
        assert_in_delta 0.30, @user.default_energy_cost_per_kwh.to_f, 0.001
      end

      test "get_usage_stats returns counts and limits" do
        result = call_tool("get_usage_stats")
        data = parse_tool_result(result)

        assert data["counts"].key?("printers")
        assert_equal "unlimited", data["limits"]["printers"]
      end

      # ============================================================
      # tools/call - printers (full CRUD via MCP)
      # ============================================================

      test "list_printers returns only the user's printers" do
        result = call_tool("list_printers")
        data = parse_tool_result(result)

        ids = data["printers"].map { |p| p["id"] }
        assert_includes ids, @printer.id.to_s
        refute_includes ids, printers(:two).id.to_s
      end

      test "list_printers filters by technology" do
        result = call_tool("list_printers", { technology: "fdm" })
        data = parse_tool_result(result)

        assert data["printers"].all? { |p| p["material_technology"] == "fdm" }
      end

      test "get_printer returns a single printer" do
        result = call_tool("get_printer", { id: @printer.id.to_s })
        data = parse_tool_result(result)

        assert_equal @printer.id.to_s, data["id"]
        assert_equal @printer.name, data["name"]
      end

      test "get_printer returns isError for another user's printer" do
        result = call_tool("get_printer", { id: printers(:two).id.to_s })
        assert result["isError"]
      end

      test "create_printer creates a new printer" do
        assert_difference("Printer.count", 1) do
          result = call_tool("create_printer", {
            name: "MCP-built printer",
            manufacturer: "Anycubic",
            material_technology: "fdm",
            power_consumption: 120,
            cost: 350,
            payoff_goal_years: 2,
            daily_usage_hours: 6
          })
          refute result["isError"], result["content"].first["text"] if result["isError"]
        end
        printer = Printer.last
        assert_equal @user.id, printer.user_id
        assert_equal "MCP-built printer", printer.name
      end

      test "create_printer surfaces validation errors as isError" do
        result = call_tool("create_printer", { name: "" })

        assert result["isError"]
        text = result["content"].first["text"]
        assert_match(/Validation failed/i, text)
      end

      test "update_printer modifies a printer" do
        call_tool("update_printer", { id: @printer.id.to_s, name: "Renamed via MCP" })

        @printer.reload
        assert_equal "Renamed via MCP", @printer.name
      end

      test "delete_printer destroys the printer" do
        assert_difference("Printer.count", -1) do
          result = call_tool("delete_printer", { id: @printer.id.to_s })
          refute result["isError"]
        end
      end

      # ============================================================
      # tools/call - filaments
      # ============================================================

      test "create_filament + duplicate_filament + delete_filament" do
        # create
        create_result = call_tool("create_filament", {
          name: "Hatchbox PLA",
          brand: "Hatchbox",
          material_type: "PLA",
          spool_weight: 1000,
          spool_price: 25.0
        })
        refute create_result["isError"], create_result["content"].first["text"]
        filament_id = parse_tool_result(create_result)["id"]

        # duplicate
        dup_result = call_tool("duplicate_filament", { id: filament_id })
        dup = parse_tool_result(dup_result)
        assert_equal "Hatchbox PLA (Copy)", dup["name"]

        # delete original
        del_result = call_tool("delete_filament", { id: filament_id })
        refute del_result["isError"]
        assert_raises(ActiveRecord::RecordNotFound) { @user.filaments.find(filament_id) }
      end

      test "list_filaments supports search and material_type filter" do
        @user.filaments.create!(name: "Special PETG", material_type: "PETG", spool_weight: 1000, spool_price: 30)

        result = call_tool("list_filaments", { material_type: "PETG" })
        data = parse_tool_result(result)
        assert data["filaments"].all? { |f| f["material_type"] == "PETG" }
      end

      # ============================================================
      # tools/call - clients
      # ============================================================

      test "client CRUD via MCP" do
        # create
        create = call_tool("create_client", { name: "Acme Corp", email: "ops@acme.example", company_name: "Acme" })
        refute create["isError"], create["content"].first["text"]
        client_id = parse_tool_result(create)["id"]

        # list - includes new client
        list = call_tool("list_clients")
        assert parse_tool_result(list)["clients"].any? { |c| c["id"] == client_id }

        # update
        upd = call_tool("update_client", { id: client_id, phone: "+1-555-0100" })
        assert_equal "+1-555-0100", parse_tool_result(upd)["phone"]

        # delete
        del = call_tool("delete_client", { id: client_id })
        refute del["isError"]
      end

      # ============================================================
      # tools/call - print pricings (the core domain object)
      # ============================================================

      test "create_print_pricing builds a job with nested plates and filaments" do
        filament = @user.filaments.create!(name: "PLA", material_type: "PLA", spool_weight: 1000, spool_price: 25)

        result = call_tool("create_print_pricing", {
          job_name: "Test job from MCP",
          printer_id: @printer.id.to_s,
          units: 10,
          plates: [ {
            material_technology: "fdm",
            printing_time_hours: 2,
            printing_time_minutes: 30,
            plate_filaments: [ { filament_id: filament.id.to_s, filament_weight: 50.0, markup_percentage: 10 } ]
          } ]
        })

        refute result["isError"], result["content"].first["text"]
        data = parse_tool_result(result)
        assert_equal "Test job from MCP", data["job_name"]
        assert_equal 1, data["plates"].length
        assert_equal 1, data["plates"][0]["filaments"].length
        assert_equal 50.0, data["plates"][0]["filaments"][0]["filament_weight"]
      end

      test "duplicate_print_pricing copies the entire job tree" do
        original = print_pricings(:one)
        result = call_tool("duplicate_print_pricing", { id: original.id.to_s })
        refute result["isError"], result["content"].first["text"]

        copy = parse_tool_result(result)
        assert_match(/\(Copy\)\z/, copy["job_name"])
        refute_equal original.id.to_s, copy["id"]
      end

      test "increment_times_printed bumps the counter" do
        pricing = print_pricings(:one)
        original_count = pricing.times_printed.to_i

        result = call_tool("increment_times_printed", { id: pricing.id.to_s })
        data = parse_tool_result(result)

        assert_equal original_count + 1, data["times_printed"]
      end

      test "list_plates_for_pricing returns plates" do
        pricing = print_pricings(:one)
        result = call_tool("list_plates_for_pricing", { print_pricing_id: pricing.id.to_s })
        data = parse_tool_result(result)

        assert data["plates"].is_a?(Array)
      end

      # ============================================================
      # tools/call - error handling
      # ============================================================

      test "calling unknown tool returns method-not-found JSON-RPC error" do
        post_rpc rpc("tools/call", params: { name: "nonexistent_tool", arguments: {} })

        json = JSON.parse(response.body)
        assert_equal(-32_601, json["error"]["code"])
      end

      test "missing tool name returns invalid-params" do
        post_rpc rpc("tools/call", params: { arguments: {} })
        json = JSON.parse(response.body)
        assert_equal(-32_602, json["error"]["code"])
      end

      test "calling a tool without required argument returns isError content" do
        result = call_tool("get_printer", {}) # missing :id
        assert result["isError"]
      end

      private

      def auth_headers
        { "Authorization" => "Bearer #{@plain_token}", "Content-Type" => "application/json" }
      end

      def rpc(method, id: 1, params: nil)
        msg = { jsonrpc: "2.0", id: id, method: method }
        msg[:params] = params if params
        msg
      end

      def post_rpc(message)
        post api_v1_mcp_url, params: message.to_json, headers: auth_headers
      end

      # Calls a tool via the JSON-RPC endpoint and returns the unwrapped
      # tool result (the `result` field from the JSON-RPC response).
      def call_tool(name, arguments = {})
        post_rpc rpc("tools/call", params: { name: name, arguments: arguments })
        json = JSON.parse(response.body)
        json["result"] || raise("MCP error: #{json['error'].inspect}")
      end

      # Tools return their data as JSON-formatted text inside content[0].text;
      # this helper unwraps and parses that.
      def parse_tool_result(tool_result)
        text = tool_result["content"].first["text"]
        JSON.parse(text)
      end
    end
  end
end
