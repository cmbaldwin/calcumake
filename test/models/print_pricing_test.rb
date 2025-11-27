require "test_helper"

class PrintPricingTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      default_currency: "USD",
      default_energy_cost_per_kwh: 0.12
    )
    @printer = Printer.create!(
      user: @user,
      name: "Test Printer",
      manufacturer: "Prusa",
      power_consumption: 200,
      cost: 500,
      payoff_goal_years: 3,
      daily_usage_hours: 8,
      repair_cost_percentage: 5.0
    )
    @filament = Filament.create!(
      user: @user,
      name: "Test PLA",
      material_type: "PLA",
      spool_price: 25.0,
      spool_weight: 1000.0
    )
    @print_pricing = PrintPricing.new(
      user: @user,
      printer: @printer,
      job_name: "Test Print",
      vat_percentage: 10.0
    )
    plate = @print_pricing.plates.build(
      printing_time_hours: 2,
      printing_time_minutes: 30
    )
    plate.plate_filaments.build(
      filament: @filament,
      filament_weight: 50.0
    )
  end

  test "should be valid with valid attributes" do
    assert @print_pricing.valid?
  end

  test "should require job_name" do
    @print_pricing.job_name = nil
    assert_not @print_pricing.valid?
    assert_includes @print_pricing.errors[:job_name], "can't be blank"
  end


  test "should require at least one plate" do
    @print_pricing.plates.clear
    assert_not @print_pricing.valid?
    assert_includes @print_pricing.errors[:base], "Must have at least one plate"
  end

  test "should calculate total_printing_time_minutes correctly" do
    assert_equal 150, @print_pricing.total_printing_time_minutes
  end

  test "should sum printing time across all plates" do
    plate = @print_pricing.plates.build(
      printing_time_hours: 1,
      printing_time_minutes: 15
    )
    plate.plate_filaments.build(
      filament: @filament,
      filament_weight: 30.0
    )
    assert_equal 225, @print_pricing.total_printing_time_minutes # 150 + 75
  end

  test "should calculate total_filament_cost correctly" do
    # Base cost: 50g * $0.025/g = $1.25
    # With default 20% markup: $1.25 * 1.2 = $1.50
    base_cost = 50.0 * @filament.cost_per_gram
    markup_multiplier = 1 + (20.0 / 100.0) # Default markup_percentage is 20%
    expected_cost = base_cost * markup_multiplier
    assert_in_delta expected_cost, @print_pricing.total_filament_cost, 0.01
  end

  test "should calculate total_electricity_cost correctly" do
    expected_cost = (200.0 * 150.0 / 60.0 / 1000.0) * 0.12
    assert_in_delta expected_cost, @print_pricing.total_electricity_cost, 0.01
  end

  test "should calculate total_labor_cost correctly" do
    @print_pricing.prep_time_minutes = 30
    @print_pricing.prep_cost_per_hour = 20.0
    @print_pricing.postprocessing_time_minutes = 45
    @print_pricing.postprocessing_cost_per_hour = 25.0

    expected_cost = (30 * 20.0 / 60) + (45 * 25.0 / 60)
    assert_in_delta expected_cost, @print_pricing.total_labor_cost, 0.01
  end

  test "should calculate total_machine_upkeep_cost correctly" do
    @print_pricing.printer.update!(
      cost: 1000.0,
      payoff_goal_years: 3,
      daily_usage_hours: 8,
      repair_cost_percentage: 5.0
    )

    total_days = 3 * 365
    daily_depreciation = 1000.0 / total_days
    hourly_depreciation = daily_depreciation / 8
    repair_factor = 1.05
    expected_cost = hourly_depreciation * (150 / 60) * repair_factor

    assert_in_delta expected_cost, @print_pricing.total_machine_upkeep_cost, 0.01
  end

  test "should return zero for machine upkeep cost with missing values" do
    # Remove the printer association to simulate missing values
    @print_pricing.printer = nil
    assert_equal 0, @print_pricing.total_machine_upkeep_cost
  end

  test "should calculate final_price with VAT before save" do
    @print_pricing.save!
    subtotal = @print_pricing.calculate_subtotal
    expected_final = subtotal * 1.1
    assert_in_delta expected_final, @print_pricing.final_price, 0.01
  end

  test "should belong to user" do
    assert_respond_to @print_pricing, :user
    assert_equal @user, @print_pricing.user
  end

  test "should have default units value of 1" do
    pricing = PrintPricing.new(
      user: @user,
      job_name: "Test"
    )
    plate = pricing.plates.build(printing_time_hours: 1, printing_time_minutes: 0)
    plate.plate_filaments.build(filament: @filament, filament_weight: 10.0)
    pricing.save!
    assert_equal 1, pricing.units
  end

  test "should have default failure_rate_percentage of 5.0" do
    pricing = PrintPricing.new(
      user: @user,
      job_name: "Test"
    )
    plate = pricing.plates.build(printing_time_hours: 1, printing_time_minutes: 0)
    plate.plate_filaments.build(filament: @filament, filament_weight: 10.0)
    pricing.save!
    assert_equal 5.0, pricing.failure_rate_percentage
  end

  test "should validate units is greater than 0" do
    @print_pricing.units = 0
    assert_not @print_pricing.valid?
    assert_includes @print_pricing.errors[:units], "must be greater than 0"
  end

  test "should validate failure_rate_percentage is between 0 and 100" do
    @print_pricing.failure_rate_percentage = -1
    assert_not @print_pricing.valid?

    @print_pricing.failure_rate_percentage = 101
    assert_not @print_pricing.valid?

    @print_pricing.failure_rate_percentage = 50
    assert @print_pricing.valid?
  end

  test "should apply failure rate to filament cost" do
    @print_pricing.failure_rate_percentage = 10.0
    base_cost = 50.0 * @filament.cost_per_gram
    markup_multiplier = 1 + (20.0 / 100.0)
    base_with_markup = base_cost * markup_multiplier
    expected_cost_with_failure = base_with_markup * 1.1

    assert_in_delta expected_cost_with_failure, @print_pricing.total_filament_cost, 0.01
  end

  test "should apply failure rate to electricity cost" do
    @print_pricing.failure_rate_percentage = 10.0
    base_cost = (200.0 * 150.0 / 60.0 / 1000.0) * 0.12
    expected_cost_with_failure = base_cost * 1.1

    assert_in_delta expected_cost_with_failure, @print_pricing.total_electricity_cost, 0.01
  end

  test "should apply failure rate to machine upkeep cost" do
    @print_pricing.failure_rate_percentage = 10.0
    @print_pricing.save!

    # Calculate base cost without failure rate
    total_days = 3 * 365
    daily_depreciation = 500.0 / total_days
    hourly_depreciation = daily_depreciation / 8
    repair_factor = 1.05
    base_cost = hourly_depreciation * (150 / 60) * repair_factor
    expected_cost_with_failure = base_cost * 1.1

    assert_in_delta expected_cost_with_failure, @print_pricing.total_machine_upkeep_cost, 0.01
  end

  test "should calculate per_unit_price correctly" do
    @print_pricing.units = 5
    @print_pricing.save!
    expected_per_unit = @print_pricing.final_price / 5

    assert_in_delta expected_per_unit, @print_pricing.per_unit_price, 0.01
  end

  test "should return 0 for per_unit_price when units is 0" do
    @print_pricing.units = 1  # Can't save with 0 due to validation, so set to 1 first
    @print_pricing.save!
    @print_pricing.units = 0  # Then set to 0 to test the method

    assert_equal 0, @print_pricing.per_unit_price
  end

  test "should not apply failure rate when it is 0" do
    @print_pricing.failure_rate_percentage = 0
    base_cost = 50.0 * @filament.cost_per_gram
    markup_multiplier = 1 + (20.0 / 100.0)
    expected_cost = base_cost * markup_multiplier

    assert_in_delta expected_cost, @print_pricing.total_filament_cost, 0.01
  end

  test "should not apply failure rate when it is nil" do
    @print_pricing.failure_rate_percentage = nil
    base_cost = 50.0 * @filament.cost_per_gram
    markup_multiplier = 1 + (20.0 / 100.0)
    expected_cost = base_cost * markup_multiplier

    assert_in_delta expected_cost, @print_pricing.total_filament_cost, 0.01
  end
end
