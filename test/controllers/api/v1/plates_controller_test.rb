# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class PlatesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @other_user = users(:two)
        @token = @user.api_tokens.create!(name: "Test Token")
        @plain_token = @token.plain_token
        @print_pricing = print_pricings(:one)
        @other_user_print_pricing = print_pricings(:two)
        @plate = plates(:one)
        @other_user_plate = plates(:two)
      end

      # ── Authentication ──────────────────────────────────────────────────────

      test "index requires authentication" do
        get api_v1_print_pricing_plates_url(@print_pricing)
        assert_response :unauthorized
      end

      test "show requires authentication" do
        get api_v1_plate_url(@plate)
        assert_response :unauthorized
      end

      # ── Index ────────────────────────────────────────────────────────────────

      test "index returns success for user's print_pricing" do
        get api_v1_print_pricing_plates_url(@print_pricing), headers: auth_headers
        assert_response :success
      end

      test "index returns JSON content type" do
        get api_v1_print_pricing_plates_url(@print_pricing), headers: auth_headers
        assert_match %r{application/json}, response.content_type
      end

      test "index returns plates for the given print_pricing" do
        get api_v1_print_pricing_plates_url(@print_pricing), headers: auth_headers
        json = JSON.parse(response.body)
        assert json.key?("data")
        assert json["data"].is_a?(Array)
        plate_ids = json["data"].map { |p| p["id"] }
        assert_includes plate_ids, @plate.id.to_s
      end

      test "index does not return plates from other user's print_pricing" do
        get api_v1_print_pricing_plates_url(@print_pricing), headers: auth_headers
        json = JSON.parse(response.body)
        plate_ids = json["data"].map { |p| p["id"] }
        refute_includes plate_ids, @other_user_plate.id.to_s
      end

      test "index returns 404 for another user's print_pricing" do
        get api_v1_print_pricing_plates_url(@other_user_print_pricing), headers: auth_headers
        assert_response :not_found
      end

      # ── Show ─────────────────────────────────────────────────────────────────

      test "show returns success for user's plate" do
        get api_v1_plate_url(@plate), headers: auth_headers
        assert_response :success
      end

      test "show returns single plate data" do
        get api_v1_plate_url(@plate), headers: auth_headers
        json = JSON.parse(response.body)
        assert json.key?("data")
        assert_equal @plate.id.to_s, json["data"]["id"]
      end

      test "show returns 404 for another user's plate" do
        get api_v1_plate_url(@other_user_plate), headers: auth_headers
        assert_response :not_found
      end

      # ── Response format ───────────────────────────────────────────────────────

      test "plate entries have required attributes" do
        get api_v1_print_pricing_plates_url(@print_pricing), headers: auth_headers
        json = JSON.parse(response.body)
        plate = json["data"].first
        assert_not_nil plate
        assert_equal "plate", plate["type"]
        %w[material_technology printing_time_hours printing_time_minutes
           total_printing_time_minutes total_material_cost material_types
           created_at updated_at].each do |attr|
          assert plate["attributes"].key?(attr), "Plate missing attribute: #{attr}"
        end
      end

      test "plate entry includes relationships" do
        get api_v1_print_pricing_plates_url(@print_pricing), headers: auth_headers
        json = JSON.parse(response.body)
        plate = json["data"].first
        assert plate.key?("relationships"), "Plate missing 'relationships'"
        assert plate["relationships"].key?("print_pricing")
        assert_equal @print_pricing.id.to_s, plate["relationships"]["print_pricing"]["data"]["id"]
      end

      test "fdm plate includes filaments relationship" do
        # plates(:one) is fdm
        get api_v1_plate_url(@plate), headers: auth_headers
        json = JSON.parse(response.body)
        plate = json["data"]
        assert_equal "fdm", plate["attributes"]["material_technology"]
        assert plate["relationships"].key?("filaments"), "FDM plate should have filaments relationship"
        assert_nil plate["attributes"]["total_resin_volume"], "FDM plate should not have total_resin_volume"
      end

      test "fdm plate filament relationships have required attributes" do
        get api_v1_plate_url(@plate), headers: auth_headers
        json = JSON.parse(response.body)
        plate = json["data"]
        filament_entry = plate["relationships"]["filaments"]["data"].first
        next if filament_entry.nil? # plate may have no filaments in fixtures
        %w[filament_name filament_brand material_type filament_weight total_cost].each do |attr|
          assert filament_entry["attributes"].key?(attr), "Filament relationship missing: #{attr}"
        end
      end

      private

      def auth_headers
        { "Authorization" => "Bearer #{@plain_token}" }
      end
    end
  end
end
