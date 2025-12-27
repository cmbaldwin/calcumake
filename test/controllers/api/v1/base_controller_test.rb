# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class BaseControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @token = @user.api_tokens.create!(name: "Test API Token")
        @plain_token = @token.plain_token
      end

      # Authentication tests
      test "returns 401 without authorization header" do
        get api_v1_me_url
        assert_response :unauthorized

        json = JSON.parse(response.body)
        assert_equal "401", json["errors"].first["status"]
        assert_equal "unauthorized", json["errors"].first["code"]
      end

      test "returns 401 with invalid token" do
        get api_v1_me_url, headers: { "Authorization" => "Bearer invalid_token" }
        assert_response :unauthorized
      end

      test "returns 401 with expired token" do
        @token.update_column(:expires_at, 1.day.ago)

        get api_v1_me_url, headers: { "Authorization" => "Bearer #{@plain_token}" }
        assert_response :unauthorized
      end

      test "returns 401 with revoked token" do
        @token.revoke!

        get api_v1_me_url, headers: { "Authorization" => "Bearer #{@plain_token}" }
        assert_response :unauthorized
      end

      test "accepts valid token" do
        get api_v1_me_url, headers: { "Authorization" => "Bearer #{@plain_token}" }
        assert_response :success
      end

      test "updates last_used_at on successful authentication" do
        assert_nil @token.last_used_at

        get api_v1_me_url, headers: { "Authorization" => "Bearer #{@plain_token}" }

        @token.reload
        assert @token.last_used_at.present?
      end

      # Error response format tests
      test "error response follows JSON:API format" do
        get api_v1_me_url
        assert_response :unauthorized

        json = JSON.parse(response.body)
        assert json.key?("errors")
        assert json["errors"].is_a?(Array)

        error = json["errors"].first
        assert error.key?("status")
        assert error.key?("code")
        assert error.key?("title")
        assert error.key?("detail")
      end

      # Content type tests
      test "returns JSON content type" do
        get api_v1_me_url, headers: { "Authorization" => "Bearer #{@plain_token}" }

        assert_match %r{application/json}, response.content_type
      end

      # Never expires token tests
      test "accepts never-expires token" do
        @token.update_column(:expires_at, nil)

        get api_v1_me_url, headers: { "Authorization" => "Bearer #{@plain_token}" }
        assert_response :success
      end

      # Health endpoint tests (public)
      test "health endpoint does not require authentication" do
        get api_v1_health_url
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal "healthy", json["status"]
        assert json.key?("timestamp")
        assert_equal "v1", json["version"]
      end
    end
  end
end
