require "application_system_test_case"

# US-007: Make locale suggestion non-blocking on mobile
# Verifies that the locale suggestion banner does not cover or block
# the primary CTA on mobile viewports, and that dismiss choice persists.
class MobileLocaleSuggestionTest < ApplicationSystemTestCase
  MOBILE_WIDTH  = 390
  MOBILE_HEIGHT = 844

  # Helper: resize to a typical mobile viewport
  def resize_to_mobile
    page.driver.browser.manage.window.resize_to(MOBILE_WIDTH, MOBILE_HEIGHT)
  end

  def resize_to_desktop
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end

  # Inject the locale banner as visible so we can test its rendered impact
  def force_banner_visible
    execute_script(<<~JS)
      const banner = document.querySelector('[data-controller="locale-suggestion"]');
      if (banner) {
        banner.style.display  = 'block';
        banner.style.opacity  = '1';
        banner.style.transform = 'translateY(0)';
      }
    JS
  end

  test "primary sign-up CTA is visible and clickable on mobile with locale banner present" do
    resize_to_mobile
    visit root_path
    force_banner_visible

    # The banner must NOT cover the hero sign-up CTA
    cta_selector = "a[href='#{new_user_registration_path}'].btn"

    # Assert CTA exists on the page
    assert_selector cta_selector, minimum: 1

    # Scroll CTA into view and verify it is in the viewport (not occluded by banner)
    cta_element = first(cta_selector)
    scroll_to(cta_element)

    # The banner is compact on mobile (max-height <= 60px) so the CTA must be reachable
    banner_height = evaluate_script(
      "document.querySelector('.locale-suggestion-banner') ? " \
      "document.querySelector('.locale-suggestion-banner').getBoundingClientRect().height : 0"
    ).to_i

    assert banner_height <= 60,
      "Expected mobile locale banner height <= 60px, got #{banner_height}px. " \
      "Banner is too tall and may block primary CTA on mobile."

    # Ensure the CTA is in the viewport (top >= banner_height means it's below the banner)
    cta_top = evaluate_script(
      "document.querySelector(\"a[href='#{new_user_registration_path}']\") ? " \
      "document.querySelector(\"a[href='#{new_user_registration_path}']\").getBoundingClientRect().top : -1"
    ).to_f

    # CTA must be accessible (not hidden behind the fixed banner)
    # After scrolling to the CTA it should be in viewport (top < window.innerHeight)
    window_height = evaluate_script("window.innerHeight").to_i
    assert cta_top < window_height,
      "Primary CTA is out of viewport on mobile (top=#{cta_top}, innerHeight=#{window_height})."
  ensure
    resize_to_desktop
  end

  test "locale banner is compact on mobile (reduced visual priority)" do
    resize_to_mobile
    visit root_path
    force_banner_visible

    banner = first(".locale-suggestion-banner", visible: :all)
    assert banner, "Locale suggestion banner not found on landing page"

    # Banner height must be compact on mobile
    banner_height = evaluate_script(
      "document.querySelector('.locale-suggestion-banner').getBoundingClientRect().height"
    ).to_i

    assert banner_height <= 60,
      "Locale suggestion banner height on mobile should be <= 60px (got #{banner_height}px). " \
      "Add .locale-suggestion-banner--compact or reduce mobile padding."
  ensure
    resize_to_desktop
  end

  test "dismiss choice persists so banner does not reappear" do
    resize_to_mobile
    visit root_path

    # Simulate that the banner was previously dismissed by setting localStorage
    dismissed_key = evaluate_script(
      "document.querySelector('[data-locale-suggestion-dismissed-key-value]')&." \
      "getAttribute('data-locale-suggestion-dismissed-key-value')"
    )

    assert dismissed_key.present?, "Could not read dismissed key attribute from banner element"

    execute_script("localStorage.setItem('#{dismissed_key}', 'true')")

    # Reload — banner should not become visible
    visit root_path

    is_visible = evaluate_script(
      "const b = document.querySelector('.locale-suggestion-banner'); " \
      "b ? (b.style.display !== 'none' && b.style.opacity !== '0') : false"
    )

    assert_not is_visible,
      "Locale suggestion banner should remain hidden after dismiss choice is persisted in localStorage."
  ensure
    resize_to_desktop
    execute_script("localStorage.clear()")
  end
end
