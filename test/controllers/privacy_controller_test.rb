require "test_helper"

class PrivacyControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  # Public pages tests
  test "should get privacy_policy without authentication" do
    get privacy_policy_url
    assert_response :success
    assert_select "h1", I18n.t("gdpr.privacy_policy_title")
  end

  test "should get terms_of_service without authentication" do
    get terms_of_service_url
    assert_response :success
    assert_select "h1", I18n.t("gdpr.terms_of_service_title")
  end

  test "should get cookie_policy without authentication" do
    get cookie_policy_url
    assert_response :success
    assert_select "h1", I18n.t("gdpr.cookie_policy_title")
  end

  # Data export tests
  test "should require authentication for data_export" do
    get data_export_url
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  test "should show data export page when authenticated" do
    sign_in @user
    get data_export_url
    assert_response :success
    assert_select "h1", I18n.t("gdpr.data_export.title")
  end

  test "should export user data as JSON" do
    sign_in @user
    get data_export_url(format: :json)

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_match "attachment", response.headers["Content-Disposition"]

    json = JSON.parse(response.body)
    assert json.key?("user")
    assert json.key?("print_pricings")
    assert json.key?("printers")
    assert json.key?("invoices")
    assert json.key?("filaments")
    assert json.key?("clients")
    assert json.key?("consents")
  end

  test "exported data should include user email" do
    sign_in @user
    get data_export_url(format: :json)

    json = JSON.parse(response.body)
    assert_equal @user.email, json["user"]["email"]
  end

  test "exported data should not include password" do
    sign_in @user
    get data_export_url(format: :json)

    json = JSON.parse(response.body)
    assert_not json["user"].key?("encrypted_password")
    assert_not json["user"].key?("password")
  end

  # Data deletion tests
  test "should require authentication for data_deletion" do
    get data_deletion_url
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  test "should show data deletion page when authenticated" do
    sign_in @user
    get data_deletion_url
    assert_response :success
    assert_select "h1", I18n.t("gdpr.data_deletion.title")
  end

  test "should delete user account and data" do
    sign_in @user
    user_id = @user.id

    assert_difference("User.count", -1) do
      post data_deletion_url
    end

    assert_redirected_to root_url
    assert_match I18n.t("gdpr.account_deleted"), flash[:notice]
    assert_nil User.find_by(id: user_id)
  end

  test "should sign out user after account deletion" do
    sign_in @user
    post data_deletion_url

    # Try to access a protected page
    get print_pricings_url
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  test "should delete associated data on account deletion" do
    sign_in @user

    # Ensure user has associated data
    assert @user.print_pricings.any?, "User should have print_pricings for this test"

    post data_deletion_url

    # Verify associated data is deleted (via dependent: :destroy)
    assert_equal 0, PrintPricing.where(user_id: @user.id).count
    assert_equal 0, Printer.where(user_id: @user.id).count
  end

  test "should show Turbo confirmation for data deletion" do
    sign_in @user
    get data_deletion_url

    assert_select "form[data-turbo-confirm]"
  end
end
