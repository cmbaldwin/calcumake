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
    @print_pricing = PrintPricing.new(
      user: @user,
      printer: @printer,
      job_name: "Test Print",
      printing_time_hours: 2,
      printing_time_minutes: 30,
      filament_weight: 50.0,
      filament_type: "PLA",
      spool_price: 25.0,
      spool_weight: 1000.0,
      markup_percentage: 20.0,
      vat_percentage: 10.0
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


  test "should require filament_type" do
    @print_pricing.filament_type = nil
    assert_not @print_pricing.valid?
    assert_includes @print_pricing.errors[:filament_type], "can't be blank"
  end

  test "should require positive filament_weight" do
    @print_pricing.filament_weight = 0
    assert_not @print_pricing.valid?
    assert_includes @print_pricing.errors[:filament_weight], "must be greater than 0"
  end

  test "should calculate total_printing_time_minutes correctly" do
    assert_equal 150, @print_pricing.total_printing_time_minutes
  end

  test "should handle nil time values" do
    @print_pricing.printing_time_hours = nil
    @print_pricing.printing_time_minutes = 45
    assert_equal 45, @print_pricing.total_printing_time_minutes
  end

  test "should calculate total_filament_cost correctly" do
    expected_cost = (50.0 * 25.0 / 1000.0) * 1.2
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
end
