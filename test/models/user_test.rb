require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      email: "test@example.com",
      password: "password123",
      default_currency: "USD",
      default_energy_cost_per_kwh: 0.12
    )
  end

  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "should require email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "should require password" do
    @user.password = nil
    assert_not @user.valid?
    assert_includes @user.errors[:password], "can't be blank"
  end

  test "should have many print_pricings" do
    assert_respond_to @user, :print_pricings
  end

  test "should destroy associated print_pricings when user is destroyed" do
    @user.save!
    filament = @user.filaments.create!(
      name: "Test PLA",
      material_type: "PLA",
      spool_price: 25.0,
      spool_weight: 1000.0
    )
    printer = @user.printers.create!(
      name: "Test Printer",
      manufacturer: "Prusa",
      power_consumption: 200,
      cost: 500,
      payoff_goal_years: 3,
      daily_usage_hours: 8,
      repair_cost_percentage: 5.0
    )
    pricing = @user.print_pricings.build(
      job_name: "Test Print",
      printer: printer
    )
    plate = pricing.plates.build(
      printing_time_hours: 2,
      printing_time_minutes: 30
    )
    plate.plate_filaments.build(
      filament: filament,
      filament_weight: 50.0
    )
    pricing.save!

    assert_difference "PrintPricing.count", -1 do
      @user.destroy
    end
  end

  test "should require default_currency" do
    @user.default_currency = nil
    assert_not @user.valid?
    assert_includes @user.errors[:default_currency], "can't be blank"
  end

  test "should require default_energy_cost_per_kwh" do
    @user.default_energy_cost_per_kwh = nil
    assert_not @user.valid?
    assert_includes @user.errors[:default_energy_cost_per_kwh], "can't be blank"
  end

  test "should require positive default_energy_cost_per_kwh" do
    @user.default_energy_cost_per_kwh = -0.01
    assert_not @user.valid?
    assert_includes @user.errors[:default_energy_cost_per_kwh], "must be greater than 0"
  end

  test "should have default values for new users" do
    new_user = User.new(email: "new@example.com", password: "password123")
    new_user.save!
    assert_equal "USD", new_user.default_currency
    assert_equal 0.12, new_user.default_energy_cost_per_kwh.to_f
  end

  # Locale-specific tests
  test "should have default locale of 'en'" do
    @user.save!
    assert_equal "en", @user.locale
  end

  test "should accept valid locale" do
    @user.locale = "ja"
    assert @user.valid?
  end

  test "should accept all available locales" do
    I18n.available_locales.each do |locale|
      @user.locale = locale.to_s
      assert @user.valid?, "Locale #{locale} should be valid"
    end
  end

  test "should reject invalid locale" do
    @user.locale = "invalid"
    assert_not @user.valid?
    assert_includes @user.errors[:locale], "is not included in the list"
  end

  test "should allow blank locale" do
    @user.locale = ""
    assert @user.valid?

    @user.locale = nil
    assert @user.valid?
  end

  test "should save and retrieve locale correctly" do
    @user.locale = "es"
    @user.save!

    reloaded_user = User.find(@user.id)
    assert_equal "es", reloaded_user.locale
  end
end
