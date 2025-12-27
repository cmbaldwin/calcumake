require "application_system_test_case"

class LocaleSuggestionTest < ApplicationSystemTestCase
  # Note: These tests check the DOM structure but cannot fully test
  # geolocation features in headless browser environment

  test "locale suggestion banner exists in DOM" do
    visit root_path

    assert_selector ".locale-suggestion-banner", visible: false
    assert_selector "[data-controller='locale-suggestion']", visible: false
  end

  test "locale suggestion banner has correct data attributes" do
    visit root_path

    assert_selector "[data-locale-suggestion-current-locale-value='en']", visible: false
    assert_selector "[data-locale-suggestion-dismissed-key-value]", visible: false
  end

  test "locale switching mechanism structure exists" do
    visit root_path

    # Check that locale suggestion elements exist (may be hidden)
    # Skip detailed checks as this feature may be conditionally shown
    assert_selector "[data-controller='locale-suggestion']", visible: :all
  end

  test "banner is only included on landing page" do
    visit root_path
    # Locale suggestion should exist on landing (even if hidden)
    assert_selector "[data-controller='locale-suggestion']", visible: :all

    # Visit a different path that shouldn't have the banner
    visit privacy_policy_path
    assert_no_selector "[data-controller='locale-suggestion']"
  end
end
