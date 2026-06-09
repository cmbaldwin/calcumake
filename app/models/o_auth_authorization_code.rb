# frozen_string_literal: true

class OAuthAuthorizationCode < ApplicationRecord
  self.table_name = "oauth_authorization_codes"

  belongs_to :user

  validates :redirect_uri, presence: true
  validates :client_id, presence: true

  scope :active, -> { where(used_at: nil).where("expires_at > ?", Time.current) }

  before_create :generate_code_and_expiry

  def self.find_active(code)
    active.find_by(code: code)
  end

  def mark_used!
    update!(used_at: Time.current)
  end

  def verify_pkce!(code_verifier)
    return true if code_challenge.blank?

    verified = case code_challenge_method
    when "S256"
      expected = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)
      ActiveSupport::SecurityUtils.secure_compare(expected, code_challenge)
    when "plain"
      ActiveSupport::SecurityUtils.secure_compare(code_verifier.to_s, code_challenge)
    else
      false
    end

    raise OAuthError.new("PKCE verification failed", error_code: "invalid_grant") unless verified
    true
  end

  private

  def generate_code_and_expiry
    self.code = SecureRandom.urlsafe_base64(32)
    self.expires_at ||= 10.minutes.from_now
  end
end
