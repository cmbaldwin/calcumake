require "application_system_test_case"

class UserJourneySmokeTest < ApplicationSystemTestCase
  test "authenticated user can create a print pricing" do
    user = users(:one)
    sign_in user

    assert_current_path print_pricings_path
    visit new_print_pricing_path

    fill_in "print_pricing[job_name]", with: "Smoke Job"
    select printers(:one).name, from: "print_pricing_printer_id"
    fill_in "print_pricing_units", with: "1"

    within(".nested-form-item[data-plate]", match: :first) do
      find("input[name*='[printing_time_hours]']", match: :first).fill_in with: "1"
      find("input[name*='[printing_time_minutes]']", match: :first).fill_in with: "20"

      filament_select = find("select[name*='[plate_filaments_attributes]'][name$='[filament_id]']", match: :first)
      filament_select.find("option", text: filaments(:one).display_name).select_option
      find("input[name*='[plate_filaments_attributes]'][name$='[filament_weight]']", match: :first).fill_in with: "35"
    end

    click_button I18n.t("print_pricing.buttons.calculate_save")
    assert_current_path(%r{\A/print_pricings/\d+\z})
    assert_text "Smoke Job"
  end

  test "new user can complete onboarding printer and filament steps" do
    user = User.create!(
      email: "smoke-onboarding@example.com",
      password: "password123",
      confirmed_at: Time.current,
      default_currency: "USD",
      default_energy_cost_per_kwh: 0.12,
      onboarding_current_step: 3,
      onboarding_completed_at: nil,
      created_at: 30.minutes.ago
    )

    sign_in user

    assert_no_current_path new_user_session_path
    visit onboarding_path(step: "printer")
    assert_selector ".printer-quick-select", minimum: 1

    find(".printer-quick-select", match: :first).click
    click_button I18n.t("onboarding.buttons.create_printer")

    assert_current_path onboarding_path(step: "filament")
    click_button I18n.t("onboarding.buttons.add_filaments")
    assert_current_path onboarding_path(step: "complete")

    assert user.reload.printers.exists?
    assert user.filaments.exists?
  end

  test "visitor can run the public calculator and see totals" do
    visit pricing_calculator_path

    find("input[name='plates[0][print_time]']").fill_in with: "2.0"
    find("input[name='plates[0][filaments][0][filament_weight]']").fill_in with: "80"
    find("input[name='plates[0][filaments][0][filament_price]']").fill_in with: "25"

    sleep 1

    total = find("[data-advanced-calculator-target='grandTotal']").text.strip
    assert_match(/\$\d+\.\d{2}/, total)
    assert_not_equal "$0.00", total
  end
end
