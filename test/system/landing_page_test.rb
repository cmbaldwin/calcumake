require "application_system_test_case"

class LandingPageTest < ApplicationSystemTestCase
  test "visiting the landing page" do
    visit root_path

    assert_selector "h1", text: /Make 3D Printing Profitable/i
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
      assert_text "$0.99"
      assert_text "$9.99"
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
      assert_link "See Demo", href: demo_path
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
    assert_selector "h1", text: /3D印刷を収益化する/

    visit "/?locale=es"
    assert_selector "h1"  # Just check that h1 exists for now

    visit "/?locale=fr"
    assert_selector "h1"  # Just check that h1 exists for now
  end

  private

  def resize_to_mobile
    page.driver.browser.manage.window.resize_to(375, 667)
  end
end
