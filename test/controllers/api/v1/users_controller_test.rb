# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class UsersControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @other_user = users(:two)
        @token = @user.api_tokens.create!(name: "Test Token")
        @plain_token = @token.plain_token
      end

      # Authentication tests
      test "show requires authentication" do
        get api_v1_me_url
        assert_response :unauthorized
      end

      test "update requires authentication" do
        patch api_v1_me_url, params: { user: { default_currency: "EUR" } }
        assert_response :unauthorized
      end

      test "export_data requires authentication" do
        get export_api_v1_me_url
        assert_response :unauthorized
      end

      test "usage_stats requires authentication" do
        get usage_api_v1_me_url
        assert_response :unauthorized
      end

      # Show tests
      test "show returns current user details" do
        get api_v1_me_url, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal @user.id.to_s, json["data"]["id"]
        assert_equal "user", json["data"]["type"]
        assert_equal @user.email, json["data"]["attributes"]["email"]
        assert_equal @user.default_currency, json["data"]["attributes"]["default_currency"]
        assert_equal @user.plan, json["data"]["attributes"]["plan"]
        assert json["data"]["attributes"].key?("default_energy_cost_per_kwh")
        assert json["data"]["attributes"].key?("locale")
        assert json["data"]["attributes"].key?("created_at")
        assert json["data"]["attributes"].key?("updated_at")
      end

      test "show does not expose sensitive fields" do
        get api_v1_me_url, headers: auth_headers

        json = JSON.parse(response.body)

        # Should not expose password or other sensitive data
        refute json["data"]["attributes"].key?("encrypted_password")
        refute json["data"]["attributes"].key?("reset_password_token")
        refute json["data"]["attributes"].key?("confirmation_token")
      end

      # Update tests
      test "update modifies user settings" do
        patch api_v1_me_url, params: {
          user: {
            default_currency: "EUR",
            default_energy_cost_per_kwh: 0.15
          }
        }, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal "EUR", json["data"]["attributes"]["default_currency"]
        assert_equal 0.15, json["data"]["attributes"]["default_energy_cost_per_kwh"].to_f
        @user.reload
        assert_equal "EUR", @user.default_currency
      end

      test "update allows changing locale" do
        patch api_v1_me_url, params: {
          user: { locale: "ja" }
        }, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal "ja", json["data"]["attributes"]["locale"]
      end

      test "update allows changing default prep time settings" do
        patch api_v1_me_url, params: {
          user: {
            default_prep_time_minutes: 15,
            default_prep_cost_per_hour: 20.0
          }
        }, headers: auth_headers

        assert_response :success
        @user.reload

        assert_equal 15, @user.default_prep_time_minutes
        assert_equal 20.0, @user.default_prep_cost_per_hour.to_f
      end

      test "update allows changing default postprocessing settings" do
        patch api_v1_me_url, params: {
          user: {
            default_postprocessing_time_minutes: 30,
            default_postprocessing_cost_per_hour: 25.0
          }
        }, headers: auth_headers

        assert_response :success
        @user.reload

        assert_equal 30, @user.default_postprocessing_time_minutes
        assert_equal 25.0, @user.default_postprocessing_cost_per_hour.to_f
      end

      test "update allows changing default VAT and other costs" do
        patch api_v1_me_url, params: {
          user: {
            default_other_costs: 5.0,
            default_vat_percentage: 10.0
          }
        }, headers: auth_headers

        assert_response :success
        @user.reload

        assert_equal 5.0, @user.default_other_costs.to_f
        assert_equal 10.0, @user.default_vat_percentage.to_f
      end

      test "update with invalid data returns validation errors" do
        # Setting currency to empty string should fail presence validation
        patch api_v1_me_url, params: {
          user: { default_currency: "" }
        }, headers: auth_headers

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)

        assert json.key?("errors")
        assert json["errors"].first["code"] == "validation_error"
      end

      test "update does not allow changing email" do
        original_email = @user.email

        patch api_v1_me_url, params: {
          user: { email: "hacker@example.com" }
        }, headers: auth_headers

        @user.reload
        assert_equal original_email, @user.email
      end

      # Export data tests
      test "export_data returns user data export" do
        get export_api_v1_me_url, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert json.key?("data")
      end

      # Usage stats tests
      test "usage_stats returns counts" do
        get usage_api_v1_me_url, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert json["data"].key?("print_pricings_count")
        assert json["data"].key?("printers_count")
        assert json["data"].key?("filaments_count")
        assert json["data"].key?("clients_count")
        assert json["data"].key?("invoices_count")
        assert json["data"].key?("plan")
        assert json["data"].key?("limits")
      end

      test "usage_stats returns plan limits" do
        get usage_api_v1_me_url, headers: auth_headers

        json = JSON.parse(response.body)

        assert json["data"]["limits"].key?("print_pricings")
        assert json["data"]["limits"].key?("printers")
        assert json["data"]["limits"].key?("filaments")
        assert json["data"]["limits"].key?("clients")
      end

      test "usage_stats returns correct counts for user" do
        get usage_api_v1_me_url, headers: auth_headers

        json = JSON.parse(response.body)

        assert_equal @user.print_pricings.count, json["data"]["print_pricings_count"]
        assert_equal @user.printers.count, json["data"]["printers_count"]
        assert_equal @user.filaments.count, json["data"]["filaments_count"]
        assert_equal @user.clients.count, json["data"]["clients_count"]
        assert_equal @user.invoices.count, json["data"]["invoices_count"]
      end

      # Response format tests
      test "responses include correct content type" do
        get api_v1_me_url, headers: auth_headers

        assert_match %r{application/json}, response.content_type
      end

      # Token isolation tests
      test "different user tokens return different user data" do
        other_token = @other_user.api_tokens.create!(name: "Other User Token")
        other_plain_token = other_token.plain_token

        get api_v1_me_url, headers: { "Authorization" => "Bearer #{other_plain_token}" }

        json = JSON.parse(response.body)
        assert_equal @other_user.id.to_s, json["data"]["id"]
        assert_equal @other_user.email, json["data"]["attributes"]["email"]
      end

      # PUT method tests
      test "update works with PUT method" do
        put api_v1_me_url, params: {
          user: { default_currency: "GBP" }
        }, headers: auth_headers

        assert_response :success
        @user.reload
        assert_equal "GBP", @user.default_currency
      end

      private

      def auth_headers
        { "Authorization" => "Bearer #{@plain_token}" }
      end
    end
  end
end
