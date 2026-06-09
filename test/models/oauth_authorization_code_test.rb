# frozen_string_literal: true

require "test_helper"

class OAuthAuthorizationCodeTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  # --- Creation & code generation --------------------------------------------

  test "generates a unique code on create" do
    code = OAuthAuthorizationCode.create!(
      user: @user,
      redirect_uri: "https://example.com/cb",
      client_id: "mcp"
    )
    assert code.code.present?
    assert code.code.length >= 32
  end

  test "sets expires_at to 10 minutes from now on create" do
    code = OAuthAuthorizationCode.create!(
      user: @user,
      redirect_uri: "https://example.com/cb",
      client_id: "mcp"
    )
    assert_in_delta 10.minutes.from_now.to_i, code.expires_at.to_i, 5
  end

  test "two codes have different values" do
    c1 = OAuthAuthorizationCode.create!(user: @user, redirect_uri: "https://ex.com", client_id: "mcp")
    c2 = OAuthAuthorizationCode.create!(user: @user, redirect_uri: "https://ex.com", client_id: "mcp")
    refute_equal c1.code, c2.code
  end

  # --- Active scope ----------------------------------------------------------

  test "active scope returns unexpired, unused codes" do
    code = oauth_authorization_codes(:active_code)
    assert_includes OAuthAuthorizationCode.active, code
  end

  test "active scope excludes expired codes" do
    code = oauth_authorization_codes(:expired_code)
    refute_includes OAuthAuthorizationCode.active, code
  end

  test "active scope excludes used codes" do
    code = oauth_authorization_codes(:used_code)
    refute_includes OAuthAuthorizationCode.active, code
  end

  # --- find_active -----------------------------------------------------------

  test "find_active returns the code by value when active" do
    code = oauth_authorization_codes(:active_code)
    found = OAuthAuthorizationCode.find_active(code.code)
    assert_equal code, found
  end

  test "find_active returns nil for expired code" do
    code = oauth_authorization_codes(:expired_code)
    assert_nil OAuthAuthorizationCode.find_active(code.code)
  end

  test "find_active returns nil for used code" do
    code = oauth_authorization_codes(:used_code)
    assert_nil OAuthAuthorizationCode.find_active(code.code)
  end

  test "find_active returns nil for unknown code" do
    assert_nil OAuthAuthorizationCode.find_active("nonexistent_code")
  end

  # --- mark_used! -----------------------------------------------------------

  test "mark_used! sets used_at" do
    code = oauth_authorization_codes(:active_code)
    assert_nil code.used_at
    code.mark_used!
    assert_not_nil code.used_at
  end

  test "mark_used! makes the code no longer active" do
    code = oauth_authorization_codes(:active_code)
    code.mark_used!
    assert_nil OAuthAuthorizationCode.find_active(code.code)
  end

  # --- PKCE verification ----------------------------------------------------

  test "verify_pkce! succeeds with correct S256 verifier" do
    verifier  = "test_verifier_s256_value_abcdefghij"
    challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)

    code = OAuthAuthorizationCode.create!(
      user: @user,
      redirect_uri: "https://example.com/cb",
      client_id: "mcp",
      code_challenge: challenge,
      code_challenge_method: "S256"
    )

    assert code.verify_pkce!(verifier)
  end

  test "verify_pkce! raises OAuthError with wrong verifier" do
    verifier  = "correct_verifier"
    challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)

    code = OAuthAuthorizationCode.create!(
      user: @user,
      redirect_uri: "https://example.com/cb",
      client_id: "mcp",
      code_challenge: challenge,
      code_challenge_method: "S256"
    )

    assert_raises(OAuthError) { code.verify_pkce!("wrong_verifier") }
  end

  test "verify_pkce! returns true when no challenge is set" do
    code = OAuthAuthorizationCode.create!(
      user: @user,
      redirect_uri: "https://example.com/cb",
      client_id: "mcp",
      code_challenge: nil
    )
    assert code.verify_pkce!("anything")
  end

  test "verify_pkce! succeeds with plain method" do
    verifier = "my_plain_verifier"
    code = OAuthAuthorizationCode.create!(
      user: @user,
      redirect_uri: "https://example.com/cb",
      client_id: "mcp",
      code_challenge: verifier,
      code_challenge_method: "plain"
    )
    assert code.verify_pkce!(verifier)
  end

  # --- Associations & validations -------------------------------------------

  test "requires redirect_uri" do
    code = OAuthAuthorizationCode.new(user: @user, client_id: "mcp")
    refute code.valid?
    assert_includes code.errors[:redirect_uri], "can't be blank"
  end

  test "requires client_id" do
    code = OAuthAuthorizationCode.new(user: @user, redirect_uri: "https://ex.com")
    refute code.valid?
    assert_includes code.errors[:client_id], "can't be blank"
  end

  test "belongs to a user" do
    code = OAuthAuthorizationCode.create!(
      user: @user,
      redirect_uri: "https://ex.com/cb",
      client_id: "mcp"
    )
    assert_equal @user, code.user
  end
end
