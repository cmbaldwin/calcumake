require "test_helper"

class UserConsentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should create consent with valid params" do
    assert_difference("UserConsent.count") do
      post user_consents_url, params: { consent_type: "cookies", accepted: true }, as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal "cookies", json["consent"]["consent_type"]
  end

  test "should record IP address and user agent" do
    post user_consents_url, params: { consent_type: "cookies", accepted: true }, as: :json

    consent = UserConsent.last
    assert_not_nil consent.ip_address
    assert_not_nil consent.user_agent
  end

  test "should fail without authentication" do
    sign_out @user

    post user_consents_url, params: { consent_type: "cookies", accepted: true }, as: :json
    assert_response :unauthorized
  end

  test "should fail with invalid consent_type" do
    assert_no_difference("UserConsent.count") do
      post user_consents_url, params: { consent_type: "invalid", accepted: true }, as: :json
    end

    assert_response :unprocessable_entity
  end

  test "should fail without consent_type" do
    assert_raises(ActionController::ParameterMissing) do
      post user_consents_url, params: { accepted: true }, as: :json
    end
  end

  test "should fail without accepted parameter" do
    assert_raises(ActionController::ParameterMissing) do
      post user_consents_url, params: { consent_type: "cookies" }, as: :json
    end
  end

  test "should accept consent as false" do
    assert_difference("UserConsent.count") do
      post user_consents_url, params: { consent_type: "cookies", accepted: false }, as: :json
    end

    assert_response :created
    assert_equal false, UserConsent.last.accepted
  end

  test "should handle HTML format" do
    post user_consents_url, params: { consent_type: "cookies", accepted: true }
    assert_response :redirect
    assert_match I18n.t("gdpr.consent_recorded"), flash[:notice]
  end
end
