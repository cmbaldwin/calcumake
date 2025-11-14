class UserConsent < ApplicationRecord
  belongs_to :user

  CONSENT_TYPES = %w[cookies privacy_policy terms_of_service].freeze

  validates :consent_type, presence: true, inclusion: { in: CONSENT_TYPES }
  validates :accepted, inclusion: { in: [ true, false ] }

  scope :accepted, -> { where(accepted: true) }
  scope :rejected, -> { where(accepted: false) }
  scope :for_type, ->(type) { where(consent_type: type) }
  scope :recent, -> { order(created_at: :desc) }

  def self.latest_for_user_and_type(user, consent_type)
    where(user: user, consent_type: consent_type).order(created_at: :desc).first
  end
end
