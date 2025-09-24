require "test_helper"

class FooterTest < ActionDispatch::IntegrationTest
  test "footer contains copyright information" do
    get support_path
    assert_response :success

    assert_select "footer"
    assert_includes response.body, "© #{Date.current.year}"
    assert_includes response.body, "株式会社モアブ (MOAB Co., Ltd.)"
  end

  test "footer contains legal page links" do
    get support_path
    assert_response :success

    assert_select "footer a[href='#{support_path}']", text: I18n.t("support.nav_title")
    assert_select "footer a[href='#{privacy_policy_path}']", text: I18n.t("legal.privacy_policy.nav_title")
    assert_select "footer a[href='#{user_agreement_path}']", text: I18n.t("legal.user_agreement.nav_title")
  end

  test "footer is present on all main pages" do
    pages_to_test = [
      support_path,
      privacy_policy_path,
      user_agreement_path
    ]

    pages_to_test.each do |page_path|
      get page_path
      assert_response :success
      assert_select "footer", minimum: 1, message: "Footer should be present on #{page_path}"
      assert_select "footer a[href='#{support_path}']", minimum: 1, message: "Support link should be in footer on #{page_path}"
    end
  end

  test "footer has responsive layout classes" do
    get support_path
    assert_response :success

    assert_select "footer.bg-white.p-3.border-top.mt-4"
    assert_select "footer .row"
    assert_select "footer .col-md-6"
  end
end
