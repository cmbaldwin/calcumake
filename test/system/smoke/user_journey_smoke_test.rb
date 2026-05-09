require "application_system_test_case"

class UserJourneySmokeTest < ApplicationSystemTestCase
  test "authenticated user can create a print pricing" do
    user = users(:one)
    sign_in user

    assert_current_path print_pricings_path
    visit new_print_pricing_path

    # Capybara's fill_in / .set typing is unreliable in headless Chrome here:
    # values silently drop when Stimulus 'input' actions fire mid-keystroke.
    # Use the native HTMLInputElement.value setter (the React-friendly idiom)
    # so the value sticks regardless of which Stimulus controllers are listening.
    set_input_value("input[name='print_pricing[job_name]']", "Smoke Job")
    select printers(:one).name, from: "print_pricing_printer_id"
    set_input_value("#print_pricing_units", "1")

    within(".nested-form-item[data-plate]", match: :first) do
      set_input_value("input[name*='[printing_time_hours]']", "1")
      set_input_value("input[name*='[printing_time_minutes]']", "20")

      filament_select = find("select[name*='[plate_filaments_attributes]'][name$='[filament_id]']", match: :first)
      filament_select.find("option", text: filaments(:one).display_name).select_option

      set_input_value("input[name*='[plate_filaments_attributes]'][name$='[filament_weight]']", "35")
    end

    # Sanity-check values landed before submitting; surfaces failures clearly
    # rather than as an opaque "form didn't redirect" timeout.
    assert_equal "Smoke Job", find("input[name='print_pricing[job_name]']").value
    assert_equal "1", find("input[name*='[printing_time_hours]']", match: :first).value
    assert_equal "35", find("input[name*='[filament_weight]']", match: :first).value

    # Submit via JS to bypass any HTML5 validation issues in headless Chrome
    execute_script("document.getElementById('pricing-form').requestSubmit()")

    # Wait for redirect to show page
    assert_current_path(%r{\A/print_pricings/\d+\z}, wait: 10)
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

    # Click via JS to bypass cookie consent banner overlay
    submit_btn = find(:button, I18n.t("onboarding.buttons.create_printer"))
    execute_script("arguments[0].scrollIntoView({block: 'center'}); arguments[0].click();", submit_btn.native)

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

  private

  # Set an input/textarea value via the native value setter and fire input+change.
  # More reliable than Capybara's typed input for fields with Stimulus listeners.
  def set_input_value(selector, value)
    el = find(selector, match: :first)
    execute_script(<<~JS, el.native, value.to_s)
      const target = arguments[0];
      const proto = target.tagName === 'TEXTAREA'
        ? window.HTMLTextAreaElement.prototype
        : window.HTMLInputElement.prototype;
      Object.getOwnPropertyDescriptor(proto, 'value').set.call(target, arguments[1]);
      target.dispatchEvent(new Event('input', { bubbles: true }));
      target.dispatchEvent(new Event('change', { bubbles: true }));
    JS
    el
  end
end
