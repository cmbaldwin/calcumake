require "test_helper"

class UserConsentTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @consent = user_consents(:cookie_consent_user_one)
  end

  test "should belong to user" do
    assert_instance_of User, @consent.user
  end

  test "should validate presence of consent_type" do
    consent = @user.user_consents.build(accepted: true)
    assert_not consent.valid?
    assert_includes consent.errors[:consent_type], "can't be blank"
  end

  test "should validate inclusion of consent_type" do
    consent = @user.user_consents.build(consent_type: "invalid_type", accepted: true)
    assert_not consent.valid?
    assert_includes consent.errors[:consent_type], "is not included in the list"
  end

  test "should validate inclusion of accepted" do
    consent = @user.user_consents.build(consent_type: "cookies")
    assert consent.valid?
  end

  test "should accept valid consent types" do
    UserConsent::CONSENT_TYPES.each do |type|
      consent = @user.user_consents.build(consent_type: type, accepted: true)
      assert consent.valid?, "#{type} should be a valid consent type"
    end
  end

  test "accepted scope should return only accepted consents" do
    @user.user_consents.create!(consent_type: "privacy_policy", accepted: false, ip_address: "127.0.0.1")
    @user.user_consents.create!(consent_type: "terms_of_service", accepted: true, ip_address: "127.0.0.1")

    accepted_consents = @user.user_consents.accepted
    assert accepted_consents.all? { |c| c.accepted == true }
  end

  test "rejected scope should return only rejected consents" do
    @user.user_consents.create!(consent_type: "privacy_policy", accepted: false, ip_address: "127.0.0.1")

    rejected_consents = @user.user_consents.rejected
    assert rejected_consents.all? { |c| c.accepted == false }
  end

  test "for_type scope should return consents of specific type" do
    @user.user_consents.create!(consent_type: "cookies", accepted: true, ip_address: "127.0.0.1")
    @user.user_consents.create!(consent_type: "privacy_policy", accepted: true, ip_address: "127.0.0.1")

    cookie_consents = @user.user_consents.for_type("cookies")
    assert cookie_consents.all? { |c| c.consent_type == "cookies" }
  end

  test "latest_for_user_and_type should return most recent consent" do
    older_consent = @user.user_consents.create!(
      consent_type: "cookies",
      accepted: false,
      ip_address: "127.0.0.1",
      created_at: 2.days.ago
    )
    newer_consent = @user.user_consents.create!(
      consent_type: "cookies",
      accepted: true,
      ip_address: "127.0.0.1",
      created_at: 1.day.ago
    )

    latest = UserConsent.latest_for_user_and_type(@user, "cookies")
    assert_equal newer_consent.id, latest.id
  end

  test "should store IP address and user agent" do
    consent = @user.user_consents.create!(
      consent_type: "cookies",
      accepted: true,
      ip_address: "192.168.1.1",
      user_agent: "Mozilla/5.0"
    )

    assert_equal "192.168.1.1", consent.ip_address
    assert_equal "Mozilla/5.0", consent.user_agent
  end
end
