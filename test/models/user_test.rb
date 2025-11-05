require "test_helper"
require "ostruct"

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

  # OAuth-specific tests
  test "from_omniauth should create new user with valid auth hash" do
    auth_hash = create_oauth_hash("newuser@example.com", "google_oauth2", "123456")

    assert_difference "User.count", 1 do
      user = User.from_omniauth(auth_hash)
      assert user.persisted?
      assert_equal "newuser@example.com", user.email
      assert_equal "google_oauth2", user.provider
      assert_equal "123456", user.uid
      assert user.password.present?
      assert user.oauth_user?
    end
  end

  test "from_omniauth should find existing user by email" do
    existing_user = users(:one)
    auth_hash = create_oauth_hash(existing_user.email, "github", "789012")

    assert_no_difference "User.count" do
      user = User.from_omniauth(auth_hash)
      assert_equal existing_user, user
      assert_equal "github", user.provider
      assert_equal "789012", user.uid
    end
  end

  test "from_omniauth should not create user with invalid email" do
    auth_hash = create_oauth_hash("", "google_oauth2", "123456")

    assert_no_difference "User.count" do
      user = User.from_omniauth(auth_hash)
      assert_not user.persisted?
      assert user.errors[:email].present?
    end
  end

  test "from_omniauth should handle duplicate email gracefully" do
    existing_user = users(:one)
    auth_hash = create_oauth_hash(existing_user.email, "microsoft_graph", "345678")

    user = User.from_omniauth(auth_hash)
    assert_equal existing_user.id, user.id
    assert_equal "microsoft_graph", user.provider
    assert_equal "345678", user.uid
  end

  test "from_omniauth should set default values for new OAuth users" do
    auth_hash = create_oauth_hash("oauthuser@example.com", "google_oauth2", "999888")

    user = User.from_omniauth(auth_hash)
    assert user.persisted?
    assert_equal "USD", user.default_currency
    assert_equal 0.12, user.default_energy_cost_per_kwh
    assert_equal "en", user.locale
    assert_equal 1, user.next_invoice_number
  end

  test "from_omniauth should generate secure password for OAuth users" do
    auth_hash = create_oauth_hash("secure@example.com", "github", "secure123")

    user = User.from_omniauth(auth_hash)
    assert user.password.present?
    assert user.password.length >= 20
    assert user.valid_password?(user.password)
  end

  test "oauth_user? should return true for users with provider and uid" do
    oauth_user = users(:oauth_google)
    assert oauth_user.oauth_user?

    github_user = users(:oauth_github)
    assert github_user.oauth_user?

    microsoft_user = users(:oauth_microsoft)
    assert microsoft_user.oauth_user?
  end

  test "oauth_user? should return false for regular users" do
    regular_user = users(:one)
    assert_not regular_user.oauth_user?

    another_user = users(:two)
    assert_not another_user.oauth_user?
  end

  test "oauth_user? should return false for users with only provider" do
    user = User.new(
      email: "partial@example.com",
      password: "password123",
      default_currency: "USD",
      default_energy_cost_per_kwh: 0.12,
      provider: "google_oauth2"
    )
    user.save!
    assert_not user.oauth_user?
  end

  test "oauth_user? should return false for users with only uid" do
    user = User.new(
      email: "partial2@example.com",
      password: "password123",
      default_currency: "USD",
      default_energy_cost_per_kwh: 0.12,
      uid: "123456"
    )
    user.save!
    assert_not user.oauth_user?
  end

  test "should allow OAuth users to exist without traditional validations" do
    oauth_user = users(:oauth_google)
    # OAuth users should be valid even with generated passwords
    assert oauth_user.valid?
    assert oauth_user.oauth_user?
  end

  test "OAuth user should maintain data isolation like regular users" do
    oauth_user = users(:oauth_google)
    regular_user = users(:one)

    # Get initial counts
    oauth_initial_count = oauth_user.printers.count
    regular_initial_count = regular_user.printers.count

    # Create some data for each user
    oauth_printer = oauth_user.printers.create!(
      name: "OAuth Printer",
      manufacturer: "Test",
      power_consumption: 200,
      cost: 500,
      payoff_goal_years: 3,
      daily_usage_hours: 8,
      repair_cost_percentage: 5.0
    )

    regular_printer = regular_user.printers.create!(
      name: "Regular Printer",
      manufacturer: "Test",
      power_consumption: 250,
      cost: 600,
      payoff_goal_years: 2,
      daily_usage_hours: 10,
      repair_cost_percentage: 3.0
    )

    # Verify data isolation - each user should have one more printer than before
    assert_equal oauth_initial_count + 1, oauth_user.printers.count
    assert_equal regular_initial_count + 1, regular_user.printers.count
    assert_not_includes oauth_user.printers, regular_printer
    assert_not_includes regular_user.printers, oauth_printer
  end

  private

  def create_oauth_hash(email, provider, uid, name = "Test User")
    OpenStruct.new(
      provider: provider,
      uid: uid,
      info: OpenStruct.new(
        email: email,
        name: name
      )
    )
  end
end
