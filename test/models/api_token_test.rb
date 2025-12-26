# frozen_string_literal: true

require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @active_token = api_tokens(:active_token)
    @expired_token = api_tokens(:expired_token)
    @revoked_token = api_tokens(:revoked_token)
    @never_expires_token = api_tokens(:never_expires_token)
  end

  # Validation tests
  test "should be valid with valid attributes" do
    token = @user.api_tokens.build(name: "Test Token")
    assert token.valid?
  end

  test "should require name" do
    token = @user.api_tokens.build(name: nil)
    assert_not token.valid?
    assert_includes token.errors[:name], "can't be blank"
  end

  test "should require name within 100 characters" do
    token = @user.api_tokens.build(name: "a" * 101)
    assert_not token.valid?
    assert_includes token.errors[:name], "is too long (maximum is 100 characters)"
  end

  test "should allow name up to 100 characters" do
    token = @user.api_tokens.build(name: "a" * 100)
    assert token.valid?
  end

  test "should require user" do
    token = ApiToken.new(name: "Test Token")
    assert_not token.valid?
    assert_includes token.errors[:user], "must exist"
  end

  test "token_digest should be unique" do
    token1 = @user.api_tokens.create!(name: "Token 1")
    token2 = @user.api_tokens.build(name: "Token 2")
    token2.token_digest = token1.token_digest
    assert_not token2.valid?
    assert_includes token2.errors[:token_digest], "has already been taken"
  end

  # Token generation tests
  test "should generate token on create" do
    token = @user.api_tokens.build(name: "New Token")
    assert_nil token.token_digest

    token.save!

    assert token.token_digest.present?
    assert token.token_hint.present?
    assert token.plain_token.present?
  end

  test "plain_token should start with cm_ prefix" do
    token = @user.api_tokens.create!(name: "Prefixed Token")
    assert token.plain_token.start_with?(ApiToken::TOKEN_PREFIX)
  end

  test "token_hint should show start and end of token" do
    token = @user.api_tokens.create!(name: "Hinted Token")
    assert token.token_hint.include?("...")
    assert token.token_hint.start_with?("cm_")
  end

  test "token_digest should be SHA256 hash of plain_token" do
    token = @user.api_tokens.create!(name: "Hashed Token")
    expected_digest = Digest::SHA256.hexdigest(token.plain_token)
    assert_equal expected_digest, token.token_digest
  end

  test "should not regenerate token on update" do
    token = @user.api_tokens.create!(name: "Original Name")
    original_digest = token.token_digest

    token.update!(name: "Updated Name")
    token.reload

    assert_equal original_digest, token.token_digest
  end

  # Status tests
  test "active? should return true for active token" do
    assert @active_token.active?
  end

  test "active? should return false for expired token" do
    assert_not @expired_token.active?
  end

  test "active? should return false for revoked token" do
    assert_not @revoked_token.active?
  end

  test "expired? should return true for expired token" do
    assert @expired_token.expired?
  end

  test "expired? should return false for non-expired token" do
    assert_not @active_token.expired?
  end

  test "expired? should return false for never-expires token" do
    assert_not @never_expires_token.expired?
  end

  test "revoked? should return true for revoked token" do
    assert @revoked_token.revoked?
  end

  test "revoked? should return false for non-revoked token" do
    assert_not @active_token.revoked?
  end

  test "never_expires? should return true for token without expiration" do
    assert @never_expires_token.never_expires?
  end

  test "never_expires? should return false for token with expiration" do
    assert_not @active_token.never_expires?
  end

  # Revoke tests
  test "revoke! should set revoked_at" do
    assert_nil @active_token.revoked_at
    @active_token.revoke!
    assert @active_token.revoked_at.present?
    assert @active_token.revoked?
  end

  # Last used tests
  test "touch_last_used! should update last_used_at" do
    original_last_used = @active_token.last_used_at

    travel 1.minute do
      @active_token.touch_last_used!
    end

    @active_token.reload
    assert @active_token.last_used_at > original_last_used if original_last_used
    assert @active_token.last_used_at.present?
  end

  # Days until expiration tests
  test "days_until_expiration should return nil for never-expires token" do
    assert_nil @never_expires_token.days_until_expiration
  end

  test "days_until_expiration should return 0 for expired token" do
    assert_equal 0, @expired_token.days_until_expiration
  end

  test "days_until_expiration should return correct days for active token" do
    token = @user.api_tokens.create!(name: "5 Day Token")
    token.update_column(:expires_at, 5.days.from_now)
    assert_equal 5, token.days_until_expiration
  end

  # Scope tests
  test "active scope should return only active tokens" do
    active_tokens = @user.api_tokens.active

    assert_includes active_tokens, @active_token
    assert_includes active_tokens, @never_expires_token
    assert_not_includes active_tokens, @expired_token
    assert_not_includes active_tokens, @revoked_token
  end

  test "expired scope should return only expired tokens" do
    expired_tokens = @user.api_tokens.expired

    assert_includes expired_tokens, @expired_token
    assert_not_includes expired_tokens, @active_token
    assert_not_includes expired_tokens, @never_expires_token
  end

  test "revoked scope should return only revoked tokens" do
    revoked_tokens = @user.api_tokens.revoked

    assert_includes revoked_tokens, @revoked_token
    assert_not_includes revoked_tokens, @active_token
    assert_not_includes revoked_tokens, @expired_token
  end

  # Authentication tests
  test "authenticate should return token for valid plain_token" do
    token = @user.api_tokens.create!(name: "Auth Test Token")
    plain_token = token.plain_token

    authenticated = ApiToken.authenticate(plain_token)

    assert_equal token.id, authenticated.id
  end

  test "authenticate should return nil for invalid token" do
    assert_nil ApiToken.authenticate("cm_invalid_token_12345")
  end

  test "authenticate should return nil for blank token" do
    assert_nil ApiToken.authenticate("")
    assert_nil ApiToken.authenticate(nil)
  end

  test "authenticate should return nil for token without prefix" do
    assert_nil ApiToken.authenticate("no_prefix_token")
  end

  test "authenticate should return nil for expired token" do
    # Create a token with known plain_token that's expired
    token = @user.api_tokens.create!(name: "Expired Auth Test")
    plain_token = token.plain_token
    token.update_column(:expires_at, 1.day.ago)

    assert_nil ApiToken.authenticate(plain_token)
  end

  test "authenticate should return nil for revoked token" do
    token = @user.api_tokens.create!(name: "Revoked Auth Test")
    plain_token = token.plain_token
    token.revoke!

    assert_nil ApiToken.authenticate(plain_token)
  end

  test "authenticate should update last_used_at" do
    token = @user.api_tokens.create!(name: "Usage Track Token")
    plain_token = token.plain_token
    assert_nil token.last_used_at

    ApiToken.authenticate(plain_token)

    token.reload
    assert token.last_used_at.present?
  end

  # Expiration duration tests
  test "expiration_duration should return correct duration for 30_days" do
    assert_equal 30.days, ApiToken.expiration_duration("30_days")
  end

  test "expiration_duration should return correct duration for 90_days" do
    assert_equal 90.days, ApiToken.expiration_duration("90_days")
  end

  test "expiration_duration should return correct duration for 1_year" do
    assert_equal 1.year, ApiToken.expiration_duration("1_year")
  end

  test "expiration_duration should return nil for never" do
    assert_nil ApiToken.expiration_duration("never")
  end

  test "expiration_duration should return nil for unknown option" do
    assert_nil ApiToken.expiration_duration("unknown")
  end

  # Association tests
  test "should belong to user" do
    assert_respond_to @active_token, :user
    assert_equal @user, @active_token.user
  end

  test "should be destroyed when user is destroyed" do
    user = User.create!(
      email: "api_test@example.com",
      password: "password123",
      default_currency: "USD",
      default_energy_cost_per_kwh: 0.12
    )
    token = user.api_tokens.create!(name: "User Delete Test")
    token_id = token.id

    user.destroy

    assert_nil ApiToken.find_by(id: token_id)
  end

  # Constants tests
  test "should have expected constant values" do
    assert_equal "cm_", ApiToken::TOKEN_PREFIX
    assert_equal 32, ApiToken::TOKEN_LENGTH
    assert_equal "90_days", ApiToken::DEFAULT_EXPIRATION
    assert_equal({ "30_days" => 30.days, "90_days" => 90.days, "1_year" => 1.year, "never" => nil }, ApiToken::EXPIRATION_OPTIONS)
  end
end
