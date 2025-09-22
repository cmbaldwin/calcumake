require "test_helper"

class PrintPricingFlowsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
  end

  test "user can sign up and create a print pricing" do
    # Test user registration
    get new_user_registration_path
    assert_response :success

    post user_registration_path, params: {
      user: {
        email: "newuser@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success

    # First create a printer for the user
    current_user = User.find_by(email: "newuser@example.com")
    printer = current_user.printers.create!(
      name: "Test Printer",
      manufacturer: "Prusa",
      power_consumption: 200,
      cost: 500,
      payoff_goal_years: 3,
      daily_usage_hours: 8,
      repair_cost_percentage: 5.0
    )

    # Test creating a new print pricing
    get new_print_pricing_path
    assert_response :success
    assert_select "form#pricing-form"

    post print_pricings_path, params: {
      print_pricing: {
        job_name: "Integration Test Print",
        printer_id: printer.id,
        printing_time_hours: 1,
        printing_time_minutes: 30,
        filament_weight: 25.0,
        filament_type: "PLA",
        spool_price: 20.0,
        spool_weight: 1000.0,
        markup_percentage: 15.0,
        vat_percentage: 8.0
      }
    }

    assert_redirected_to print_pricing_path(PrintPricing.last)
    follow_redirect!
    assert_response :success
    assert_select "h1", /Integration Test Print/
  end

  test "authenticated user can manage print pricings" do
    sign_in @user

    # Update user settings for EUR
    @user.update!(
      default_currency: "EUR",
      default_energy_cost_per_kwh: 0.15
    )

    # Create a printer for the test
    printer = @user.printers.create!(
      name: "Flow Test Printer",
      manufacturer: "Prusa",
      power_consumption: 150,
      cost: 800.0,
      payoff_goal_years: 3,
      daily_usage_hours: 8,
      repair_cost_percentage: 5.0
    )

    # Test accessing index page
    get root_path
    assert_response :success
    assert_select "h1", /My Print Calculations/

    # Test creating a new pricing
    get new_print_pricing_path
    assert_response :success

    assert_difference("PrintPricing.count") do
      post print_pricings_path, params: {
        print_pricing: {
          job_name: "Flow Test Print",
          printer_id: printer.id,
          printing_time_hours: 2,
          printing_time_minutes: 15,
          filament_weight: 40.0,
          filament_type: "PETG",
          spool_price: 35.0,
          spool_weight: 1000.0,
          markup_percentage: 20.0,
          vat_percentage: 21.0
        }
      }
    end

    pricing = PrintPricing.last
    assert_redirected_to print_pricing_path(pricing)

    # Test viewing the created pricing
    follow_redirect!
    assert_response :success
    assert_select "h1", /Flow Test Print/
    assert_select "td", "EUR"
    assert_select "td", "2h 15m"

    # Test editing the pricing
    get edit_print_pricing_path(pricing)
    assert_response :success

    patch print_pricing_path(pricing), params: {
      print_pricing: {
        job_name: "Updated Flow Test Print",
        currency: "GBP"
      }
    }

    assert_redirected_to print_pricing_path(pricing)
    follow_redirect!
    assert_select "h1", /Updated Flow Test Print/

    # Test deleting the pricing
    assert_difference("PrintPricing.count", -1) do
      delete print_pricing_path(pricing)
    end

    assert_redirected_to print_pricings_path
    follow_redirect!
    assert_response :success
  end

  test "user cannot access other user's pricings" do
    sign_in @user

    # Create a completely separate user and pricing
    other_user = User.create!(
      email: "otherintegration@example.com",
      password: "password123",
      default_currency: "USD",
      default_energy_cost_per_kwh: 0.12
    )
    other_printer = other_user.printers.create!(
      name: "Other Integration Printer",
      manufacturer: "Prusa",
      power_consumption: 200,
      cost: 500,
      payoff_goal_years: 3,
      daily_usage_hours: 8,
      repair_cost_percentage: 5.0
    )
    other_pricing = other_user.print_pricings.create!(
      job_name: "Other User's Print",
      printer: other_printer,
      printing_time_hours: 1,
      printing_time_minutes: 0,
      filament_weight: 30.0,
      filament_type: "PLA",
      spool_price: 20.0,
      spool_weight: 1000.0,
      markup_percentage: 15.0
    )

    # The security check should either return 404 or redirect to login
    get print_pricing_path(other_pricing)
    assert_includes [ 404, 302 ], response.status
  end

  test "unauthenticated user is redirected to login" do
    # Test accessing protected pages without authentication
    get print_pricings_path
    assert_redirected_to new_user_session_path

    get new_print_pricing_path
    assert_redirected_to new_user_session_path

    post print_pricings_path, params: { print_pricing: { job_name: "Test" } }
    assert_redirected_to new_user_session_path
  end

  test "complete pricing calculation workflow" do
    sign_in @user

    # Update user currency settings for this test
    @user.update!(
      default_currency: "JPY",
      default_energy_cost_per_kwh: 35.0
    )

    # Create a printer for the comprehensive test
    printer = @user.printers.create!(
      name: "Complete Test Printer",
      manufacturer: "Prusa",
      power_consumption: 250,
      cost: 300000.0,
      payoff_goal_years: 3,
      daily_usage_hours: 10,
      repair_cost_percentage: 8.0
    )

    # Create a comprehensive pricing with all optional fields
    post print_pricings_path, params: {
      print_pricing: {
        job_name: "Complete Test",
        printer_id: printer.id,
        printing_time_hours: 3,
        printing_time_minutes: 45,
        filament_weight: 60.0,
        filament_type: "ABS",
        spool_price: 4500.0,
        spool_weight: 1000.0,
        markup_percentage: 25.0,
        prep_time_minutes: 45,
        prep_cost_per_hour: 2500.0,
        postprocessing_time_minutes: 30,
        postprocessing_cost_per_hour: 3000.0,
        other_costs: 500.0,
        vat_percentage: 10.0
      }
    }

    pricing = PrintPricing.last
    assert_redirected_to print_pricing_path(pricing)

    # Verify calculations are working
    assert pricing.final_price > 0
    assert pricing.total_filament_cost > 0
    assert pricing.total_electricity_cost > 0
    assert pricing.total_labor_cost > 0
    assert pricing.total_machine_upkeep_cost > 0

    # Check the show page displays all components
    follow_redirect!
    assert_response :success
    assert_select "h3", /Electricity Cost/
    assert_select "h3", /Labor Cost/
    assert_select "h3", /Machine & Upkeep Cost/
    assert_select "h3", /Cost Summary/
  end
end
