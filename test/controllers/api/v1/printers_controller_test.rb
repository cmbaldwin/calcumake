# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class PrintersControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @other_user = users(:two)
        @token = @user.api_tokens.create!(name: "Test Token")
        @plain_token = @token.plain_token
        @printer = printers(:one)
        @other_user_printer = printers(:two)
      end

      # Authentication tests
      test "index requires authentication" do
        get api_v1_printers_url
        assert_response :unauthorized
      end

      test "show requires authentication" do
        get api_v1_printer_url(@printer)
        assert_response :unauthorized
      end

      test "create requires authentication" do
        post api_v1_printers_url, params: { printer: { name: "New Printer" } }
        assert_response :unauthorized
      end

      test "update requires authentication" do
        patch api_v1_printer_url(@printer), params: { printer: { name: "Updated" } }
        assert_response :unauthorized
      end

      test "destroy requires authentication" do
        delete api_v1_printer_url(@printer)
        assert_response :unauthorized
      end

      # Index tests
      test "index returns user printers" do
        get api_v1_printers_url, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert json.key?("data")
        assert json["data"].is_a?(Array)
        assert json["data"].any? { |p| p["id"] == @printer.id.to_s }
      end

      test "index does not return other users printers" do
        get api_v1_printers_url, headers: auth_headers

        json = JSON.parse(response.body)
        printer_ids = json["data"].map { |p| p["id"] }

        refute_includes printer_ids, @other_user_printer.id.to_s
      end

      test "index filters by technology" do
        get api_v1_printers_url, params: { technology: "resin" }, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        json["data"].each do |printer|
          assert_equal "resin", printer["attributes"]["material_technology"]
        end
      end

      test "index with invalid technology filter returns all printers" do
        get api_v1_printers_url, params: { technology: "invalid" }, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        # Should still return printers (filter ignored for invalid values)
        assert json["data"].is_a?(Array)
      end

      # Show tests
      test "show returns printer details" do
        get api_v1_printer_url(@printer), headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal @printer.id.to_s, json["data"]["id"]
        assert_equal "printer", json["data"]["type"]
        assert_equal @printer.name, json["data"]["attributes"]["name"]
        assert_equal @printer.manufacturer, json["data"]["attributes"]["manufacturer"]
        assert_equal @printer.material_technology, json["data"]["attributes"]["material_technology"]
        assert_equal @printer.power_consumption.to_i, json["data"]["attributes"]["power_consumption"].to_i
        assert json["data"]["attributes"].key?("created_at")
        assert json["data"]["attributes"].key?("updated_at")
      end

      test "show includes relationships" do
        get api_v1_printer_url(@printer), headers: auth_headers

        json = JSON.parse(response.body)
        assert json["data"]["relationships"].key?("print_pricings")
        assert json["data"]["relationships"]["print_pricings"]["meta"].key?("count")
      end

      test "show returns 404 for non-existent printer" do
        get api_v1_printer_url(id: 999999), headers: auth_headers

        assert_response :not_found
        json = JSON.parse(response.body)

        assert json["errors"].first["status"] == "404"
        assert json["errors"].first["code"] == "not_found"
      end

      test "show returns 404 for other users printer" do
        get api_v1_printer_url(@other_user_printer), headers: auth_headers

        assert_response :not_found
      end

      # Create tests
      test "create creates a new printer" do
        assert_difference("Printer.count") do
          post api_v1_printers_url, params: {
            printer: {
              name: "New Test Printer",
              manufacturer: "Creality",
              material_technology: "fdm",
              power_consumption: 150,
              cost: 400,
              payoff_goal_years: 3,
              daily_usage_hours: 6
            }
          }, headers: auth_headers
        end

        assert_response :created
        json = JSON.parse(response.body)

        assert_equal "New Test Printer", json["data"]["attributes"]["name"]
        assert_equal "Creality", json["data"]["attributes"]["manufacturer"]
        assert_equal "fdm", json["data"]["attributes"]["material_technology"]
      end

      test "create returns JSON:API format response" do
        post api_v1_printers_url, params: {
          printer: {
            name: "Test",
            manufacturer: "Test",
            material_technology: "fdm",
            power_consumption: 100,
            cost: 300,
            payoff_goal_years: 2,
            daily_usage_hours: 4
          }
        }, headers: auth_headers

        assert_response :created
        json = JSON.parse(response.body)
        assert json["data"].key?("id")
        assert json["data"].key?("type")
        assert json["data"].key?("attributes")
        assert json["data"].key?("relationships")
      end

      test "create with invalid data returns validation errors" do
        assert_no_difference("Printer.count") do
          post api_v1_printers_url, params: {
            printer: { name: "" }
          }, headers: auth_headers
        end

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)

        assert json.key?("errors")
        assert json["errors"].is_a?(Array)
        assert json["errors"].first["code"] == "validation_error"
      end

      test "create associates printer with current user" do
        post api_v1_printers_url, params: {
          printer: {
            name: "My Printer",
            manufacturer: "Test",
            material_technology: "fdm",
            power_consumption: 100,
            cost: 250,
            payoff_goal_years: 2,
            daily_usage_hours: 4
          }
        }, headers: auth_headers

        assert_response :created
        printer = Printer.last
        assert_equal @user.id, printer.user_id
      end

      test "create with missing required parameter returns bad request" do
        post api_v1_printers_url, params: {}, headers: auth_headers

        assert_response :bad_request
        json = JSON.parse(response.body)

        assert json["errors"].first["code"] == "bad_request"
      end

      # Update tests
      test "update modifies printer" do
        patch api_v1_printer_url(@printer), params: {
          printer: { name: "Updated Printer Name" }
        }, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal "Updated Printer Name", json["data"]["attributes"]["name"]
        @printer.reload
        assert_equal "Updated Printer Name", @printer.name
      end

      test "update returns 404 for other users printer" do
        patch api_v1_printer_url(@other_user_printer), params: {
          printer: { name: "Hacked" }
        }, headers: auth_headers

        assert_response :not_found
        @other_user_printer.reload
        refute_equal "Hacked", @other_user_printer.name
      end

      test "update with invalid data returns validation errors" do
        patch api_v1_printer_url(@printer), params: {
          printer: { name: "" }
        }, headers: auth_headers

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)

        assert json["errors"].first["code"] == "validation_error"
      end

      # Destroy tests
      test "destroy deletes printer" do
        assert_difference("Printer.count", -1) do
          delete api_v1_printer_url(@printer), headers: auth_headers
        end

        assert_response :no_content
      end

      test "destroy returns 404 for other users printer" do
        assert_no_difference("Printer.count") do
          delete api_v1_printer_url(@other_user_printer), headers: auth_headers
        end

        assert_response :not_found
      end

      test "destroy returns 404 for non-existent printer" do
        delete api_v1_printer_url(id: 999999), headers: auth_headers

        assert_response :not_found
      end

      # Technology filter edge cases
      test "index with fdm filter returns only fdm printers" do
        get api_v1_printers_url, params: { technology: "fdm" }, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        json["data"].each do |printer|
          assert_equal "fdm", printer["attributes"]["material_technology"]
        end
      end

      # Response format tests
      test "responses include correct content type" do
        get api_v1_printers_url, headers: auth_headers

        assert_match %r{application/json}, response.content_type
      end

      private

      def auth_headers
        { "Authorization" => "Bearer #{@plain_token}" }
      end
    end
  end
end
