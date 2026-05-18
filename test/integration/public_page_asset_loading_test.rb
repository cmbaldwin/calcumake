require "test_helper"

# US-008: Eliminate avoidable public-page CSS preload warnings
#
# Audits the application layout to confirm:
#  1. The Bootstrap Icons stylesheet uses the media="print" async pattern
#     (not the <link rel="preload"> pattern which causes Chrome console warnings).
#  2. No extraneous rel="preload" as="style" tags exist in the shared layout.
#  3. The landing page, sign-up page, blog index, support page, and calculator
#     all render without producing a <link rel="preload" as="style"> element.
class PublicPageAssetLoadingTest < ActionDispatch::IntegrationTest
  PRELOAD_STYLE_PATTERN = /rel=["']preload["'][^>]*as=["']style["']/i

  test "application layout does not use rel=preload for Bootstrap Icons stylesheet" do
    layout_path = Rails.root.join("app/views/layouts/application.html.erb")
    layout_source = File.read(layout_path)

    assert_no_match PRELOAD_STYLE_PATTERN, layout_source,
      "application.html.erb must not contain `rel=preload as=style` — " \
      "use `media=print onload=this.media='all'` instead to avoid CSS preload console warnings."
  end

  test "Bootstrap Icons link uses media=print async pattern in layout" do
    layout_path = Rails.root.join("app/views/layouts/application.html.erb")
    layout_source = File.read(layout_path)

    # The approved async pattern
    assert_match(/bootstrap-icons.*media=["']print["'][^>]*onload/i, layout_source,
      "Bootstrap Icons stylesheet should use media=\"print\" onload=\"this.media='all'\" pattern.")
  end

  test "landing page renders without preload style links" do
    get root_path
    assert_response :success
    assert_no_match PRELOAD_STYLE_PATTERN, response.body,
      "Landing page (/) must not emit <link rel=preload as=style> elements."
  end

  test "sign-up page renders without preload style links" do
    get new_user_registration_path
    assert_response :success
    assert_no_match PRELOAD_STYLE_PATTERN, response.body,
      "Sign-up page (/users/sign_up) must not emit <link rel=preload as=style> elements."
  end

  test "blog index renders without preload style links" do
    get articles_path
    assert_response :success
    assert_no_match PRELOAD_STYLE_PATTERN, response.body,
      "Blog index (/blog) must not emit <link rel=preload as=style> elements."
  end

  test "support page renders without preload style links" do
    get support_path
    assert_response :success
    assert_no_match PRELOAD_STYLE_PATTERN, response.body,
      "Support page (/support) must not emit <link rel=preload as=style> elements."
  end

  test "pricing calculator renders without preload style links" do
    get pricing_calculator_path
    assert_response :success
    assert_no_match PRELOAD_STYLE_PATTERN, response.body,
      "Pricing calculator must not emit <link rel=preload as=style> elements."
  end
end
