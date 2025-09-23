require "application_system_test_case"

class SimpleInvoiceTest < ApplicationSystemTestCase
  test "invoice functionality works end-to-end" do
    # Create user
    user = User.create!(
      email: "simple@example.com",
      password: "password123",
      default_currency: "USD",
      default_energy_cost_per_kwh: 0.12
    )

    # Create printer
    printer = user.printers.create!(
      name: "Test Printer",
      manufacturer: "Prusa",
      power_consumption: 250,
      cost: 800,
      payoff_goal_years: 3,
      daily_usage_hours: 8,
      repair_cost_percentage: 5.0
    )

    # Create print pricing
    print_pricing = user.print_pricings.create!(
      job_name: "Simple Test Job",
      printer: printer,
      printing_time_hours: 2,
      printing_time_minutes: 30,
      filament_weight: 50,
      filament_type: "PLA+",
      spool_price: 25,
      spool_weight: 1000,
      markup_percentage: 20,
      vat_percentage: 8,
      times_printed: 1
    )

    # Sign in
    sign_in user

    # Go directly to invoice page
    visit invoice_print_pricing_path(print_pricing)

    # Verify basic invoice content
    assert_text "Invoice"
    assert_text "Simple Test Job"
    assert_text "PLA+"
    assert_text "Cost Breakdown"
    assert_text "Total"

    # Verify currency symbols are present
    assert_text "$"

    # Verify PDF controls are present
    assert_button "Download PDF"
    assert_button "Print"

    # Verify navigation works
    assert_link "Back"
    click_link "Back"
    assert_current_path print_pricing_path(print_pricing)
  end
end
