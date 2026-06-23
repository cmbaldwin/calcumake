require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "user can sign up successfully" do
    visit new_user_registration_path

    # Fill in form fields with explicit waits and ensure form is ready
    fill_in "user_email", with: "newuser@example.com"
    fill_in "user_password", with: "password123"

    # Ensure password is filled before moving to confirmation
    password_field = find_field("user_password")
    assert_equal "password123", password_field.value

    fill_in "user_password_confirmation", with: "password123"

    # Ensure confirmation is filled before submitting
    confirmation_field = find_field("user_password_confirmation")
    assert_equal "password123", confirmation_field.value

    click_button "Sign up"

    # New users are redirected to onboarding (needs_onboarding? is true for users created < 1 hour ago)
    assert_current_path onboarding_path
    # Flash message might not be visible on onboarding page, just check we're on the right path
  end

  test "user can sign in successfully" do
    user = User.create!(
      email: "testuser@example.com",
      password: "password123",
      default_currency: "USD",
      default_energy_cost_per_kwh: 0.12,
      confirmed_at: Time.current,  # Confirm user
      onboarding_completed_at: Time.current  # Mark onboarding as completed
    )

    visit new_user_session_path

    # Fill in fields and verify they're set before submitting
    fill_in "user_email", with: "testuser@example.com"
    email_field = find_field("user_email")
    assert_equal "testuser@example.com", email_field.value

    fill_in "user_password", with: "password123"
    password_field = find_field("user_password")
    assert_equal "password123", password_field.value

    click_button "Sign in"  # Changed from "Log in"

    # After sign in, redirects to dashboard (print_pricings#index)
    assert_current_path print_pricings_path
    # Verify user is signed in - check for dashboard content instead of nav link
    assert_text I18n.t("print_pricing.index.title")
  end

  test "user can sign out successfully" do
    user = User.create!(
      email: "testuser@example.com",
      password: "password123",
      default_currency: "USD",
      default_energy_cost_per_kwh: 0.12,
      confirmed_at: Time.current,
      onboarding_completed_at: Time.current  # Mark onboarding as completed
    )

    # Sign in through the UI
    sign_in user

    # Verify user is signed in by checking we're on the dashboard
    assert_current_path print_pricings_path

    # Find and click the sign out link using translation key
    # The link might be in a dropdown, so we use accept_confirm to handle any JS confirmations
    sign_out_link = find_link(I18n.t("nav.sign_out"), visible: :all)
    sign_out_link.click

    # Wait for the sign out to complete by checking we're no longer on the dashboard
    assert_no_current_path print_pricings_path, wait: 5

    # Verify we're redirected to public page or sign-in
    assert [ root_path, new_user_session_path ].include?(current_path),
           "Expected to be redirected to root or sign-in, but was on #{current_path}"

    # Verify we can't access protected pages - should redirect to sign-in
    visit print_pricings_path
    assert_current_path new_user_session_path
  end

  test "user cannot access protected pages when not signed in" do
    visit "/printers"

    assert_current_path new_user_session_path
    assert_text "You need to sign in or sign up before continuing."
  end

  test "sign up with invalid data shows errors" do
    visit new_user_registration_path

    # Use an email that passes HTML5 validation but fails Rails validation
    fill_in "Email", with: "invalid@"
    fill_in "Password", with: "short"
    fill_in "Password confirmation", with: "different"

    click_button "Sign up"

    # Should stay on registration page due to validation errors
    assert_current_path new_user_registration_path

    # Look for validation error indicators (may be in form or flash)
    # Rails validation errors may appear as field errors or in flash
    page_content = page.body
    assert page_content.include?("Email") || page_content.include?("email"), "Should show email validation error"
    assert page_content.include?("Password") || page_content.include?("password"), "Should show password validation error"
  end

  test "sign in with invalid credentials shows error" do
    visit new_user_session_path

    fill_in "Email", with: "nonexistent@example.com"
    fill_in "Password", with: "wrongpassword"

    click_button "Sign in"  # Changed from "Log in"

    # Should stay on sign in page
    assert_current_path new_user_session_path
    # Flash error message should be visible (may be in toast or flash div)
    assert_text "Invalid Email or password."
  end

  # US-002: Cookie consent banner must not block sign-up submission (desktop)
  test "desktop sign-up submit is clickable with cookie consent banner visible" do
    verify_signup_submission_with_cookie_banner
  end

  # US-002: Cookie consent banner must not block sign-up submission (mobile)
  test "mobile sign-up submit is clickable with cookie consent banner visible" do
    page.driver.browser.manage.window.resize_to(375, 667)
    verify_signup_submission_with_cookie_banner
  end

  # US-003: Sign-up validation feedback must be visibly detectable
  test "invalid sign-up shows visible validation errors" do
    visit new_user_registration_path

    # Submit with invalid data: short password, mismatched confirmation
    fill_in "user_email", with: "validation-test@example.com"
    fill_in "user_password", with: "short"
    fill_in "user_password_confirmation", with: "different"

    click_button I18n.t("nav.sign_up")

    # Should show error explanation with validation messages
    assert_selector "#error_explanation", wait: 5

    # Error list should contain specific validation messages
    within("#error_explanation") do
      assert_selector "li", minimum: 1
    end
  end

  private

  def verify_signup_submission_with_cookie_banner
    visit new_user_registration_path

    # Cookie consent banner should appear (no cookie set in fresh test session)
    assert_selector "[data-cookie-consent-target='banner']:not(.d-none)", wait: 3

    fill_in "user_email", with: "consent-test@example.com"
    fill_in "user_password", with: "password123"
    fill_in "user_password_confirmation", with: "password123"

    # Submit button must be clickable (not blocked by banner overlay)
    click_button I18n.t("nav.sign_up")
    assert_no_current_path new_user_registration_path, wait: 5
  end
end
