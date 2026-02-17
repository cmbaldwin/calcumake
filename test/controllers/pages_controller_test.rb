require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  # =========================================================================
  # Root Landing Page (new AI-first minimal page)
  # =========================================================================

  test "should get landing page" do
    get root_path
    assert_response :success
    assert_includes @response.body, "calcumake"
    assert_includes @response.body, "minimal-landing-page"
  end

  test "landing page has 3D viewer" do
    get root_path
    assert_response :success
    assert_includes @response.body, 'data-controller="landing-3d'
  end

  test "landing page has upload zone" do
    get root_path
    assert_response :success
    assert_includes @response.body, 'data-controller="landing-upload'
    assert_includes @response.body, ".stl,.3mf"
  end

  test "landing page has chat input" do
    get root_path
    assert_response :success
    assert_includes @response.body, 'data-controller="landing-chat'
    assert_includes @response.body, "ai-chat"
  end

  test "landing page hides navbar via body class" do
    get root_path
    assert_response :success
    assert_includes @response.body, "minimal-landing"
  end

  test "landing page links to about, sign in, sign up" do
    get root_path
    assert_response :success
    assert_includes @response.body, about_path
    assert_includes @response.body, new_user_session_path
    assert_includes @response.body, new_user_registration_path
  end

  test "landing page has proper SEO meta tags" do
    get root_path
    assert_response :success
    assert_includes @response.body, "CalcuMake"
  end

  test "landing page should include structured data" do
    get root_path
    assert_response :success
    assert_includes @response.body, '"@type":"SoftwareApplication"'
    assert_includes @response.body, '"name":"CalcuMake"'
  end

  test "landing page works in different locales" do
    I18n.available_locales.each do |locale|
      get root_path, params: { locale: locale }
      assert_response :success
    end
  end

  test "landing page should not include Google Analytics in development" do
    get root_path
    assert_response :success
    assert_not_includes @response.body, "gtag"
  end

  # =========================================================================
  # About Page (moved old landing content)
  # =========================================================================

  test "about page should include all original sections" do
    get about_path
    assert_response :success
    assert_includes @response.body, "hero-section"
    assert_includes @response.body, "problem-section"
    assert_includes @response.body, "features-section"
    assert_includes @response.body, "pricing-section"
    assert_includes @response.body, "faq-section"
    assert_includes @response.body, "final-cta"
  end

  test "about page has proper SEO" do
    get about_path
    assert_response :success
    assert_includes @response.body, '"@type":"SoftwareApplication"'
  end

  test "about page has signup CTAs" do
    get about_path
    assert_response :success
    assert_includes @response.body, new_user_registration_path
  end

  test "about page pricing section should show all tiers" do
    get about_path
    assert_response :success
    assert_includes @response.body, "Free"
    assert_includes @response.body, "Startup"
    assert_includes @response.body, "Pro"
  end

  test "about page works in different locales" do
    I18n.available_locales.each do |locale|
      get about_path, params: { locale: locale }
      assert_response :success
    end
  end

  # =========================================================================
  # Pricing Calculator
  # =========================================================================

  test "pricing calculator page should show advanced calculator" do
    get pricing_calculator_path
    assert_response :success
    assert_select "[data-controller='advanced-calculator']"
    assert_select ".pricing-calculator-page"
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
