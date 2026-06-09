# frozen_string_literal: true

require "test_helper"

class McpControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user  = users(:one)
    @token = @user.api_tokens.create!(name: "MCP Test")
    @plain = @token.plain_token
  end

  # ---------------------------------------------------------------------------
  # GET /mcp/schema — public, no auth
  # ---------------------------------------------------------------------------

  test "schema returns JSON without authentication" do
    get mcp_schema_url
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "CalcuMake MCP", json["server"]["name"]
    assert json["tools"].is_a?(Array)
    assert json["tools"].any? { |t| t["name"] == "health_check" }
  end

  test "schema includes authentication info" do
    get mcp_schema_url
    json = JSON.parse(response.body)
    assert json.key?("authentication")
    assert_equal "oauth2", json["authentication"]["type"]
  end

  # ---------------------------------------------------------------------------
  # POST /mcp — authentication
  # ---------------------------------------------------------------------------

  test "returns 401 without token" do
    post mcp_url, params: jsonrpc("tools/list", {}, 1), as: :json
    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal(-32001, json["error"]["code"])
  end

  test "returns 401 with invalid token" do
    post mcp_url,
         params: jsonrpc("tools/list", {}, 1),
         headers: bearer("cm_invalid_token_xyz"),
         as: :json
    assert_response :unauthorized
  end

  test "401 response includes WWW-Authenticate header" do
    post mcp_url, params: jsonrpc("tools/list", {}, 1), as: :json
    assert_includes response.headers["WWW-Authenticate"],
                    "oauth-protected-resource"
  end

  # ---------------------------------------------------------------------------
  # initialize — allowed without auth
  # ---------------------------------------------------------------------------

  test "initialize succeeds without authentication" do
    post mcp_url, params: jsonrpc("initialize", {
      "protocolVersion" => "2024-11-05",
      "clientInfo" => { "name" => "test", "version" => "1.0" }
    }, 1), as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "2024-11-05", json["result"]["protocolVersion"]
    assert_equal "CalcuMake MCP", json["result"]["serverInfo"]["name"]
  end

  test "initialize returns capabilities" do
    post mcp_url, params: jsonrpc("initialize", {}, 1), as: :json
    json = JSON.parse(response.body)
    assert json["result"]["capabilities"].key?("tools")
  end

  # ---------------------------------------------------------------------------
  # ping — allowed without auth
  # ---------------------------------------------------------------------------

  test "ping succeeds without authentication" do
    post mcp_url, params: jsonrpc("ping", {}, 1), as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal({}, json["result"])
  end

  # ---------------------------------------------------------------------------
  # notifications — no response
  # ---------------------------------------------------------------------------

  test "notification returns no content" do
    # Notifications have no id field
    post mcp_url,
         params: { "jsonrpc" => "2.0", "method" => "notifications/initialized" },
         headers: bearer(@plain), as: :json
    assert_response :no_content
  end

  # ---------------------------------------------------------------------------
  # tools/list
  # ---------------------------------------------------------------------------

  test "tools/list returns all tool definitions" do
    post mcp_url, params: jsonrpc("tools/list", {}, 2),
         headers: bearer(@plain), as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json["result"]["tools"].is_a?(Array)
    tool_names = json["result"]["tools"].map { |t| t["name"] }
    assert_includes tool_names, "health_check"
    assert_includes tool_names, "list_printers"
    assert_includes tool_names, "create_printer"
    assert_includes tool_names, "list_filaments"
    assert_includes tool_names, "list_clients"
    assert_includes tool_names, "list_print_pricings"
    assert_includes tool_names, "list_printer_profiles"
  end

  test "each tool definition has name, description, and inputSchema" do
    post mcp_url, params: jsonrpc("tools/list", {}, 2),
         headers: bearer(@plain), as: :json

    json = JSON.parse(response.body)
    json["result"]["tools"].each do |tool|
      assert tool["name"].present?,        "Tool missing name: #{tool}"
      assert tool["description"].present?, "Tool missing description: #{tool}"
      assert tool.key?("inputSchema"),     "Tool missing inputSchema: #{tool}"
    end
  end

  # ---------------------------------------------------------------------------
  # tools/call — health_check (public tool)
  # ---------------------------------------------------------------------------

  test "health_check returns ok status with auth" do
    post mcp_url,
         params: jsonrpc("tools/call", { "name" => "health_check", "arguments" => {} }, 3),
         headers: bearer(@plain), as: :json

    assert_response :success
    json = JSON.parse(response.body)
    refute json["result"]["isError"]
    data = JSON.parse(json["result"]["content"].first["text"])
    assert_equal "ok", data["status"]
  end

  # ---------------------------------------------------------------------------
  # tools/call — get_profile
  # ---------------------------------------------------------------------------

  test "get_profile returns user info" do
    post mcp_url,
         params: jsonrpc("tools/call", { "name" => "get_profile", "arguments" => {} }, 4),
         headers: bearer(@plain), as: :json

    assert_response :success
    json = JSON.parse(response.body)
    data = JSON.parse(json["result"]["content"].first["text"])
    assert_equal @user.email, data["email"]
  end

  # ---------------------------------------------------------------------------
  # tools/call — list_printers
  # ---------------------------------------------------------------------------

  test "list_printers returns user printers" do
    post mcp_url,
         params: jsonrpc("tools/call", { "name" => "list_printers", "arguments" => {} }, 5),
         headers: bearer(@plain), as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json["result"].present?, "Expected result, got: #{json['error']}"
    refute json["result"]["isError"], "Tool returned error: #{json['result'].inspect}"
    data = JSON.parse(json["result"]["content"].first["text"])
    assert data["data"].is_a?(Array)
    assert data["meta"].present?
  end

  test "list_printers does not return other users printers" do
    other_user  = users(:two)
    other_token = other_user.api_tokens.create!(name: "Other User Test")

    post mcp_url,
         params: jsonrpc("tools/call", { "name" => "list_printers", "arguments" => {} }, 5),
         headers: bearer(other_token.plain_token), as: :json

    json = JSON.parse(response.body)
    assert json["result"].present?, "Expected result, got: #{json['error']}"
    data = JSON.parse(json["result"]["content"].first["text"])
    user_printer_ids = @user.printers.pluck(:id)
    result_ids       = data["data"].map { |p| p["id"] }
    assert (result_ids & user_printer_ids).empty?
  end

  # ---------------------------------------------------------------------------
  # tools/call — list_printer_profiles (public, but also works with auth)
  # ---------------------------------------------------------------------------

  test "list_printer_profiles works with authentication" do
    post mcp_url,
         params: jsonrpc("tools/call", { "name" => "list_printer_profiles", "arguments" => {} }, 6),
         headers: bearer(@plain), as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "2.0", json["jsonrpc"]
    assert json["result"].present?, "Expected result, got: #{json['error']}"
    refute json["result"]["isError"], "Tool returned error: #{json['result'].inspect}"
  end

  # ---------------------------------------------------------------------------
  # tools/call — create_printer
  # ---------------------------------------------------------------------------

  test "create_printer creates a new printer" do
    assert_difference("Printer.count") do
      post mcp_url,
           params: jsonrpc("tools/call", {
             "name" => "create_printer",
             "arguments" => {
               "name" => "MCP Test Printer",
               "manufacturer" => "TestCo",
               "material_technology" => "fdm",
               "power_consumption" => 150,
               "cost" => 300.0,
               "payoff_goal_years" => 3,
               "daily_usage_hours" => 6
             }
           }, 7),
           headers: bearer(@plain), as: :json
    end

    json = JSON.parse(response.body)
    data = JSON.parse(json["result"]["content"].first["text"])
    assert_equal "MCP Test Printer", data["data"]["name"]
  end

  # ---------------------------------------------------------------------------
  # tools/call — unknown tool
  # ---------------------------------------------------------------------------

  test "unknown tool returns tool-not-found error in JSON-RPC" do
    post mcp_url,
         params: jsonrpc("tools/call", { "name" => "nonexistent_tool", "arguments" => {} }, 8),
         headers: bearer(@plain), as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal(-32601, json["error"]["code"])
  end

  # ---------------------------------------------------------------------------
  # tools/call — missing name
  # ---------------------------------------------------------------------------

  test "tools/call without name returns invalid params error" do
    post mcp_url,
         params: jsonrpc("tools/call", { "arguments" => {} }, 9),
         headers: bearer(@plain), as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal(-32602, json["error"]["code"])
  end

  # ---------------------------------------------------------------------------
  # Unknown method
  # ---------------------------------------------------------------------------

  test "unknown method returns method not found" do
    post mcp_url, params: jsonrpc("unsupported/method", {}, 10),
         headers: bearer(@plain), as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal(-32601, json["error"]["code"])
  end

  # ---------------------------------------------------------------------------
  # Parse error
  # ---------------------------------------------------------------------------

  test "malformed request body returns an error response" do
    # Rails middleware rejects unparseable JSON bodies before they reach the controller.
    # The controller's own parse error path is triggered when Content-Type is NOT json
    # but the body is garbage.  Either way the client receives an error status.
    post mcp_url,
         params: "not valid json{{{",
         headers: bearer(@plain).merge("Content-Type" => "text/plain")
    # Rails returns 400/415/500 — the exact code depends on middleware; just assert it's not 2xx
    assert response.status >= 400
  end

  # ---------------------------------------------------------------------------
  # Batch request
  # ---------------------------------------------------------------------------

  test "batch requests are processed" do
    batch = [
      jsonrpc("ping", {}, 1),
      jsonrpc("tools/list", {}, 2)
    ]

    post mcp_url,
         params: batch,
         headers: bearer(@plain), as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 2, json.size
    assert json.any? { |r| r["id"] == 1 }
    assert json.any? { |r| r["id"] == 2 }
  end

  private

  def bearer(token)
    { "Authorization" => "Bearer #{token}" }
  end

  # Returns a Hash; pass with `as: :json` so ActionDispatch serialises it once.
  def jsonrpc(method, params, id)
    { "jsonrpc" => "2.0", "method" => method, "params" => params, "id" => id }
  end
end
