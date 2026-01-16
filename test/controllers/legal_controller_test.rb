require "test_helper"

class LegalControllerTest < ActionDispatch::IntegrationTest
  test "should get privacy policy" do
    get privacy_policy_path
    assert_response :success
    assert_includes response.body, I18n.t("legal.privacy_policy.title")
    assert_includes response.body, I18n.t("legal.privacy_policy.information_we_collect.title")
  end

  test "should get user agreement" do
    get user_agreement_path
    assert_response :success
    assert_includes response.body, I18n.t("legal.user_agreement.title")
    assert_includes response.body, I18n.t("legal.user_agreement.acceptance.title")
  end

  test "should get support page" do
    get support_path
    assert_response :success
    assert_includes response.body, I18n.t("support.title")
    assert_includes response.body, "cody@moab.jp"
  end

  test "privacy policy should have correct meta title" do
    get privacy_policy_path
    assert_response :success
    assert_select "title", I18n.t("legal.privacy_policy.title")
  end

  test "user agreement should have correct meta title" do
    get user_agreement_path
    assert_response :success
    assert_select "title", I18n.t("legal.user_agreement.title")
  end

  test "support page should have correct meta title" do
    get support_path
    assert_response :success
    assert_select "title", I18n.t("support.title")
  end

  test "privacy policy should contain AdSense disclosure" do
    get privacy_policy_path
    assert_response :success
    assert_includes response.body, I18n.t("legal.privacy_policy.advertising.title")
    assert_includes response.body, I18n.t("legal.privacy_policy.advertising.google_adsense")
  end

  test "user agreement should contain calculation disclaimers" do
    get user_agreement_path
    assert_response :success
    assert_includes response.body, I18n.t("legal.user_agreement.disclaimers.title")
    assert_includes response.body, I18n.t("legal.user_agreement.disclaimers.calculations_estimates")
  end

  test "support page should have mailto link" do
    get support_path
    assert_response :success
    assert_select "a[href='mailto:cody@moab.jp']"
  end

  # Markdown format tests
  test "should get privacy policy in markdown format" do
    get privacy_policy_path(format: :md)
    assert_response :success
    assert_equal "text/markdown; charset=utf-8", response.content_type
    assert_includes response.body, "# #{I18n.t('legal.privacy_policy.title')}"
    assert_includes response.body, "---" # frontmatter
  end

  test "should get user agreement in markdown format" do
    get user_agreement_path(format: :md)
    assert_response :success
    assert_equal "text/markdown; charset=utf-8", response.content_type
    assert_includes response.body, "# #{I18n.t('legal.user_agreement.title')}"
    assert_includes response.body, "---" # frontmatter
  end

  test "should get support page in markdown format" do
    get support_path(format: :md)
    assert_response :success
    assert_equal "text/markdown; charset=utf-8", response.content_type
    assert_includes response.body, "# #{I18n.t('support.title')}"
    assert_includes response.body, "cody@moab.jp"
  end

  test "markdown format should have proper cache headers" do
    get privacy_policy_path(format: :md)
    assert_response :success
    assert_match /public/, response.headers["Cache-Control"]
  end

  test "markdown format should have alternate language links in frontmatter" do
    get privacy_policy_path(format: :md)
    assert_response :success
    assert_includes response.body, "alternate_languages:"
    assert_includes response.body, "language: en"
  end

  test "markdown privacy policy should contain all sections" do
    get privacy_policy_path(format: :md)
    assert_response :success
    assert_includes response.body, I18n.t("legal.privacy_policy.information_we_collect.title")
    assert_includes response.body, I18n.t("legal.privacy_policy.data_security.title")
    assert_includes response.body, I18n.t("legal.privacy_policy.contact.title")
  end

  test "markdown user agreement should contain disclaimers" do
    get user_agreement_path(format: :md)
    assert_response :success
    assert_includes response.body, I18n.t("legal.user_agreement.disclaimers.title")
    assert_includes response.body, I18n.t("legal.user_agreement.disclaimers.calculations_estimates")
  end

  test "markdown support page should have FAQ content" do
    get support_path(format: :md)
    assert_response :success
    assert_includes response.body, I18n.t("support.faq.title")
    assert_includes response.body, I18n.t("support.faq.delete_account.question")
  end
end
