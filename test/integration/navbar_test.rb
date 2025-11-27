require "test_helper"

class NavbarTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
  end

  test "navbar shows help dropdown for authenticated users" do
    sign_in @user
    get print_pricings_path
    assert_response :success

    # Should contain help dropdown
    assert_select "a#helpDropdown", text: I18n.t("nav.help")

    # Should contain dropdown menu items (support is now outside dropdown)
    assert_select ".dropdown-menu a[href='#{privacy_policy_path}']", text: I18n.t("legal.privacy_policy.nav_title")
    assert_select ".dropdown-menu a[href='#{user_agreement_path}']", text: I18n.t("legal.user_agreement.nav_title")

    # Support link should be outside dropdown, next to locale switcher
    assert_select "a[href='#{support_path}']", text: I18n.t("support.nav_title")
  end

  test "navbar shows direct support link for non-authenticated users" do
    get support_path
    assert_response :success

    # Should contain direct support link
    assert_select "a[href='#{support_path}']", text: I18n.t("support.nav_title")

    # Should not contain help dropdown
    assert_select "a#helpDropdown", false
  end

  test "navbar contains language selector" do
    get support_path
    assert_response :success

    # Should contain language selector form
    assert_select "form[action='#{switch_locale_path}']"
    assert_select "select[name='locale']"

    # Should contain all supported languages
    assert_select "option[value='en']"
    assert_select "option[value='es']"
    assert_select "option[value='ja']"
    assert_select "option[value='zh-CN']"
    assert_select "option[value='hi']"
    assert_select "option[value='fr']"
    assert_select "option[value='ar']"
  end

  test "navbar brand links to root path" do
    get support_path
    assert_response :success
    assert_select "a.navbar-brand[href='#{root_path}']", text: I18n.t("nav.brand")
  end

  test "navbar shows appropriate links for authenticated users" do
    sign_in @user
    get print_pricings_path
    assert_response :success

    assert_select "a[href='#{new_print_pricing_path}']", text: I18n.t("nav.new_pricing")
    assert_select "a[href='#{printers_path}']", text: I18n.t("nav.my_printers")
    assert_select "a[href='#{user_profile_path}']", text: I18n.t("nav.profile")
    assert_select "a[href='#{destroy_user_session_path}']", text: I18n.t("nav.sign_out")
  end

  test "navbar shows sign in and sign up for non-authenticated users" do
    get support_path
    assert_response :success

    assert_select "a[href='#{new_user_session_path}']", text: I18n.t("nav.sign_in")
    assert_select "a[href='#{new_user_registration_path}']", text: I18n.t("nav.sign_up")
  end

  test "navbar is responsive with toggle button" do
    get support_path
    assert_response :success

    assert_select "button.navbar-toggler[data-bs-toggle='collapse']"
    assert_select ".collapse.navbar-collapse#navbarNav"
  end
end
