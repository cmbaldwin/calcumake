# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class ResinsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @other_user = users(:two)
        @token = @user.api_tokens.create!(name: "Test Token")
        @plain_token = @token.plain_token
        @resin = resins(:one)
        @other_user_resin = resins(:two)
      end

      # Authentication tests
      test "index requires authentication" do
        get api_v1_resins_url
        assert_response :unauthorized
      end

      test "show requires authentication" do
        get api_v1_resin_url(@resin)
        assert_response :unauthorized
      end

      test "create requires authentication" do
        post api_v1_resins_url, params: { resin: { name: "New" } }
        assert_response :unauthorized
      end

      test "update requires authentication" do
        patch api_v1_resin_url(@resin), params: { resin: { name: "Updated" } }
        assert_response :unauthorized
      end

      test "destroy requires authentication" do
        delete api_v1_resin_url(@resin)
        assert_response :unauthorized
      end

      test "duplicate requires authentication" do
        post duplicate_api_v1_resin_url(@resin)
        assert_response :unauthorized
      end

      # Index tests
      test "index returns user resins" do
        get api_v1_resins_url, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert json.key?("data")
        assert json["data"].is_a?(Array)
        assert json["data"].any? { |r| r["id"] == @resin.id.to_s }
      end

      test "index does not return other users resins" do
        get api_v1_resins_url, headers: auth_headers

        json = JSON.parse(response.body)
        resin_ids = json["data"].map { |r| r["id"] }

        refute_includes resin_ids, @other_user_resin.id.to_s
      end

      test "index filters by search query" do
        get api_v1_resins_url, params: { q: "Gray" }, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert json["data"].all? { |r|
          r["attributes"]["name"]&.include?("Gray") ||
          r["attributes"]["color"]&.include?("Gray")
        }
      end

      test "index filters by resin type" do
        get api_v1_resins_url, params: { resin_type: "Standard" }, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        json["data"].each do |resin|
          assert_equal "Standard", resin["attributes"]["resin_type"]
        end
      end

      # Show tests
      test "show returns resin details" do
        get api_v1_resin_url(@resin), headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal @resin.id.to_s, json["data"]["id"]
        assert_equal "resin", json["data"]["type"]
        assert_equal @resin.name, json["data"]["attributes"]["name"]
        assert_equal @resin.brand, json["data"]["attributes"]["brand"]
        assert_equal @resin.resin_type, json["data"]["attributes"]["resin_type"]
        assert_equal @resin.color, json["data"]["attributes"]["color"]
        assert json["data"]["attributes"].key?("cost_per_ml")
        assert json["data"]["attributes"].key?("bottle_price")
        assert json["data"]["attributes"].key?("bottle_volume_ml")
        assert json["data"]["attributes"].key?("display_name")
      end

      test "show returns 404 for non-existent resin" do
        get api_v1_resin_url(id: 999999), headers: auth_headers

        assert_response :not_found
      end

      test "show returns 404 for other users resin" do
        get api_v1_resin_url(@other_user_resin), headers: auth_headers

        assert_response :not_found
      end

      # Create tests
      test "create creates a new resin" do
        assert_difference("Resin.count") do
          post api_v1_resins_url, params: {
            resin: {
              name: "New Standard Resin",
              brand: "Phrozen",
              resin_type: "Standard",
              color: "Clear",
              bottle_volume_ml: 1000,
              bottle_price: 35.00
            }
          }, headers: auth_headers
        end

        assert_response :created
        json = JSON.parse(response.body)

        assert_equal "New Standard Resin", json["data"]["attributes"]["name"]
        assert_equal "Phrozen", json["data"]["attributes"]["brand"]
        assert_equal "Standard", json["data"]["attributes"]["resin_type"]
        assert_equal "Clear", json["data"]["attributes"]["color"]
      end

      test "create returns cost_per_ml calculated value" do
        post api_v1_resins_url, params: {
          resin: {
            name: "Test",
            brand: "Test",
            resin_type: "Standard",
            bottle_volume_ml: 1000,
            bottle_price: 25.00
          }
        }, headers: auth_headers

        json = JSON.parse(response.body)
        assert_equal 0.025, json["data"]["attributes"]["cost_per_ml"]
      end

      test "create with invalid data returns validation errors" do
        assert_no_difference("Resin.count") do
          post api_v1_resins_url, params: {
            resin: { name: "" }
          }, headers: auth_headers
        end

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)

        assert json.key?("errors")
        assert json["errors"].first["code"] == "validation_error"
      end

      test "create associates resin with current user" do
        post api_v1_resins_url, params: {
          resin: { name: "My Resin", brand: "Test", resin_type: "Standard" }
        }, headers: auth_headers

        resin = Resin.last
        assert_equal @user.id, resin.user_id
      end

      # Update tests
      test "update modifies resin" do
        patch api_v1_resin_url(@resin), params: {
          resin: { name: "Updated Resin Name", color: "White" }
        }, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal "Updated Resin Name", json["data"]["attributes"]["name"]
        assert_equal "White", json["data"]["attributes"]["color"]
        @resin.reload
        assert_equal "Updated Resin Name", @resin.name
      end

      test "update returns 404 for other users resin" do
        patch api_v1_resin_url(@other_user_resin), params: {
          resin: { name: "Hacked" }
        }, headers: auth_headers

        assert_response :not_found
      end

      test "update with invalid data returns validation errors" do
        patch api_v1_resin_url(@resin), params: {
          resin: { name: "" }
        }, headers: auth_headers

        assert_response :unprocessable_entity
      end

      # Destroy tests
      test "destroy deletes resin" do
        # Create a new resin not used anywhere
        resin = @user.resins.create!(name: "Temp", brand: "Test", resin_type: "Standard")

        assert_difference("Resin.count", -1) do
          delete api_v1_resin_url(resin), headers: auth_headers
        end

        assert_response :no_content
      end

      test "destroy returns 404 for other users resin" do
        assert_no_difference("Resin.count") do
          delete api_v1_resin_url(@other_user_resin), headers: auth_headers
        end

        assert_response :not_found
      end

      # Duplicate tests
      test "duplicate creates a copy of resin" do
        assert_difference("Resin.count") do
          post duplicate_api_v1_resin_url(@resin), headers: auth_headers
        end

        assert_response :created
        json = JSON.parse(response.body)

        assert_match(/\(Copy\)/, json["data"]["attributes"]["name"])
        assert_equal @resin.brand, json["data"]["attributes"]["brand"]
        assert_equal @resin.resin_type, json["data"]["attributes"]["resin_type"]
        assert_equal @resin.color, json["data"]["attributes"]["color"]
      end

      test "duplicate returns 404 for other users resin" do
        assert_no_difference("Resin.count") do
          post duplicate_api_v1_resin_url(@other_user_resin), headers: auth_headers
        end

        assert_response :not_found
      end

      test "duplicate preserves all resin properties except name" do
        post duplicate_api_v1_resin_url(@resin), headers: auth_headers

        json = JSON.parse(response.body)

        assert_equal @resin.bottle_volume_ml.to_f, json["data"]["attributes"]["bottle_volume_ml"]
        assert_equal @resin.bottle_price.to_f, json["data"]["attributes"]["bottle_price"]
        assert_equal @resin.cure_time_seconds, json["data"]["attributes"]["cure_time_seconds"]
        assert_equal @resin.exposure_time_seconds, json["data"]["attributes"]["exposure_time_seconds"]
      end

      # Response format tests
      test "responses include correct content type" do
        get api_v1_resins_url, headers: auth_headers

        assert_match %r{application/json}, response.content_type
      end

      test "index returns properly formatted attributes" do
        get api_v1_resins_url, headers: auth_headers

        json = JSON.parse(response.body)

        json["data"].each do |resin|
          assert resin["attributes"].key?("name")
          assert resin["attributes"].key?("brand")
          assert resin["attributes"].key?("resin_type")
          assert resin["attributes"].key?("color")
          assert resin["attributes"].key?("bottle_volume_ml")
          assert resin["attributes"].key?("bottle_price")
          assert resin["attributes"].key?("cost_per_ml")
          assert resin["attributes"].key?("display_name")
          assert resin["attributes"].key?("created_at")
          assert resin["attributes"].key?("updated_at")
        end
      end

      # Layer height range tests
      test "show includes layer height range" do
        get api_v1_resin_url(@resin), headers: auth_headers

        json = JSON.parse(response.body)
        assert json["data"]["attributes"].key?("layer_height_range")
        assert json["data"]["attributes"].key?("layer_height_min")
        assert json["data"]["attributes"].key?("layer_height_max")
      end

      private

      def auth_headers
        { "Authorization" => "Bearer #{@plain_token}" }
      end
    end
  end
end
