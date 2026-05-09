# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class MaterialsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @other_user = users(:two)
        @token = @user.api_tokens.create!(name: "Test Token")
        @plain_token = @token.plain_token
        @filament = filaments(:one)
        @resin = resins(:one)
        @other_user_filament = filaments(:two)
        @other_user_resin = resins(:two)
      end

      # ── Authentication ──────────────────────────────────────────────────────

      test "index requires authentication" do
        get api_v1_materials_url
        assert_response :unauthorized
      end

      # ── Index - basic response ───────────────────────────────────────────────

      test "index returns success with valid token" do
        get api_v1_materials_url, headers: auth_headers
        assert_response :success
      end

      test "index returns JSON content type" do
        get api_v1_materials_url, headers: auth_headers
        assert_match %r{application/json}, response.content_type
      end

      test "index response contains data and meta keys" do
        get api_v1_materials_url, headers: auth_headers
        json = JSON.parse(response.body)
        assert json.key?("data"), "Response missing 'data' key"
        assert json.key?("meta"), "Response missing 'meta' key"
      end

      test "index data contains filaments and resins arrays" do
        get api_v1_materials_url, headers: auth_headers
        json = JSON.parse(response.body)
        assert json["data"].key?("filaments"), "data missing 'filaments'"
        assert json["data"].key?("resins"), "data missing 'resins'"
        assert json["data"]["filaments"].is_a?(Array)
        assert json["data"]["resins"].is_a?(Array)
      end

      # ── Index - user scoping ─────────────────────────────────────────────────

      test "index returns current user filaments" do
        get api_v1_materials_url, headers: auth_headers
        json = JSON.parse(response.body)
        filament_ids = json["data"]["filaments"].map { |f| f["id"] }
        assert_includes filament_ids, @filament.id.to_s
      end

      test "index does not return other user filaments" do
        get api_v1_materials_url, headers: auth_headers
        json = JSON.parse(response.body)
        filament_ids = json["data"]["filaments"].map { |f| f["id"] }
        refute_includes filament_ids, @other_user_filament.id.to_s
      end

      test "index returns current user resins" do
        get api_v1_materials_url, headers: auth_headers
        json = JSON.parse(response.body)
        resin_ids = json["data"]["resins"].map { |r| r["id"] }
        assert_includes resin_ids, @resin.id.to_s
      end

      test "index does not return other user resins" do
        get api_v1_materials_url, headers: auth_headers
        json = JSON.parse(response.body)
        resin_ids = json["data"]["resins"].map { |r| r["id"] }
        refute_includes resin_ids, @other_user_resin.id.to_s
      end

      # ── Index - technology filter ─────────────────────────────────────────────

      test "technology=fdm returns filaments and empty resins" do
        get api_v1_materials_url, params: { technology: "fdm" }, headers: auth_headers
        json = JSON.parse(response.body)
        assert json["data"]["resins"].empty?, "Expected resins to be empty for fdm filter"
        assert json["data"]["filaments"].any?, "Expected filaments to be present for fdm filter"
      end

      test "technology=resin returns resins and empty filaments" do
        get api_v1_materials_url, params: { technology: "resin" }, headers: auth_headers
        json = JSON.parse(response.body)
        assert json["data"]["filaments"].empty?, "Expected filaments to be empty for resin filter"
        assert json["data"]["resins"].any?, "Expected resins to be present for resin filter"
      end

      test "no technology filter returns both filaments and resins" do
        get api_v1_materials_url, headers: auth_headers
        json = JSON.parse(response.body)
        assert json["data"]["filaments"].any?, "Expected filaments"
        assert json["data"]["resins"].any?, "Expected resins"
      end

      # ── Index - search filter ─────────────────────────────────────────────────

      test "search filter applies to filaments by name" do
        get api_v1_materials_url, params: { q: @filament.name }, headers: auth_headers
        json = JSON.parse(response.body)
        filament_ids = json["data"]["filaments"].map { |f| f["id"] }
        assert_includes filament_ids, @filament.id.to_s
      end

      test "search filter applies to resins by name" do
        get api_v1_materials_url, params: { q: @resin.name }, headers: auth_headers
        json = JSON.parse(response.body)
        resin_ids = json["data"]["resins"].map { |r| r["id"] }
        assert_includes resin_ids, @resin.id.to_s
      end

      test "search with no matches returns empty arrays" do
        get api_v1_materials_url, params: { q: "zzznomatchxxx" }, headers: auth_headers
        json = JSON.parse(response.body)
        assert json["data"]["filaments"].empty?
        assert json["data"]["resins"].empty?
      end

      # ── Index - meta counts ───────────────────────────────────────────────────

      test "meta includes counts" do
        get api_v1_materials_url, headers: auth_headers
        json = JSON.parse(response.body)
        meta = json["meta"]
        assert meta.key?("filaments_count")
        assert meta.key?("resins_count")
        assert meta.key?("total_count")
        assert_equal meta["filaments_count"] + meta["resins_count"], meta["total_count"]
      end

      test "meta includes filament and resin type lists" do
        get api_v1_materials_url, headers: auth_headers
        json = JSON.parse(response.body)
        meta = json["meta"]
        assert meta.key?("filament_types")
        assert meta.key?("resin_types")
        assert meta["filament_types"].is_a?(Array)
        assert meta["resin_types"].is_a?(Array)
      end

      # ── Index - response format ───────────────────────────────────────────────

      test "filament entries have required attributes" do
        get api_v1_materials_url, params: { technology: "fdm" }, headers: auth_headers
        json = JSON.parse(response.body)
        filament = json["data"]["filaments"].first
        assert_not_nil filament
        %w[name brand material_type color diameter spool_weight spool_price cost_per_gram created_at updated_at].each do |attr|
          assert filament["attributes"].key?(attr), "Filament missing attribute: #{attr}"
        end
        assert_equal "filament", filament["type"]
        assert_equal "fdm", filament["technology"]
      end

      test "resin entries have required attributes" do
        get api_v1_materials_url, params: { technology: "resin" }, headers: auth_headers
        json = JSON.parse(response.body)
        resin = json["data"]["resins"].first
        assert_not_nil resin
        %w[name brand resin_type color bottle_volume_ml bottle_price cost_per_ml needs_wash created_at updated_at].each do |attr|
          assert resin["attributes"].key?(attr), "Resin missing attribute: #{attr}"
        end
        assert_equal "resin", resin["type"]
        assert_equal "resin", resin["technology"]
      end

      private

      def auth_headers
        { "Authorization" => "Bearer #{@plain_token}" }
      end
    end
  end
end
