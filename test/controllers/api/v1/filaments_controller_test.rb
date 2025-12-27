# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class FilamentsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @other_user = users(:two)
        @token = @user.api_tokens.create!(name: "Test Token")
        @plain_token = @token.plain_token
        @filament = filaments(:one)
        @other_user_filament = filaments(:two)
      end

      # Authentication tests
      test "index requires authentication" do
        get api_v1_filaments_url
        assert_response :unauthorized
      end

      test "show requires authentication" do
        get api_v1_filament_url(@filament)
        assert_response :unauthorized
      end

      test "create requires authentication" do
        post api_v1_filaments_url, params: { filament: { name: "New" } }
        assert_response :unauthorized
      end

      test "update requires authentication" do
        patch api_v1_filament_url(@filament), params: { filament: { name: "Updated" } }
        assert_response :unauthorized
      end

      test "destroy requires authentication" do
        delete api_v1_filament_url(@filament)
        assert_response :unauthorized
      end

      test "duplicate requires authentication" do
        post duplicate_api_v1_filament_url(@filament)
        assert_response :unauthorized
      end

      # Index tests
      test "index returns user filaments" do
        get api_v1_filaments_url, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert json.key?("data")
        assert json["data"].is_a?(Array)
        assert json["data"].any? { |f| f["id"] == @filament.id.to_s }
      end

      test "index does not return other users filaments" do
        get api_v1_filaments_url, headers: auth_headers

        json = JSON.parse(response.body)
        filament_ids = json["data"].map { |f| f["id"] }

        refute_includes filament_ids, @other_user_filament.id.to_s
      end

      test "index filters by search query" do
        get api_v1_filaments_url, params: { q: "PLA" }, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert json["data"].all? { |f|
          f["attributes"]["name"].include?("PLA") ||
          f["attributes"]["material_type"].include?("PLA")
        }
      end

      test "index filters by material type" do
        get api_v1_filaments_url, params: { material_type: "PLA" }, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        json["data"].each do |filament|
          assert_equal "PLA", filament["attributes"]["material_type"]
        end
      end

      # Show tests
      test "show returns filament details" do
        get api_v1_filament_url(@filament), headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal @filament.id.to_s, json["data"]["id"]
        assert_equal "filament", json["data"]["type"]
        assert_equal @filament.name, json["data"]["attributes"]["name"]
        assert_equal @filament.brand, json["data"]["attributes"]["brand"]
        assert_equal @filament.material_type, json["data"]["attributes"]["material_type"]
        assert_equal @filament.color, json["data"]["attributes"]["color"]
        assert json["data"]["attributes"].key?("cost_per_gram")
        assert json["data"]["attributes"].key?("spool_price")
        assert json["data"]["attributes"].key?("spool_weight")
      end

      test "show returns 404 for non-existent filament" do
        get api_v1_filament_url(id: 999999), headers: auth_headers

        assert_response :not_found
      end

      test "show returns 404 for other users filament" do
        get api_v1_filament_url(@other_user_filament), headers: auth_headers

        assert_response :not_found
      end

      # Create tests
      test "create creates a new filament" do
        assert_difference("Filament.count") do
          post api_v1_filaments_url, params: {
            filament: {
              name: "New PLA Filament",
              brand: "Sunlu",
              material_type: "PLA",
              color: "Blue",
              diameter: 1.75,
              density: 1.24,
              spool_weight: 1000,
              spool_price: 20.00
            }
          }, headers: auth_headers
        end

        assert_response :created
        json = JSON.parse(response.body)

        assert_equal "New PLA Filament", json["data"]["attributes"]["name"]
        assert_equal "Sunlu", json["data"]["attributes"]["brand"]
        assert_equal "PLA", json["data"]["attributes"]["material_type"]
        assert_equal "Blue", json["data"]["attributes"]["color"]
      end

      test "create returns cost_per_gram calculated value" do
        post api_v1_filaments_url, params: {
          filament: {
            name: "Test",
            brand: "Test",
            material_type: "PLA",
            spool_weight: 1000,
            spool_price: 25.00
          }
        }, headers: auth_headers

        json = JSON.parse(response.body)
        assert_equal 0.025, json["data"]["attributes"]["cost_per_gram"]
      end

      test "create with invalid data returns validation errors" do
        assert_no_difference("Filament.count") do
          post api_v1_filaments_url, params: {
            filament: { name: "" }
          }, headers: auth_headers
        end

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)

        assert json.key?("errors")
        assert json["errors"].first["code"] == "validation_error"
      end

      test "create associates filament with current user" do
        post api_v1_filaments_url, params: {
          filament: { name: "My Filament", brand: "Test", material_type: "ABS" }
        }, headers: auth_headers

        filament = Filament.last
        assert_equal @user.id, filament.user_id
      end

      # Update tests
      test "update modifies filament" do
        patch api_v1_filament_url(@filament), params: {
          filament: { name: "Updated Filament Name", color: "Green" }
        }, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal "Updated Filament Name", json["data"]["attributes"]["name"]
        assert_equal "Green", json["data"]["attributes"]["color"]
        @filament.reload
        assert_equal "Updated Filament Name", @filament.name
      end

      test "update returns 404 for other users filament" do
        patch api_v1_filament_url(@other_user_filament), params: {
          filament: { name: "Hacked" }
        }, headers: auth_headers

        assert_response :not_found
      end

      test "update with invalid data returns validation errors" do
        patch api_v1_filament_url(@filament), params: {
          filament: { name: "" }
        }, headers: auth_headers

        assert_response :unprocessable_entity
      end

      # Destroy tests
      test "destroy deletes filament" do
        # Create a new filament not used anywhere
        filament = @user.filaments.create!(name: "Temp", brand: "Test", material_type: "PLA")

        assert_difference("Filament.count", -1) do
          delete api_v1_filament_url(filament), headers: auth_headers
        end

        assert_response :no_content
      end

      test "destroy returns 404 for other users filament" do
        assert_no_difference("Filament.count") do
          delete api_v1_filament_url(@other_user_filament), headers: auth_headers
        end

        assert_response :not_found
      end

      # Duplicate tests
      test "duplicate creates a copy of filament" do
        assert_difference("Filament.count") do
          post duplicate_api_v1_filament_url(@filament), headers: auth_headers
        end

        assert_response :created
        json = JSON.parse(response.body)

        assert_match(/\(Copy\)/, json["data"]["attributes"]["name"])
        assert_equal @filament.brand, json["data"]["attributes"]["brand"]
        assert_equal @filament.material_type, json["data"]["attributes"]["material_type"]
        assert_equal @filament.color, json["data"]["attributes"]["color"]
      end

      test "duplicate returns 404 for other users filament" do
        assert_no_difference("Filament.count") do
          post duplicate_api_v1_filament_url(@other_user_filament), headers: auth_headers
        end

        assert_response :not_found
      end

      test "duplicate preserves all filament properties except name" do
        post duplicate_api_v1_filament_url(@filament), headers: auth_headers

        json = JSON.parse(response.body)

        assert_equal @filament.diameter.to_f, json["data"]["attributes"]["diameter"]
        assert_equal @filament.density.to_f, json["data"]["attributes"]["density"]
        assert_equal @filament.spool_weight.to_f, json["data"]["attributes"]["spool_weight"]
        assert_equal @filament.spool_price.to_f, json["data"]["attributes"]["spool_price"]
      end

      # Response format tests
      test "responses include correct content type" do
        get api_v1_filaments_url, headers: auth_headers

        assert_match %r{application/json}, response.content_type
      end

      test "index returns properly formatted attributes" do
        get api_v1_filaments_url, headers: auth_headers

        json = JSON.parse(response.body)

        json["data"].each do |filament|
          assert filament["attributes"].key?("name")
          assert filament["attributes"].key?("brand")
          assert filament["attributes"].key?("material_type")
          assert filament["attributes"].key?("color")
          assert filament["attributes"].key?("diameter")
          assert filament["attributes"].key?("density")
          assert filament["attributes"].key?("cost_per_gram")
          assert filament["attributes"].key?("created_at")
          assert filament["attributes"].key?("updated_at")
        end
      end

      private

      def auth_headers
        { "Authorization" => "Bearer #{@plain_token}" }
      end
    end
  end
end
