require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "user can sign up successfully" do
    visit new_user_registration_path

    fill_in "Email", with: "newuser@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"

    click_button "Sign up"

    assert_text "Welcome! You have signed up successfully."
    assert_current_path "/"
  end

  test "user can sign in successfully" do
    user = User.create!(
      email: "testuser@example.com",
      password: "password123",
      default_currency: "USD",
      default_energy_cost_per_kwh: 0.12
    )

    visit new_user_session_path

    fill_in "Email", with: "testuser@example.com"
    fill_in "Password", with: "password123"

    click_button "Log in"

    assert_text "Signed in successfully."
    assert_current_path "/"
  end

  test "user can sign out successfully" do
    user = User.create!(
      email: "testuser@example.com",
      password: "password123",
      default_currency: "USD",
      default_energy_cost_per_kwh: 0.12
    )

    sign_in user
    visit root_path

    click_link "Sign out"

    assert_text "Signed out successfully."
    assert_current_path new_user_session_path
  end

  test "user cannot access protected pages when not signed in" do
    visit "/printers"

    assert_current_path new_user_session_path
    assert_text "You need to sign in or sign up before continuing."
  end

  test "sign up with invalid data shows errors" do
    visit new_user_registration_path

    fill_in "Email", with: "invalid"
    fill_in "Password", with: "short"
    fill_in "Password confirmation", with: "different"

    click_button "Sign up"

    assert_text "Email is invalid"
    assert_text "Password is too short"
    assert_text "Password confirmation doesn't match Password"
  end

  test "sign in with invalid credentials shows error" do
    visit new_user_session_path

    fill_in "Email", with: "nonexistent@example.com"
    fill_in "Password", with: "wrongpassword"

    click_button "Log in"

    assert_text "Invalid Email or password."
  end
end
