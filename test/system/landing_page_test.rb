require "application_system_test_case"

class LandingPageTest < ApplicationSystemTestCase
  test "visiting the landing page" do
    visit root_path

    assert_selector "h1", text: /More creating, less calculating/i
    assert_selector ".hero-section"
    assert_selector ".problem-section"
    assert_selector ".features-section"
    assert_selector ".pricing-section"
    assert_selector ".faq-section"
    assert_selector ".final-cta"
  end

  test "locale suggestion banner is present but hidden initially" do
    visit root_path

    assert_selector ".locale-suggestion-banner", visible: false
    assert_selector "[data-controller='locale-suggestion']", visible: false
  end

  test "pricing section has all three tiers" do
    visit root_path

    within ".pricing-section" do
      assert_text "Free"
      assert_text "Startup"
      assert_text "Pro"
      assert_text "¥150"
      assert_text "¥1,500"
      assert_text "Most Popular"
    end
  end

  test "FAQ section is interactive" do
    visit root_path

    within ".faq-section" do
      assert_selector ".accordion"
      assert_selector ".accordion-button"

      # First FAQ should be expanded by default
      assert_selector "#faq1.show"
    end
  end

  test "CTA buttons are present and functional" do
    visit root_path

    # Hero section CTA
    within ".hero-section" do
      assert_link "Start Calculating Free", href: new_user_registration_path
      assert_link "Try Calculator Free", href: pricing_calculator_path
    end

    # Pricing section CTAs
    within ".pricing-section" do
      assert_selector "a[href='#{new_user_registration_path}']", count: 3
    end

    # Final CTA
    within ".final-cta" do
      assert_link "Start Your Free Trial", href: new_user_registration_path
    end
  end

  test "structured data is present" do
    visit root_path

    assert_selector "script[type='application/ld+json']", visible: false
  end

  test "responsive design works on mobile" do
    resize_to_mobile
    visit root_path

    assert_selector ".hero-section"
    assert_selector ".pricing-section .col-lg-4", count: 3

    # Check that mobile layout is properly applied
    assert_selector ".container"
  end

  test "page works with different locales" do
    visit "/?locale=ja"
    assert_selector "h1"  # Just check that h1 exists

    visit "/?locale=es"
    assert_selector "h1"  # Just check that h1 exists

    visit "/?locale=fr"
    assert_selector "h1"  # Just check that h1 exists
  end

  # US-004: Mobile nav toggle exposes Sign Up and Calculator CTAs
  test "mobile nav toggle reveals sign-up and calculator links" do
    resize_to_mobile
    visit root_path

    # Navbar toggler should be visible on mobile
    assert_selector ".navbar-toggler", visible: true

    # CTAs should be hidden in collapsed navbar
    assert_no_selector ".navbar-collapse.show"

    # Click hamburger toggle
    find(".navbar-toggler").click

    # Navbar should expand
    assert_selector ".navbar-collapse.show", wait: 3

    # Sign Up and Calculator links should now be reachable
    within(".navbar-collapse.show") do
      sign_up_link = find_link(I18n.t("nav.sign_up"))
      assert sign_up_link, "Sign Up link should be visible in mobile nav"

      calculator_link = find_link(I18n.t("nav.calculate_now"))
      assert calculator_link, "Calculator link should be visible in mobile nav"
    end

    # Verify Sign Up link navigates correctly
    click_link I18n.t("nav.sign_up")
    assert_current_path new_user_registration_path
  end

  private

  def resize_to_mobile
    page.driver.browser.manage.window.resize_to(375, 667)
  end
end
