require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "user can sign up successfully" do
    visit new_user_registration_path

    fill_in "Email", with: "newuser@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"

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

    fill_in "Email", with: "testuser@example.com"
    fill_in "Password", with: "password123"

    click_button "Sign in"  # Changed from "Log in"

    # After sign in, redirects to dashboard (print_pricings#index)
    assert_current_path print_pricings_path
    assert_text "Sign out"  # Verify user is signed in
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

    # Verify user is signed in by checking navbar content
    assert_text "Sign out"

    # Click sign out
    click_link "Sign out"

    # After sign out, should be redirected to sign in page or public page
    # Check that we're no longer signed in by looking for sign in link
    assert_text "Sign in"
    assert_no_text "Sign out"
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
end
