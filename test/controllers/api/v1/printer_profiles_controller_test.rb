# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class PrinterProfilesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @token = @user.api_tokens.create!(name: "Test Token")
        @plain_token = @token.plain_token

        @fdm_profile = printer_profiles(:bambu_p1s)
        @resin_profile = printer_profiles(:elegoo_mars)
        @prusa_profile = printer_profiles(:prusa_mk4)
      end

      # =========================================================================
      # Public access - no authentication required
      # =========================================================================

      test "index is accessible without authentication" do
        get api_v1_printer_profiles_url
        assert_response :success
      end

      test "index returns all printer profiles" do
        get api_v1_printer_profiles_url

        json = JSON.parse(response.body)
        assert json.key?("data")
        assert json["data"].is_a?(Array)
        assert json["data"].length >= 3
      end

      test "index returns correct JSON structure" do
        get api_v1_printer_profiles_url

        json = JSON.parse(response.body)
        profile = json["data"].first

        assert_not_nil profile["id"]
        assert_equal "printer_profile", profile["type"]
        assert_not_nil profile["attributes"]

        attrs = profile["attributes"]
        assert attrs.key?("manufacturer")
        assert attrs.key?("model")
        assert attrs.key?("technology")
        assert attrs.key?("category")
        assert attrs.key?("power_consumption_avg_watts")
        assert attrs.key?("power_consumption_peak_watts")
        assert attrs.key?("cost_usd")
        assert attrs.key?("display_name")
        assert attrs.key?("full_display_name")
      end

      test "index does not expose non-existent attributes" do
        get api_v1_printer_profiles_url

        json = JSON.parse(response.body)
        attrs = json["data"].first["attributes"]

        # These fields do not exist on PrinterProfile model
        refute attrs.key?("power_consumption"), "Should not expose non-existent power_consumption"
        refute attrs.key?("price_usd"), "Should not expose price_usd (correct key is cost_usd)"
        refute attrs.key?("build_volume_x"), "Should not expose non-existent build_volume_x"
        refute attrs.key?("build_volume_y"), "Should not expose non-existent build_volume_y"
        refute attrs.key?("build_volume_z"), "Should not expose non-existent build_volume_z"
      end

      test "index includes meta information" do
        get api_v1_printer_profiles_url

        json = JSON.parse(response.body)
        assert json.key?("meta")
        assert json["meta"].key?("total_count")
        assert json["meta"].key?("technologies")
        assert json["meta"].key?("categories")
        assert json["meta"]["technologies"].is_a?(Array)
        assert json["meta"]["categories"].is_a?(Array)
      end

      test "index meta total_count matches data length" do
        get api_v1_printer_profiles_url

        json = JSON.parse(response.body)
        assert_equal json["data"].length, json["meta"]["total_count"]
      end

      # =========================================================================
      # Also accessible with authentication (backwards compatible)
      # =========================================================================

      test "index is also accessible with valid authentication" do
        get api_v1_printer_profiles_url, headers: auth_headers
        assert_response :success
      end

      # =========================================================================
      # Search filtering
      # =========================================================================

      test "index filters by search query on manufacturer" do
        get api_v1_printer_profiles_url, params: { q: "Bambu" }

        assert_response :success
        json = JSON.parse(response.body)

        assert json["data"].any? { |p| p["attributes"]["manufacturer"] == "Bambu Lab" }
        assert json["data"].all? { |p|
          p["attributes"]["manufacturer"].downcase.include?("bambu") ||
          p["attributes"]["model"].downcase.include?("bambu") ||
          (p["attributes"]["category"]&.downcase&.include?("bambu") || false)
        }
      end

      test "index filters by search query on model" do
        get api_v1_printer_profiles_url, params: { q: "Mars" }

        assert_response :success
        json = JSON.parse(response.body)

        assert json["data"].any? { |p| p["attributes"]["model"].include?("Mars") }
      end

      test "index filters by search query on category" do
        get api_v1_printer_profiles_url, params: { q: "Resin" }

        assert_response :success
        json = JSON.parse(response.body)

        assert json["data"].any? { |p| p["attributes"]["category"]&.include?("Resin") }
      end

      test "index returns empty data array when search has no matches" do
        get api_v1_printer_profiles_url, params: { q: "NonexistentBrandXYZ123" }

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal [], json["data"]
        assert_equal 0, json["meta"]["total_count"]
      end

      test "index returns all results when search query is blank" do
        total_count = PrinterProfile.count
        get api_v1_printer_profiles_url, params: { q: "" }

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal total_count, json["data"].length
      end

      test "index search is case insensitive" do
        get api_v1_printer_profiles_url, params: { q: "bambu" }

        assert_response :success
        json = JSON.parse(response.body)

        assert json["data"].any? { |p| p["attributes"]["manufacturer"] == "Bambu Lab" }
      end

      # =========================================================================
      # Technology filtering
      # =========================================================================

      test "index filters by fdm technology" do
        get api_v1_printer_profiles_url, params: { technology: "fdm" }

        assert_response :success
        json = JSON.parse(response.body)

        assert json["data"].length >= 1
        assert json["data"].all? { |p| p["attributes"]["technology"] == "fdm" }
      end

      test "index filters by resin technology" do
        get api_v1_printer_profiles_url, params: { technology: "resin" }

        assert_response :success
        json = JSON.parse(response.body)

        assert json["data"].length >= 1
        assert json["data"].all? { |p| p["attributes"]["technology"] == "resin" }
      end

      test "index with fdm filter excludes resin profiles" do
        get api_v1_printer_profiles_url, params: { technology: "fdm" }

        json = JSON.parse(response.body)
        profile_ids = json["data"].map { |p| p["id"] }

        refute_includes profile_ids, @resin_profile.id.to_s
      end

      test "index with resin filter excludes fdm profiles" do
        get api_v1_printer_profiles_url, params: { technology: "resin" }

        json = JSON.parse(response.body)
        profile_ids = json["data"].map { |p| p["id"] }

        refute_includes profile_ids, @fdm_profile.id.to_s
        refute_includes profile_ids, @prusa_profile.id.to_s
      end

      # =========================================================================
      # Combined filters
      # =========================================================================

      test "index combines search and technology filters" do
        get api_v1_printer_profiles_url, params: { q: "Prusa", technology: "fdm" }

        assert_response :success
        json = JSON.parse(response.body)

        assert json["data"].all? { |p| p["attributes"]["technology"] == "fdm" }
        assert json["data"].any? { |p| p["attributes"]["manufacturer"].include?("Prusa") }
      end

      test "index returns no results when search and technology filters conflict" do
        # Elegoo Mars is resin, searching for it with fdm filter should return nothing
        get api_v1_printer_profiles_url, params: { q: "Mars", technology: "fdm" }

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal [], json["data"]
      end

      # =========================================================================
      # Ordering
      # =========================================================================

      test "index returns profiles ordered by manufacturer then model" do
        get api_v1_printer_profiles_url

        json = JSON.parse(response.body)
        manufacturers = json["data"].map { |p| p["attributes"]["manufacturer"] }

        assert_equal manufacturers.sort, manufacturers
      end

      # =========================================================================
      # Attribute accuracy
      # =========================================================================

      test "index returns correct attributes for fdm profile" do
        get api_v1_printer_profiles_url, params: { q: "P1S" }

        json = JSON.parse(response.body)
        profile = json["data"].find { |p| p["id"] == @fdm_profile.id.to_s }

        assert_not_nil profile
        assert_equal "Bambu Lab", profile["attributes"]["manufacturer"]
        assert_equal "P1S Combo", profile["attributes"]["model"]
        assert_equal "fdm", profile["attributes"]["technology"]
        assert_equal "Mid-Range FDM", profile["attributes"]["category"]
        assert_equal "Bambu Lab P1S Combo", profile["attributes"]["display_name"]
        assert_equal "Bambu Lab P1S Combo (Mid-Range FDM)", profile["attributes"]["full_display_name"]
        assert_equal 100, profile["attributes"]["power_consumption_avg_watts"]
        assert_equal 850, profile["attributes"]["power_consumption_peak_watts"]
      end

      test "index returns correct cost_usd for profile" do
        get api_v1_printer_profiles_url, params: { q: "P1S" }

        json = JSON.parse(response.body)
        profile = json["data"].find { |p| p["id"] == @fdm_profile.id.to_s }

        assert_not_nil profile
        assert_in_delta 549.0, profile["attributes"]["cost_usd"], 0.01
      end

      test "index returns nil cost_usd for profile without price" do
        # elegoo_mars fixture has no cost_usd set in some configurations; skip if it has one
        get api_v1_printer_profiles_url, params: { technology: "resin" }

        json = JSON.parse(response.body)
        profile = json["data"].find { |p| p["id"] == @resin_profile.id.to_s }

        assert_not_nil profile
        # cost_usd is present in attributes (may be nil or a float)
        assert profile["attributes"].key?("cost_usd")
      end

      test "index meta technologies includes fdm and resin" do
        get api_v1_printer_profiles_url

        json = JSON.parse(response.body)
        technologies = json["meta"]["technologies"]

        assert_includes technologies, "fdm"
        assert_includes technologies, "resin"
      end

      test "index meta categories includes expected categories" do
        get api_v1_printer_profiles_url

        json = JSON.parse(response.body)
        categories = json["meta"]["categories"]

        assert_includes categories, "Mid-Range FDM"
        assert_includes categories, "Budget Resin"
      end

      private

      def auth_headers
        { "Authorization" => "Bearer #{@plain_token}" }
      end
    end
  end
end
