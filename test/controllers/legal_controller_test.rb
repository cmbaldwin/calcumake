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

  # Commerce Disclosure Tests (特定商取引法 - Specified Commercial Transactions Act)
  # These tests are MANDATORY to ensure legal compliance with Japanese law

  test "should get commerce disclosure page" do
    get commerce_disclosure_path
    assert_response :success
    assert_includes response.body, I18n.t("legal.commerce_disclosure.title")
  end

  test "commerce disclosure should have correct meta title" do
    get commerce_disclosure_path
    assert_response :success
    assert_select "title", I18n.t("legal.commerce_disclosure.title")
  end

  test "commerce disclosure must contain complete business operator information" do
    get commerce_disclosure_path
    assert_response :success
    # Company name (Japanese and English)
    assert_includes response.body, I18n.t("legal.commerce_disclosure.business_operator.company_name")
    assert_includes response.body, "株式会社モアブ", "Must include Japanese company name"
    assert_includes response.body, "MOAB Co., Ltd.", "Must include English company name"
    # Representative
    assert_includes response.body, I18n.t("legal.commerce_disclosure.business_operator.representative")
    assert_includes response.body, "Cody Baldwin", "Must include representative name"
    # Corporate number
    assert_includes response.body, I18n.t("legal.commerce_disclosure.business_operator.corporate_number")
    assert_includes response.body, "6140001137045", "Must include corporate registration number"
  end

  test "commerce disclosure must contain complete business address" do
    get commerce_disclosure_path
    assert_response :success
    # Postal code
    assert_includes response.body, "〒678-0215", "Must include postal code"
    # Japanese address
    assert_includes response.body, "兵庫県赤穂市御崎151-2", "Must include Japanese address"
    # English address
    assert_includes response.body, "151-2 Misaki, Ako City, Hyogo Prefecture 678-0215, Japan", "Must include English address"
  end

  test "commerce disclosure must contain complete contact information" do
    get commerce_disclosure_path
    assert_response :success
    # Email
    assert_includes response.body, "cody@moab.jp", "Must include contact email"
    # Phone number
    assert_includes response.body, "0791-25-4986", "Must include contact phone number"
    # Business hours
    assert_includes response.body, I18n.t("legal.commerce_disclosure.contact.hours")
  end

  test "commerce disclosure must contain explicit pricing for all tiers" do
    get commerce_disclosure_path
    assert_response :success
    # Free tier
    assert_includes response.body, I18n.t("legal.commerce_disclosure.pricing.free_tier_title")
    assert_includes response.body, "¥0", "Must include Free tier price"
    # Startup tier
    assert_includes response.body, I18n.t("legal.commerce_disclosure.pricing.startup_tier_title")
    assert_includes response.body, "¥150", "Must include Startup tier price"
    # Pro tier
    assert_includes response.body, I18n.t("legal.commerce_disclosure.pricing.pro_tier_title")
    assert_includes response.body, "¥1,500", "Must include Pro tier price"
    # Tax included note
    assert_includes response.body, "tax included", "Must specify prices include tax"
  end

  test "commerce disclosure must contain payment method information" do
    get commerce_disclosure_path
    assert_response :success
    # Credit cards
    assert_includes response.body, "Visa", "Must list Visa"
    assert_includes response.body, "Mastercard", "Must list Mastercard"
    assert_includes response.body, "American Express", "Must list Amex"
    assert_includes response.body, "JCB", "Must list JCB"
    # Payment processor
    assert_includes response.body, "Stripe", "Must mention Stripe as payment processor"
    assert_includes response.body, "PCI DSS", "Must mention PCI DSS compliance"
  end

  test "commerce disclosure must contain payment timing information" do
    get commerce_disclosure_path
    assert_response :success
    assert_includes response.body, I18n.t("legal.commerce_disclosure.payment_timing.title")
    assert_includes response.body, I18n.t("legal.commerce_disclosure.payment_timing.monthly_initial")
    assert_includes response.body, I18n.t("legal.commerce_disclosure.payment_timing.failed_payments_details")
  end

  test "commerce disclosure must contain service delivery information" do
    get commerce_disclosure_path
    assert_response :success
    assert_includes response.body, I18n.t("legal.commerce_disclosure.delivery.title")
    assert_includes response.body, "immediate", "Must specify immediate service delivery"
    assert_includes response.body, "https://calcumake.com", "Must include service URL"
  end

  test "commerce disclosure must contain refund policy" do
    get commerce_disclosure_path
    assert_response :success
    assert_includes response.body, I18n.t("legal.commerce_disclosure.returns.title")
    assert_includes response.body, "7 days", "Must specify 7-day refund window"
    assert_includes response.body, I18n.t("legal.commerce_disclosure.returns.eligibility_initial")
  end

  test "commerce disclosure must contain cancellation policy" do
    get commerce_disclosure_path
    assert_response :success
    assert_includes response.body, I18n.t("legal.commerce_disclosure.cancellation.title")
    assert_includes response.body, I18n.t("legal.commerce_disclosure.cancellation.how_to_step1")
    assert_includes response.body, I18n.t("legal.commerce_disclosure.cancellation.timing_effect")
  end

  test "commerce disclosure must contain dispute resolution information" do
    get commerce_disclosure_path
    assert_response :success
    assert_includes response.body, I18n.t("legal.commerce_disclosure.dispute_resolution.title")
    assert_includes response.body, "cody@moab.jp", "Must include contact for disputes"
    assert_includes response.body, I18n.t("legal.commerce_disclosure.dispute_resolution.jurisdiction")
  end

  test "commerce disclosure must contain compliance statement" do
    get commerce_disclosure_path
    assert_response :success
    # Check for the compliance note (HTML may escape quotes)
    assert(
      response.body.include?(I18n.t("legal.commerce_disclosure.compliance_note")) ||
      response.body.include?("Japan&#39;s Act on Specified Commercial Transactions"),
      "Must include compliance note"
    )
    assert_includes response.body, "特定商取引法", "Must reference Specified Commercial Transactions Act in Japanese"
  end

  test "commerce disclosure must not contain placeholder text" do
    get commerce_disclosure_path
    assert_response :success
    # Ensure no placeholder text remains
    assert_not_includes response.body, "Contact us for", "Must not contain 'Contact us for' placeholder"
    assert_not_includes response.body, "Available upon request", "Must not contain 'Available upon request' placeholder"
    assert_not_includes response.body, "TBD", "Must not contain 'TBD' placeholder"
    assert_not_includes response.body, "Coming soon", "Must not contain 'Coming soon' placeholder"
    assert_not_includes response.body, "[Your", "Must not contain bracket placeholders like [Your Company]"
    assert_not_includes response.body, "[TBD", "Must not contain bracket placeholders like [TBD]"
    assert_not_includes response.body, "[Contact", "Must not contain bracket placeholders like [Contact Info]"
  end

  # API Documentation Tests
  test "should get api_documentation" do
    get api_documentation_path
    assert_response :success
    assert_includes response.body, I18n.t("api_documentation.title")
  end

  test "api_documentation should have correct meta title" do
    get api_documentation_path
    assert_response :success
    assert_select "title", I18n.t("api_documentation.title")
  end

  test "api_documentation should have endpoint sections" do
    get api_documentation_path
    assert_response :success
    assert_includes response.body, I18n.t("api_documentation.endpoints.print_pricings.title")
    assert_includes response.body, I18n.t("api_documentation.endpoints.printers.title")
    assert_includes response.body, I18n.t("api_documentation.endpoints.filaments.title")
    assert_includes response.body, I18n.t("api_documentation.endpoints.resins.title")
    assert_includes response.body, I18n.t("api_documentation.endpoints.clients.title")
  end

  test "api_documentation should include authentication section" do
    get api_documentation_path
    assert_response :success
    assert_includes response.body, I18n.t("api_documentation.authentication.title")
    assert_includes response.body, "Authorization: Bearer"
  end

  test "api_documentation should include code examples" do
    get api_documentation_path
    assert_response :success
    assert_match /curl/i, response.body
    assert_includes response.body, "https://calcumake.com/api/v1"
  end

  test "api_documentation should include getting started section" do
    get api_documentation_path
    assert_response :success
    assert_includes response.body, I18n.t("api_documentation.getting_started.title")
    assert_includes response.body, "https://calcumake.com/api/v1"
  end

  test "api_documentation should include response format section" do
    get api_documentation_path
    assert_response :success
    assert_includes response.body, I18n.t("api_documentation.response_format.title")
  end

  test "api_documentation should include error handling section" do
    get api_documentation_path
    assert_response :success
    assert_includes response.body, I18n.t("api_documentation.errors.title")
    assert_includes response.body, "401"
    assert_includes response.body, "404"
  end
end
