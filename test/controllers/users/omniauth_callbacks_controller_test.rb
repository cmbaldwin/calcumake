require "test_helper"
require "ostruct"

class Users::OmniauthCallbacksControllerTest < ActiveSupport::TestCase
  # Test OAuth callback controller functionality without routes
  # This focuses on the core logic that the controller uses

  test "User.from_omniauth creates new user with Google OAuth data" do
    auth_data = create_google_auth_hash

    assert_difference "User.count", 1 do
      user = User.from_omniauth(auth_data)
      assert user.persisted?
      assert_equal "newuser@gmail.com", user.email
      assert_equal "google_oauth2", user.provider
      assert_equal "12345", user.uid
      assert user.oauth_user?
      assert user.password.present?
    end
  end

  test "User.from_omniauth creates new user with GitHub OAuth data" do
    auth_data = create_github_auth_hash(email: "github_controller@example.com")

    assert_difference "User.count", 1 do
      user = User.from_omniauth(auth_data)
      assert user.persisted?
      assert_equal "github_controller@example.com", user.email
      assert_equal "github", user.provider
      assert_equal "67890", user.uid
      assert user.oauth_user?
    end
  end

  test "User.from_omniauth creates new user with Microsoft OAuth data" do
    auth_data = create_microsoft_auth_hash(email: "ms_controller@outlook.com")

    assert_difference "User.count", 1 do
      user = User.from_omniauth(auth_data)
      assert user.persisted?
      assert_equal "ms_controller@outlook.com", user.email
      assert_equal "microsoft_graph", user.provider
      assert_equal "98765", user.uid
      assert user.oauth_user?
    end
  end

  test "User.from_omniauth creates new user with Facebook OAuth data" do
    auth_data = create_facebook_auth_hash(email: "facebook_controller@example.com")

    assert_difference "User.count", 1 do
      user = User.from_omniauth(auth_data)
      assert user.persisted?
      assert_equal "facebook_controller@example.com", user.email
      assert_equal "facebook", user.provider
      assert_equal "facebook123", user.uid
      assert user.oauth_user?
    end
  end

  test "User.from_omniauth creates new user with Yahoo Japan OAuth data" do
    auth_data = create_yahoojp_auth_hash(email: "yahoojp_controller@yahoo.co.jp")

    assert_difference "User.count", 1 do
      user = User.from_omniauth(auth_data)
      assert user.persisted?
      assert_equal "yahoojp_controller@yahoo.co.jp", user.email
      assert_equal "yahoojp", user.provider
      assert_equal "yahoojp456", user.uid
      assert user.oauth_user?
    end
  end

  test "User.from_omniauth links existing user by email" do
    existing_user = users(:one)
    auth_data = create_google_auth_hash(email: existing_user.email)

    assert_no_difference "User.count" do
      user = User.from_omniauth(auth_data)
      assert_equal existing_user.id, user.id
      assert_equal "google_oauth2", user.provider
      assert_equal "12345", user.uid
      assert user.oauth_user?
    end
  end

  test "User.from_omniauth handles invalid email gracefully" do
    auth_data = create_google_auth_hash(email: "")

    assert_no_difference "User.count" do
      user = User.from_omniauth(auth_data)
      assert_not user.persisted?
      assert user.errors[:email].present?
    end
  end

  test "OAuth controller methods exist and are defined correctly" do
    controller = Users::OmniauthCallbacksController.new

    # Test that callback methods exist
    assert_respond_to controller, :google_oauth2
    assert_respond_to controller, :github
    assert_respond_to controller, :microsoft_graph
    assert_respond_to controller, :facebook
    assert_respond_to controller, :yahoojp
    assert_respond_to controller, :failure

    # Test that handle_auth private method exists
    assert controller.private_methods.include?(:handle_auth)
  end

  test "OAuth providers are correctly configured on User model" do
    expected_providers = [ :google_oauth2, :github, :microsoft_graph, :facebook, :yahoojp, :line ]
    assert_equal expected_providers, User.omniauth_providers
  end

  test "OAuth user creation sets correct default values" do
    auth_data = create_google_auth_hash(email: "defaultstest@example.com")

    user = User.from_omniauth(auth_data)
    assert user.persisted?
    assert_equal "USD", user.default_currency
    assert_equal 0.12, user.default_energy_cost_per_kwh
    assert_equal "en", user.locale
    assert_equal 1, user.next_invoice_number
  end

  test "OAuth authentication maintains data consistency" do
    auth_data = create_github_auth_hash(email: "consistency@example.com")

    # Create user via OAuth
    user1 = User.from_omniauth(auth_data)

    # Try to authenticate same user again
    user2 = User.from_omniauth(auth_data)

    assert_equal user1.id, user2.id
    assert_equal "github", user2.provider
    assert_equal "67890", user2.uid
  end

  private

  def create_google_auth_hash(email: "newuser@gmail.com", uid: "12345", name: "Test User")
    OpenStruct.new(
      provider: "google_oauth2",
      uid: uid,
      info: OpenStruct.new(
        email: email,
        name: name,
        first_name: name.split.first,
        last_name: name.split.last
      ),
      credentials: OpenStruct.new(
        token: "mock_google_token",
        refresh_token: "mock_google_refresh_token",
        expires_at: Time.current + 1.hour
      ),
      extra: OpenStruct.new(
        raw_info: OpenStruct.new(
          sub: uid,
          email: email,
          name: name
        )
      )
    )
  end

  def create_github_auth_hash(email: "githubuser@example.com", uid: "67890", name: "GitHub User")
    OpenStruct.new(
      provider: "github",
      uid: uid,
      info: OpenStruct.new(
        email: email,
        name: name,
        nickname: email.split("@").first
      ),
      credentials: OpenStruct.new(
        token: "mock_github_token"
      ),
      extra: OpenStruct.new(
        raw_info: OpenStruct.new(
          id: uid.to_i,
          login: email.split("@").first,
          email: email,
          name: name
        )
      )
    )
  end

  def create_microsoft_auth_hash(email: "msuser@outlook.com", uid: "98765", name: "Microsoft User")
    OpenStruct.new(
      provider: "microsoft_graph",
      uid: uid,
      info: OpenStruct.new(
        email: email,
        name: name,
        first_name: name.split.first,
        last_name: name.split.last
      ),
      credentials: OpenStruct.new(
        token: "mock_microsoft_token",
        refresh_token: "mock_ms_refresh_token",
        expires_at: Time.current + 1.hour
      ),
      extra: OpenStruct.new(
        raw_info: OpenStruct.new(
          id: uid,
          mail: email,
          displayName: name
        )
      )
    )
  end

  def create_facebook_auth_hash(email: "facebookuser@example.com", uid: "facebook123", name: "Facebook User")
    OpenStruct.new(
      provider: "facebook",
      uid: uid,
      info: OpenStruct.new(
        email: email,
        name: name,
        first_name: name.split.first,
        last_name: name.split.last,
        image: "https://graph.facebook.com/#{uid}/picture"
      ),
      credentials: OpenStruct.new(
        token: "mock_facebook_token",
        expires_at: Time.current + 2.months
      ),
      extra: OpenStruct.new(
        raw_info: OpenStruct.new(
          id: uid,
          email: email,
          name: name
        )
      )
    )
  end

  def create_yahoojp_auth_hash(email: "yahoojpuser@yahoo.co.jp", uid: "yahoojp456", name: "Yahoo Japan User")
    OpenStruct.new(
      provider: "yahoojp",
      uid: uid,
      info: OpenStruct.new(
        email: email,
        name: name,
        nickname: email.split("@").first
      ),
      credentials: OpenStruct.new(
        token: "mock_yahoojp_token",
        refresh_token: "mock_yahoojp_refresh_token",
        expires_at: Time.current + 1.hour
      ),
      extra: OpenStruct.new(
        raw_info: OpenStruct.new(
          sub: uid,
          email: email,
          name: name,
          locale: "ja-JP"
        )
      )
    )
  end
end
