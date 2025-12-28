require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get landing page" do
    get root_path
    assert_response :success
    assert_includes @response.body, "CalcuMake"
    assert_includes @response.body, "3D printing"
  end

  test "should redirect landing path to root" do
    get landing_path
    assert_response :redirect
    assert_redirected_to root_path
  end

  test "landing page should include locale suggestion banner" do
    get root_path
    assert_response :success
    assert_includes @response.body, "locale-suggestion-banner"
    assert_includes @response.body, "data-controller=\"locale-suggestion\""
  end

  test "landing page should have proper SEO meta tags" do
    get root_path
    assert_response :success
    assert_includes @response.body, "CalcuMake - 3D Print Cost Calculator"
    assert_includes @response.body, "Make 3D printing profitable"
  end

  test "landing page should include all sections" do
    get root_path
    assert_response :success

    # Check for main sections
    assert_includes @response.body, "hero-section"
    assert_includes @response.body, "problem-section"
    assert_includes @response.body, "features-section"
    assert_includes @response.body, "pricing-section"
    assert_includes @response.body, "faq-section"
    assert_includes @response.body, "final-cta"
  end

  test "landing page should have signup CTAs" do
    get root_path
    assert_response :success
    assert_includes @response.body, new_user_registration_path
    assert_includes @response.body, "Start Calculating Free"
  end

  test "landing page shows for authenticated users" do
    user = users(:one)
    sign_in user

    get root_path
    assert_response :success # Landing page no longer auto-redirects
  end

  test "pricing calculator page should show advanced calculator" do
    get pricing_calculator_path
    assert_response :success
    assert_select "[data-controller='advanced-calculator']"
    assert_select ".pricing-calculator-page"
  end

  test "landing page works in different locales" do
    # Test English (default)
    get root_path
    assert_response :success

    # Test Japanese
    get root_path, params: { locale: "ja" }
    assert_response :success

    # Test Spanish
    get root_path, params: { locale: "es" }
    assert_response :success

    # Test French
    get root_path, params: { locale: "fr" }
    assert_response :success

    # Test Chinese
    get root_path, params: { locale: "zh-CN" }
    assert_response :success

    # Test Hindi
    get root_path, params: { locale: "hi" }
    assert_response :success

    # Test Arabic
    get root_path, params: { locale: "ar" }
    assert_response :success
  end

  test "landing page should include structured data" do
    get root_path
    assert_response :success
    assert_includes @response.body, '"@type":"SoftwareApplication"'
    assert_includes @response.body, '"name":"CalcuMake"'
  end

  test "landing page should include Google Analytics in production" do
    # This test would need to be adjusted for production environment
    get root_path
    assert_response :success
    # In development, GA should not be included
    assert_not_includes @response.body, "gtag"
  end

  test "landing page pricing section should show all tiers" do
    get root_path
    assert_response :success
    assert_includes @response.body, "Free"
    assert_includes @response.body, "Startup"
    assert_includes @response.body, "Pro"
    assert_includes @response.body, "¥150"
    assert_includes @response.body, "¥1,500"
  end

  test "landing page FAQ section should be present" do
    get root_path
    assert_response :success
    assert_includes @response.body, "Frequently Asked Questions"
    assert_includes @response.body, "accordion"
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
  end
end
