# frozen_string_literal: true

class ApiToken < ApplicationRecord
  belongs_to :user

  # Token is only available in memory immediately after creation
  attr_accessor :plain_token

  EXPIRATION_OPTIONS = {
    "30_days" => 30.days,
    "90_days" => 90.days,
    "1_year" => 1.year,
    "never" => nil
  }.freeze

  DEFAULT_EXPIRATION = "90_days"
  TOKEN_PREFIX = "cm_"
  TOKEN_LENGTH = 32

  validates :name, presence: true, length: { maximum: 100 }
  validates :token_digest, presence: true, uniqueness: true
  validates :token_hint, presence: true

  before_validation :generate_token, on: :create

  scope :active, -> { where(revoked_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :revoked, -> { where.not(revoked_at: nil) }

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def never_expires?
    expires_at.nil?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def revoked?
    revoked_at.present?
  end

  def active?
    !revoked? && !expired?
  end

  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end

  def days_until_expiration
    return nil if never_expires?
    return 0 if expired?

    ((expires_at - Time.current) / 1.day).ceil
  end

  # Class method to authenticate - uses digest for constant-time lookup
  def self.authenticate(token)
    return nil if token.blank?
    return nil unless token.start_with?(TOKEN_PREFIX)

    digest = Digest::SHA256.hexdigest(token)
    api_token = find_by(token_digest: digest)

    return nil unless api_token&.active?

    api_token.touch_last_used!
    api_token
  end

  # Parse expiration option and return duration
  def self.expiration_duration(option)
    EXPIRATION_OPTIONS[option.to_s]
  end

  private

  def generate_token
    return if token_digest.present?

    raw_token = SecureRandom.urlsafe_base64(TOKEN_LENGTH)
    self.plain_token = "#{TOKEN_PREFIX}#{raw_token}"

    self.token_digest = Digest::SHA256.hexdigest(plain_token)
    self.token_hint = "#{plain_token[0..6]}...#{plain_token[-4..]}"
  end
end
