require "test_helper"
require "ostruct"

class OauthAuthenticationTest < ActiveSupport::TestCase
  # Integration tests for OAuth authentication functionality
  # Focus on testing the core OAuth logic rather than routes

  test "OAuth user creation works with Google provider" do
    auth_data = create_oauth_mock("google_oauth2", "google@test.com", "12345")

    assert_difference "User.count", 1 do
      user = User.from_omniauth(auth_data)
      assert user.persisted?
      assert_equal "google@test.com", user.email
      assert_equal "google_oauth2", user.provider
      assert_equal "12345", user.uid
      assert user.oauth_user?
    end
  end

  test "OAuth user creation works with GitHub provider" do
    auth_data = create_oauth_mock("github", "github@test.com", "67890")

    assert_difference "User.count", 1 do
      user = User.from_omniauth(auth_data)
      assert user.persisted?
      assert_equal "github@test.com", user.email
      assert_equal "github", user.provider
      assert_equal "67890", user.uid
      assert user.oauth_user?
    end
  end

  test "OAuth user creation works with Microsoft provider" do
    auth_data = create_oauth_mock("microsoft_graph", "microsoft@test.com", "98765")

    assert_difference "User.count", 1 do
      user = User.from_omniauth(auth_data)
      assert user.persisted?
      assert_equal "microsoft@test.com", user.email
      assert_equal "microsoft_graph", user.provider
      assert_equal "98765", user.uid
      assert user.oauth_user?
    end
  end

  test "OAuth user creation works with Facebook provider" do
    auth_data = create_oauth_mock("facebook", "facebook@test.com", "facebook123")

    assert_difference "User.count", 1 do
      user = User.from_omniauth(auth_data)
      assert user.persisted?
      assert_equal "facebook@test.com", user.email
      assert_equal "facebook", user.provider
      assert_equal "facebook123", user.uid
      assert user.oauth_user?
    end
  end

  test "OAuth user creation works with Yahoo Japan provider" do
    auth_data = create_oauth_mock("yahoojp", "yahoojp@test.com", "yahoojp456")

    assert_difference "User.count", 1 do
      user = User.from_omniauth(auth_data)
      assert user.persisted?
      assert_equal "yahoojp@test.com", user.email
      assert_equal "yahoojp", user.provider
      assert_equal "yahoojp456", user.uid
      assert user.oauth_user?
    end
  end

  test "OAuth user creation works with LINE provider" do
    auth_data = create_oauth_mock("line", "line@test.com", "line789")

    assert_difference "User.count", 1 do
      user = User.from_omniauth(auth_data)
      assert user.persisted?
      assert_equal "line@test.com", user.email
      assert_equal "line", user.provider
      assert_equal "line789", user.uid
      assert user.oauth_user?
    end
  end

  test "OAuth authentication links existing user account" do
    existing_user = users(:one)
    auth_data = create_oauth_mock("google_oauth2", existing_user.email, "12345")

    assert_no_difference "User.count" do
      user = User.from_omniauth(auth_data)
      assert_equal existing_user.id, user.id
      assert_equal "google_oauth2", user.provider
      assert_equal "12345", user.uid
      assert user.oauth_user?
    end
  end

  test "OAuth user data is properly isolated from other users" do
    oauth_user = User.from_omniauth(create_oauth_mock("google_oauth2", "isolated@example.com", "isolation123"))
    regular_user = users(:one)

    # Create data for OAuth user
    oauth_printer = oauth_user.printers.create!(
      name: "OAuth Printer",
      manufacturer: "Test",
      power_consumption: 200,
      cost: 500,
      payoff_goal_years: 3,
      daily_usage_hours: 8,
      repair_cost_percentage: 5.0
    )

    oauth_initial_count = oauth_user.printers.count
    regular_initial_count = regular_user.printers.count

    # Verify data isolation
    assert_equal 1, oauth_initial_count
    assert_not_includes regular_user.printers, oauth_printer
  end

  test "multiple OAuth sign-ins for same user updates provider info" do
    user_email = "multiauth@example.com"
    existing_user = User.create!(
      email: user_email,
      password: "password123",
      default_currency: "USD",
      default_energy_cost_per_kwh: 0.12
    )

    # First OAuth sign-in with Google
    google_auth = create_oauth_mock("google_oauth2", user_email, "google123")
    user1 = User.from_omniauth(google_auth)

    assert_equal existing_user.id, user1.id
    assert_equal "google_oauth2", user1.provider
    assert_equal "google123", user1.uid

    # Second OAuth sign-in with GitHub (same email, different provider)
    github_auth = create_oauth_mock("github", user_email, "github456")
    user2 = User.from_omniauth(github_auth)

    assert_equal existing_user.id, user2.id
    assert_equal "github", user2.provider
    assert_equal "github456", user2.uid
  end

  test "OAuth user maintains correct default values" do
    auth_data = create_oauth_mock("google_oauth2", "defaults@example.com", "defaults123")

    user = User.from_omniauth(auth_data)
    assert_equal "USD", user.default_currency
    assert_equal 0.12, user.default_energy_cost_per_kwh
    assert_equal "en", user.locale
    assert_equal 1, user.next_invoice_number
  end

  test "OAuth authentication handles provider-specific errors gracefully" do
    # Test with missing email - should return nil for email collection flow
    auth_data = create_oauth_mock("google_oauth2", "", "invalid123")

    assert_no_difference "User.count" do
      user = User.from_omniauth(auth_data)
      assert_nil user, "Expected nil when email is blank to trigger email collection flow"
    end
  end

  test "OAuth authentication works with all supported providers" do
    providers = [
      { name: "google_oauth2", email: "google@test.com", uid: "google123" },
      { name: "github", email: "github@test.com", uid: "github456" },
      { name: "microsoft_graph", email: "microsoft@test.com", uid: "microsoft789" },
      { name: "facebook", email: "facebook@test.com", uid: "facebook101" },
      { name: "yahoojp", email: "yahoojp@test.com", uid: "yahoojp202" },
      { name: "line", email: "line@test.com", uid: "line303" }
    ]

    providers.each do |provider_data|
      auth_data = create_oauth_mock(
        provider_data[:name],
        provider_data[:email],
        provider_data[:uid]
      )

      assert_difference "User.count", 1 do
        user = User.from_omniauth(auth_data)
        assert user.persisted?
        assert_equal provider_data[:email], user.email
        assert_equal provider_data[:name], user.provider
        assert_equal provider_data[:uid], user.uid
        assert user.oauth_user?
      end
    end
  end

  test "OAuth user can have same data relationships as regular users" do
    oauth_user = User.from_omniauth(create_oauth_mock("google_oauth2", "relationships@example.com", "rel123"))

    # Test that OAuth user can create all the same types of data as regular users
    printer = oauth_user.printers.create!(
      name: "OAuth User Printer",
      manufacturer: "Test",
      power_consumption: 200,
      cost: 500,
      payoff_goal_years: 3,
      daily_usage_hours: 8,
      repair_cost_percentage: 5.0
    )

    filament = oauth_user.filaments.create!(
      name: "OAuth User PLA",
      material_type: "PLA",
      spool_price: 25.0,
      spool_weight: 1000.0
    )

    pricing = oauth_user.print_pricings.build(
      job_name: "OAuth Test Print",
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

    # Verify all relationships work
    assert_equal 1, oauth_user.printers.count
    assert_equal 1, oauth_user.filaments.count
    assert_equal 1, oauth_user.print_pricings.count
    assert_equal printer, oauth_user.printers.first
    assert_equal filament, oauth_user.filaments.first
    assert_equal pricing, oauth_user.print_pricings.first
  end

  private

  def create_oauth_mock(provider, email, uid, name = "Test User")
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
