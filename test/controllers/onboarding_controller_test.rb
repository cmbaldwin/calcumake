require "test_helper"
require "webmock/minitest"

class OnboardingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @new_user = users(:one)
    # Make user appear "new" by setting created_at to recent time
    @new_user.update!(
      created_at: 30.minutes.ago,
      onboarding_completed_at: nil,
      onboarding_current_step: 0
    )
    sign_in @new_user

    # Stub currency API calls for testing
    setup_currency_stubs
  end

  def setup_currency_stubs
    # USD to JPY
    stub_request(:get, "https://api.frankfurter.app/latest?from=USD&to=JPY")
      .to_return(
        status: 200,
        body: { "rates" => { "JPY" => 156.0 } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # USD to EUR
    stub_request(:get, "https://api.frankfurter.app/latest?from=USD&to=EUR")
      .to_return(
        status: 200,
        body: { "rates" => { "EUR" => 0.92 } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # USD to GBP
    stub_request(:get, "https://api.frankfurter.app/latest?from=USD&to=GBP")
      .to_return(
        status: 200,
        body: { "rates" => { "GBP" => 0.79 } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # USD to CAD
    stub_request(:get, "https://api.frankfurter.app/latest?from=USD&to=CAD")
      .to_return(
        status: 200,
        body: { "rates" => { "CAD" => 1.35 } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  test "should redirect to onboarding if not completed" do
    get root_path
    assert_redirected_to onboarding_path
  end

  test "should show welcome step for new user" do
    get onboarding_path
    assert_response :success
    assert_select "h1", text: /Welcome to CalcuMake/
  end

  test "should show specific step when provided" do
    get onboarding_path(step: "profile")
    assert_response :success
  end

  test "should redirect to current step if invalid step requested" do
    get onboarding_path(step: "invalid")
    assert_redirected_to onboarding_path(step: "welcome")
  end

  test "should update profile step" do
    @new_user.update!(onboarding_current_step: 1)

    patch onboarding_path(step: "profile"), params: {
      user: { default_currency: "USD", default_energy_cost_per_kwh: 0.12 }
    }

    assert_redirected_to onboarding_path(step: "company")
    @new_user.reload
    assert_equal "USD", @new_user.default_currency
    assert_equal 2, @new_user.onboarding_current_step
  end

  test "should update company step" do
    @new_user.update!(onboarding_current_step: 2)

    patch onboarding_path(step: "company"), params: {
      user: { default_company_name: "Test Company" }
    }

    assert_redirected_to onboarding_path(step: "printer")
    @new_user.reload
    assert_equal "Test Company", @new_user.default_company_name
    assert_equal 3, @new_user.onboarding_current_step
  end

  test "should create printer from preset" do
    @new_user.update!(onboarding_current_step: 3)

    assert_difference "@new_user.printers.count", 1 do
      patch onboarding_path(step: "printer"), params: {
        printer_model: "Prusa i3 MK4"
      }
    end

    assert_redirected_to onboarding_path(step: "filament")
    printer = @new_user.printers.last
    assert_equal "Prusa i3 MK4", printer.name
    assert_equal "Prusa", printer.manufacturer
    assert_equal 120, printer.power_consumption
  end

  test "should create printer from printer profile" do
    @new_user.update!(onboarding_current_step: 3)

    # Create a test printer profile
    profile = PrinterProfile.create!(
      manufacturer: "Test Manufacturer",
      model: "Test Model",
      category: "Mid-Range FDM",
      technology: "fdm",
      power_consumption_avg_watts: 250,
      cost_usd: 600
    )

    assert_difference "@new_user.printers.count", 1 do
      patch onboarding_path(step: "printer"), params: {
        printer_profile_id: profile.id
      }
    end

    assert_redirected_to onboarding_path(step: "filament")
    printer = @new_user.printers.last
    assert_equal "Test Manufacturer Test Model", printer.name
    assert_equal "Test Manufacturer", printer.manufacturer
    assert_equal 250, printer.power_consumption
    assert_equal 600, printer.cost
  end

  test "should require printer selection" do
    @new_user.update!(onboarding_current_step: 3)

    assert_no_difference "@new_user.printers.count" do
      patch onboarding_path(step: "printer"), params: {}
    end

    assert_response :unprocessable_entity
  end

  test "should create multiple filaments" do
    @new_user.update!(onboarding_current_step: 4)

    assert_difference "@new_user.filaments.count", 2 do
      patch onboarding_path(step: "filament"), params: {
        filament_types: [ "PLA", "PETG" ]
      }
    end

    assert_redirected_to onboarding_path(step: "complete")
    filaments = @new_user.filaments.order(:created_at).last(2)
    assert_equal "PLA", filaments.first.name
    assert_equal "PETG", filaments.last.name
  end

  test "should require at least one filament" do
    @new_user.update!(onboarding_current_step: 4)

    assert_no_difference "@new_user.filaments.count" do
      patch onboarding_path(step: "filament"), params: {
        filament_types: []
      }
    end

    assert_response :unprocessable_entity
  end

  test "should allow skipping individual step" do
    @new_user.update!(onboarding_current_step: 2)

    post skip_step_onboarding_path

    assert_redirected_to onboarding_path(step: "printer")
    @new_user.reload
    assert_equal 3, @new_user.onboarding_current_step
  end

  test "should allow skipping entire walkthrough" do
    post skip_walkthrough_onboarding_path

    assert_redirected_to dashboard_path
    @new_user.reload
    assert_not_nil @new_user.onboarding_completed_at
    assert @new_user.onboarding_completed?
  end

  test "should complete onboarding and redirect to dashboard" do
    @new_user.update!(onboarding_current_step: 5)

    post complete_onboarding_path

    assert_redirected_to dashboard_path
    @new_user.reload
    assert_not_nil @new_user.onboarding_completed_at
    assert @new_user.onboarding_completed?
  end

  test "should not show onboarding for completed users" do
    @new_user.update!(onboarding_completed_at: 1.day.ago)

    get onboarding_path
    assert_redirected_to root_path
  end

  test "should not redirect to onboarding for old users" do
    @new_user.update!(
      created_at: 2.hours.ago,
      onboarding_completed_at: nil
    )

    get root_path
    assert_response :success # Landing page no longer auto-redirects authenticated users
  end

  # Currency Conversion Tests
  test "should convert printer cost to JPY when user selects JPY currency" do
    @new_user.update!(
      onboarding_current_step: 3,
      default_currency: "JPY"
    )

    # Clear existing printers to ensure clean test
    @new_user.printers.destroy_all

    # Prusa i3 MK4 has cost of $799 USD
    # Should convert to approximately 124,644 JPY at rate of 156
    patch onboarding_path(step: "printer"), params: {
      printer_model: "Prusa i3 MK4"
    }

    assert_response :redirect
    assert_redirected_to onboarding_path(step: "filament")

    @new_user.reload
    assert_equal 1, @new_user.printers.count, "Expected printer to be created"

    printer = @new_user.printers.last
    assert_equal "Prusa i3 MK4", printer.name
    # Allow for small variance in conversion rate
    assert_operator printer.cost, :>, 100000, "Expected JPY cost to be much higher than USD (got #{printer.cost})"
    assert_operator printer.cost, :<, 150000, "Expected JPY cost to be reasonable (got #{printer.cost})"
  end

  test "should convert filament cost to EUR when user selects EUR currency" do
    @new_user.update!(
      onboarding_current_step: 4,
      default_currency: "EUR"
    )

    # Clear existing filaments to ensure clean test
    @new_user.filaments.destroy_all

    # PLA has spool_price of $25 USD
    # Should convert to approximately 23 EUR at rate of 0.92
    patch onboarding_path(step: "filament"), params: {
      filament_types: [ "PLA" ]
    }

    assert_response :redirect
    assert_redirected_to onboarding_path(step: "complete")

    @new_user.reload
    assert_equal 1, @new_user.filaments.count, "Expected filament to be created"

    filament = @new_user.filaments.last
    assert_equal "PLA", filament.name
    # Allow for variance - EUR should be slightly less than USD
    assert_operator filament.spool_price, :>, 20, "Expected EUR price to be reasonable (got #{filament.spool_price})"
    assert_operator filament.spool_price, :<, 30, "Expected EUR price to be close to USD (got #{filament.spool_price})"
  end

  test "should not convert when user currency is USD" do
    @new_user.update!(
      onboarding_current_step: 3,
      default_currency: "USD"
    )

    assert_difference "@new_user.printers.count", 1 do
      patch onboarding_path(step: "printer"), params: {
        printer_model: "Creality Ender 3 V3"
      }
    end

    printer = @new_user.printers.last
    # Ender 3 V3 has cost of $249 USD - should remain unchanged
    assert_equal 249, printer.cost
  end

  test "should convert printer profile cost to user currency" do
    @new_user.update!(
      onboarding_current_step: 3,
      default_currency: "GBP"
    )

    # Clear existing printers to ensure clean test
    @new_user.printers.destroy_all

    # Create a test printer profile with USD cost
    profile = PrinterProfile.create!(
      manufacturer: "Test Manufacturer",
      model: "Test Model",
      category: "Mid-Range FDM",
      technology: "fdm",
      power_consumption_avg_watts: 250,
      cost_usd: 500
    )

    patch onboarding_path(step: "printer"), params: {
      printer_profile_id: profile.id
    }

    assert_response :redirect
    assert_redirected_to onboarding_path(step: "filament")

    @new_user.reload
    assert_equal 1, @new_user.printers.count, "Expected printer to be created"

    printer = @new_user.printers.last
    # $500 USD should convert to approximately £395 GBP at rate of 0.79
    assert_operator printer.cost, :>, 350, "Expected GBP cost to be reasonable (got #{printer.cost})"
    assert_operator printer.cost, :<, 450, "Expected GBP cost to be less than USD (got #{printer.cost})"
  end

  test "should handle multiple filament conversions to same currency" do
    @new_user.update!(
      onboarding_current_step: 4,
      default_currency: "CAD"
    )

    # Clear existing filaments to ensure clean test
    @new_user.filaments.destroy_all

    # PLA: $25 USD -> ~$33.75 CAD
    # PETG: $30 USD -> ~$40.50 CAD
    # ABS: $28 USD -> ~$37.80 CAD
    patch onboarding_path(step: "filament"), params: {
      filament_types: [ "PLA", "PETG", "ABS" ]
    }

    assert_response :redirect
    assert_redirected_to onboarding_path(step: "complete")

    @new_user.reload
    assert_equal 3, @new_user.filaments.count, "Expected 3 filaments to be created"

    filaments = @new_user.filaments.order(:created_at).last(3)

    # All should be converted to CAD (higher than USD)
    filaments.each do |filament|
      assert_operator filament.spool_price, :>, 30, "Expected CAD price to be higher than USD (got #{filament.spool_price} for #{filament.name})"
      assert_operator filament.spool_price, :<, 50, "Expected CAD price to be reasonable (got #{filament.spool_price} for #{filament.name})"
    end
  end

  test "should fallback to USD if currency conversion fails" do
    @new_user.update!(
      onboarding_current_step: 3,
      default_currency: "XYZ" # Invalid currency
    )

    # Clear existing printers to ensure clean test
    @new_user.printers.destroy_all

    # Mock the converter to return nil for invalid currency
    CurrencyConverter.singleton_class.class_eval do
      alias_method :original_convert, :convert
      define_method(:convert) do |amount, from:, to:|
        return nil if to == "XYZ"
        original_convert(amount, from: from, to: to)
      end
    end

    patch onboarding_path(step: "printer"), params: {
      printer_model: "Prusa Mini+"
    }

    assert_response :redirect
    assert_redirected_to onboarding_path(step: "filament")

    @new_user.reload
    assert_equal 1, @new_user.printers.count, "Expected printer to be created"

    printer = @new_user.printers.last
    # Should fallback to original USD price of $459
    assert_equal 459, printer.cost, "Expected fallback to USD price"
  ensure
    # Restore original method
    CurrencyConverter.singleton_class.class_eval do
      alias_method :convert, :original_convert
      remove_method :original_convert
    end
  end
end
