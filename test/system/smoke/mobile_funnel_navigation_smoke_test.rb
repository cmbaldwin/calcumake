require "application_system_test_case"

class MobileFunnelNavigationSmokeTest < ApplicationSystemTestCase
  test "mobile visitor can open nav and reach funnel ctas" do
    resize_to_mobile
    visit root_path

    assert_selector "[data-testid='mobile-nav-toggle']", visible: true
    find("[data-testid='mobile-nav-toggle']").click

    assert_selector "[data-testid='mobile-nav-menu'].show", wait: 3

    within("[data-testid='mobile-nav-menu']") do
      assert_selector "[data-testid='nav-sign-up-link'][href='#{new_user_registration_path}']", visible: true
      assert_selector "[data-testid='nav-calculator-link'][href='#{pricing_calculator_path}']", visible: true

      find("[data-testid='nav-sign-up-link']").click
    end

    assert_current_path new_user_registration_path

    visit root_path
    find("[data-testid='mobile-nav-toggle']").click
    within("[data-testid='mobile-nav-menu'].show") do
      find("[data-testid='nav-calculator-link']").click
    end

    assert_current_path pricing_calculator_path
  end
end
