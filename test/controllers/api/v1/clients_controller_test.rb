# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class ClientsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @other_user = users(:two)
        @token = @user.api_tokens.create!(name: "Test Token")
        @plain_token = @token.plain_token
        @client = clients(:one)
        @other_user_client = clients(:two)
      end

      # Authentication tests
      test "index requires authentication" do
        get api_v1_clients_url
        assert_response :unauthorized
      end

      test "show requires authentication" do
        get api_v1_client_url(@client)
        assert_response :unauthorized
      end

      test "create requires authentication" do
        post api_v1_clients_url, params: { client: { name: "New" } }
        assert_response :unauthorized
      end

      test "update requires authentication" do
        patch api_v1_client_url(@client), params: { client: { name: "Updated" } }
        assert_response :unauthorized
      end

      test "destroy requires authentication" do
        delete api_v1_client_url(@client)
        assert_response :unauthorized
      end

      # Index tests
      test "index returns user clients" do
        get api_v1_clients_url, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert json.key?("data")
        assert json["data"].is_a?(Array)
        assert json["data"].any? { |c| c["id"] == @client.id.to_s }
      end

      test "index does not return other users clients" do
        get api_v1_clients_url, headers: auth_headers

        json = JSON.parse(response.body)
        client_ids = json["data"].map { |c| c["id"] }

        refute_includes client_ids, @other_user_client.id.to_s
      end

      test "index filters by search query" do
        @client.update!(name: "Test Client Company")
        get api_v1_clients_url, params: { q: "Test" }, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert json["data"].any? { |c| c["id"] == @client.id.to_s }
      end

      test "index returns empty array when no clients match search" do
        get api_v1_clients_url, params: { q: "nonexistentzzzz" }, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal [], json["data"]
      end

      # Show tests
      test "show returns client details" do
        @client.update!(
          name: "Full Client",
          email: "client@example.com",
          phone: "555-1234",
          company_name: "Client Corp"
        )

        get api_v1_client_url(@client), headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal @client.id.to_s, json["data"]["id"]
        assert_equal "client", json["data"]["type"]
        assert_equal "Full Client", json["data"]["attributes"]["name"]
        assert_equal "client@example.com", json["data"]["attributes"]["email"]
        assert_equal "555-1234", json["data"]["attributes"]["phone"]
        assert_equal "Client Corp", json["data"]["attributes"]["company_name"]
      end

      test "show includes relationships" do
        get api_v1_client_url(@client), headers: auth_headers

        json = JSON.parse(response.body)

        assert json["data"]["relationships"].key?("print_pricings")
        assert json["data"]["relationships"]["print_pricings"]["meta"].key?("count")
        assert json["data"]["relationships"].key?("invoices")
        assert json["data"]["relationships"]["invoices"]["meta"].key?("count")
      end

      test "show returns 404 for non-existent client" do
        get api_v1_client_url(id: 999999), headers: auth_headers

        assert_response :not_found
      end

      test "show returns 404 for other users client" do
        get api_v1_client_url(@other_user_client), headers: auth_headers

        assert_response :not_found
      end

      # Create tests
      test "create creates a new client" do
        assert_difference("Client.count") do
          post api_v1_clients_url, params: {
            client: {
              name: "New Client Name",
              email: "newclient@example.com",
              phone: "555-9999",
              company_name: "New Company LLC",
              address: "123 Main St",
              tax_id: "12-3456789"
            }
          }, headers: auth_headers
        end

        assert_response :created
        json = JSON.parse(response.body)

        assert_equal "New Client Name", json["data"]["attributes"]["name"]
        assert_equal "newclient@example.com", json["data"]["attributes"]["email"]
        assert_equal "New Company LLC", json["data"]["attributes"]["company_name"]
      end

      test "create returns JSON:API format response" do
        post api_v1_clients_url, params: {
          client: { name: "Test Client" }
        }, headers: auth_headers

        json = JSON.parse(response.body)
        assert json["data"].key?("id")
        assert json["data"].key?("type")
        assert json["data"].key?("attributes")
        assert json["data"].key?("relationships")
      end

      test "create with invalid data returns validation errors" do
        assert_no_difference("Client.count") do
          post api_v1_clients_url, params: {
            client: { name: "" }
          }, headers: auth_headers
        end

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)

        assert json.key?("errors")
        assert json["errors"].first["code"] == "validation_error"
      end

      test "create associates client with current user" do
        post api_v1_clients_url, params: {
          client: { name: "My Client" }
        }, headers: auth_headers

        client = Client.last
        assert_equal @user.id, client.user_id
      end

      # Update tests
      test "update modifies client" do
        patch api_v1_client_url(@client), params: {
          client: {
            name: "Updated Client Name",
            email: "updated@example.com",
            phone: "555-0000"
          }
        }, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal "Updated Client Name", json["data"]["attributes"]["name"]
        assert_equal "updated@example.com", json["data"]["attributes"]["email"]
        @client.reload
        assert_equal "Updated Client Name", @client.name
      end

      test "update returns 404 for other users client" do
        patch api_v1_client_url(@other_user_client), params: {
          client: { name: "Hacked" }
        }, headers: auth_headers

        assert_response :not_found
        @other_user_client.reload
        refute_equal "Hacked", @other_user_client.name
      end

      test "update with invalid data returns validation errors" do
        patch api_v1_client_url(@client), params: {
          client: { name: "" }
        }, headers: auth_headers

        assert_response :unprocessable_entity
      end

      test "update partial fields" do
        original_name = @client.name
        @client.update!(email: "original@example.com")

        patch api_v1_client_url(@client), params: {
          client: { phone: "555-NEW" }
        }, headers: auth_headers

        assert_response :success
        @client.reload

        assert_equal original_name, @client.name
        assert_equal "original@example.com", @client.email
        assert_equal "555-NEW", @client.phone
      end

      # Destroy tests
      test "destroy deletes client" do
        # Create a new client not used anywhere
        client = @user.clients.create!(name: "Temp Client")

        assert_difference("Client.count", -1) do
          delete api_v1_client_url(client), headers: auth_headers
        end

        assert_response :no_content
      end

      test "destroy returns 404 for other users client" do
        assert_no_difference("Client.count") do
          delete api_v1_client_url(@other_user_client), headers: auth_headers
        end

        assert_response :not_found
      end

      test "destroy returns 404 for non-existent client" do
        delete api_v1_client_url(id: 999999), headers: auth_headers

        assert_response :not_found
      end

      # Response format tests
      test "responses include correct content type" do
        get api_v1_clients_url, headers: auth_headers

        assert_match %r{application/json}, response.content_type
      end

      test "index returns properly formatted attributes" do
        get api_v1_clients_url, headers: auth_headers

        json = JSON.parse(response.body)

        json["data"].each do |client|
          assert client["attributes"].key?("name")
          assert client["attributes"].key?("email")
          assert client["attributes"].key?("phone")
          assert client["attributes"].key?("company_name")
          assert client["attributes"].key?("address")
          assert client["attributes"].key?("tax_id")
          assert client["attributes"].key?("notes")
          assert client["attributes"].key?("created_at")
          assert client["attributes"].key?("updated_at")
        end
      end

      # Tax ID tests
      test "create with tax_id" do
        post api_v1_clients_url, params: {
          client: {
            name: "Business Client",
            company_name: "Acme Corp",
            tax_id: "US-12345678"
          }
        }, headers: auth_headers

        assert_response :created
        json = JSON.parse(response.body)

        assert_equal "US-12345678", json["data"]["attributes"]["tax_id"]
      end

      private

      def auth_headers
        { "Authorization" => "Bearer #{@plain_token}" }
      end
    end
  end
end
