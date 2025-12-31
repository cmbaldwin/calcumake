require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  private

  def sign_in(user)
    visit new_user_session_path

    # Fill in fields and verify they're set before submitting
    fill_in "user_email", with: user.email
    email_field = find_field("user_email")
    assert_equal user.email, email_field.value

    fill_in "user_password", with: "password123"  # Use the known test password
    password_field = find_field("user_password")
    assert_equal "password123", password_field.value

    click_button I18n.t("nav.sign_in")  # Use translation key instead of hardcoded text
  end
end
