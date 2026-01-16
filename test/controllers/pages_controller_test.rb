require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get about page" do
    get about_path
    assert_response :success
    assert_includes response.body, I18n.t("pages.about.title")
    assert_includes response.body, I18n.t("pages.about.features.heading")
  end

  test "about page should have correct meta title" do
    get about_path
    assert_response :success
    assert_select "title", I18n.t("pages.about.title")
  end

  test "about page should display features" do
    get about_path
    assert_response :success
    assert_includes response.body, I18n.t("pages.about.features.multi_plate.title")
    assert_includes response.body, I18n.t("pages.about.features.cost_tracking.title")
    assert_includes response.body, I18n.t("pages.about.features.invoice.title")
  end

  test "about page should display how it works section" do
    get about_path
    assert_response :success
    assert_includes response.body, I18n.t("pages.about.how_it_works.heading")
    assert_includes response.body, I18n.t("pages.about.how_it_works.step1.title")
  end

  test "about page should display pricing information" do
    get about_path
    assert_response :success
    assert_includes response.body, I18n.t("pages.about.pricing.heading")
    assert_includes response.body, I18n.t("pages.about.pricing.content")
  end

  test "about page should display company information" do
    get about_path
    assert_response :success
    assert_includes response.body, I18n.t("pages.about.company.heading")
    assert_includes response.body, "cody@moab.jp"
  end

  # Markdown format tests
  test "should get about page in markdown format" do
    get about_path(format: :md)
    assert_response :success
    assert_equal "text/markdown; charset=utf-8", response.content_type
    assert_includes response.body, "# #{I18n.t('pages.about.title')}"
    assert_includes response.body, "---" # frontmatter
  end

  test "markdown about page should have proper cache headers" do
    get about_path(format: :md)
    assert_response :success
    assert_match /public/, response.headers["Cache-Control"]
  end

  test "markdown about page should contain all sections" do
    get about_path(format: :md)
    assert_response :success
    assert_includes response.body, I18n.t("pages.about.features.heading")
    assert_includes response.body, I18n.t("pages.about.how_it_works.heading")
    assert_includes response.body, I18n.t("pages.about.technology.heading")
    assert_includes response.body, I18n.t("pages.about.pricing.heading")
  end

  test "markdown about page should have frontmatter metadata" do
    get about_path(format: :md)
    assert_response :success
    assert_includes response.body, "title:"
    assert_includes response.body, "language: en"
    assert_includes response.body, "type: about_page"
    assert_includes response.body, "alternate_languages:"
  end

  # Markdown index tests
  test "should get markdown index" do
    get markdown_index_path(format: :md)
    assert_response :success
    assert_equal "text/markdown; charset=utf-8", response.content_type
  end

  test "markdown index should list all available markdown content" do
    get markdown_index_path(format: :md)
    assert_response :success
    assert_includes response.body, "Markdown Content Directory"
    assert_includes response.body, "About CalcuMake"
    assert_includes response.body, "Support"
    assert_includes response.body, "Privacy Policy"
    assert_includes response.body, "User Agreement"
  end

  test "markdown index should have links to all markdown pages" do
    get markdown_index_path(format: :md)
    assert_response :success
    assert_includes response.body, about_url(format: :md)
    assert_includes response.body, support_url(format: :md)
    assert_includes response.body, privacy_policy_url(format: :md)
    assert_includes response.body, user_agreement_url(format: :md)
  end

  test "markdown index html format should redirect to about" do
    get markdown_index_path
    assert_redirected_to about_path
  end
end
