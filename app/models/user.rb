class User < ApplicationRecord
  include CurrencyAwareDefaults

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable,
         omniauth_providers: [ :google_oauth2, :github, :microsoft_graph, :facebook, :yahoojp, :line ]

  has_many :print_pricings, dependent: :destroy
  has_many :printers, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :filaments, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :usage_trackings, dependent: :destroy
  has_many :user_consents, dependent: :destroy
  has_one_attached :company_logo

  validates :default_currency, presence: true
  validates :default_energy_cost_per_kwh, presence: true, numericality: { greater_than: 0 }
  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }, allow_blank: true
  validates :next_invoice_number, presence: true, numericality: { greater_than: 0, only_integer: true }

  validates :default_prep_time_minutes, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true
  validates :default_prep_cost_per_hour, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :default_postprocessing_time_minutes, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true
  validates :default_postprocessing_cost_per_hour, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :default_other_costs, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :default_vat_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :default_listing_cost_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :default_payment_processing_cost_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :plan, inclusion: { in: %w[free startup pro] }, allow_blank: true

  before_validation :set_default_locale, on: :create
  before_validation :set_default_next_invoice_number, on: :create
  before_validation :set_trial_period, on: :create
  after_commit :clear_logo_cache, if: -> { saved_change_to_attribute?(:company_logo) || company_logo.attachment&.previous_changes&.any? }

  # Synchronize invoice counter with existing invoices
  def synchronize_invoice_counter!
    max_invoice_number = invoices.joins("").where("invoice_number ~ '^INV-[0-9]+$'")
                                .maximum("CAST(SUBSTRING(invoice_number FROM 5) AS INTEGER)")
    correct_next_number = (max_invoice_number || 0) + 1
    update!(next_invoice_number: correct_next_number)
  end

  # Subscription and plan management methods
  def in_trial_period?
    trial_ends_at.present? && trial_ends_at > Time.current
  end

  def trial_days_remaining
    return 0 unless in_trial_period?

    ((trial_ends_at - Time.current) / 1.day).ceil
  end

  def free_plan?
    plan == "free"
  end

  def startup_plan?
    plan == "startup"
  end

  # Admin users automatically have pro tier access regardless of their plan setting
  def pro_plan?
    admin? || plan == "pro"
  end

  # Admin users automatically have active subscription with pro tier benefits
  def active_subscription?
    return true if admin? # Admins always have active subscription
    return true if in_trial_period?
    return true if pro_plan? || startup_plan?

    plan_expires_at.present? && plan_expires_at > Time.current
  end

  def subscription_expired?
    !active_subscription? && plan_expires_at.present? && plan_expires_at < Time.current
  end

  def can_create?(resource_type)
    PlanLimits.can_create?(self, resource_type)
  end

  def limit_for(resource_type)
    PlanLimits.limit_for(self, resource_type)
  end

  def current_usage(resource_type)
    PlanLimits.current_usage(self, resource_type)
  end

  def remaining(resource_type)
    PlanLimits.remaining(self, resource_type)
  end

  def usage_percentage(resource_type)
    PlanLimits.usage_percentage(self, resource_type)
  end

  def approaching_limit?(resource_type)
    PlanLimits.approaching_limit?(self, resource_type)
  end

  def upgrade_to_startup!
    update!(
      plan: "startup",
      plan_expires_at: nil,
      trial_ends_at: nil
    )
  end

  def upgrade_to_pro!
    update!(
      plan: "pro",
      plan_expires_at: nil,
      trial_ends_at: nil
    )
  end

  def downgrade_to_free!
    update!(
      plan: "free",
      plan_expires_at: nil,
      trial_ends_at: nil,
      stripe_subscription_id: nil
    )
  end

  # OAuth methods
  def self.from_omniauth(auth)
    # Return nil if email is missing - controller will handle asking for it
    return nil if auth.info.email.blank?

    # First try to find user by provider and uid
    user = where(provider: auth.provider, uid: auth.uid).first

    # If not found, try to find by email
    if user.nil?
      user = where(email: auth.info.email).first_or_create do |new_user|
        new_user.email = auth.info.email
        new_user.provider = auth.provider
        new_user.uid = auth.uid
        new_user.skip_confirmation! if new_user.respond_to?(:skip_confirmation!)

        # Try to get name from OAuth data
        if auth.info.name.present?
          # Could split into first/last name if you have those fields
          # For now, we'll just store it in a way that works with your existing setup
        end

        # Generate a random password for OAuth users
        new_user.password = Devise.friendly_token[0, 20]
      end
    end

    # Update existing user with OAuth provider info if not already set
    if user.persisted? && (user.provider != auth.provider || user.uid != auth.uid)
      user.update(provider: auth.provider, uid: auth.uid)
    end

    user
  end

  # Create user from OAuth data with provided email
  def self.create_from_omniauth_with_email(auth, email)
    user = new do |new_user|
      new_user.email = email
      new_user.provider = auth["provider"]
      new_user.uid = auth["uid"]
      new_user.skip_confirmation! if new_user.respond_to?(:skip_confirmation!)

      # Generate a random password for OAuth users
      new_user.password = Devise.friendly_token[0, 20]
    end

    user.save
    user
  end

  def oauth_user?
    provider.present? && uid.present?
  end

  # GDPR Consent methods
  def has_accepted_consent?(consent_type)
    latest_consent = user_consents.for_type(consent_type).order(created_at: :desc).first
    latest_consent&.accepted == true
  end

  def has_accepted_cookies?
    has_accepted_consent?("cookies")
  end

  def has_accepted_privacy_policy?
    has_accepted_consent?("privacy_policy")
  end

  def has_accepted_terms?
    has_accepted_consent?("terms_of_service")
  end

  def record_consent(consent_type, accepted, ip_address: nil, user_agent: nil)
    user_consents.create!(
      consent_type: consent_type,
      accepted: accepted,
      ip_address: ip_address,
      user_agent: user_agent
    )
  end

  # Export user data for GDPR compliance
  def export_data
    {
      user: {
        email: email,
        created_at: created_at,
        locale: locale,
        default_currency: default_currency,
        company_logo: company_logo.attached? ? company_logo.filename.to_s : nil
      },
      print_pricings: print_pricings.as_json(include: :plates),
      printers: printers.as_json,
      invoices: invoices.as_json(include: :invoice_line_items),
      filaments: filaments.as_json,
      clients: clients.as_json,
      consents: user_consents.as_json
    }
  end

  # Cache user usage stats to avoid repeated COUNT queries
  # Called by PlanLimits service on every authenticated page
  # Cache key includes updated_at for automatic invalidation when user changes
  def cached_usage_stats
    Rails.cache.fetch([ "user", id, "usage_stats", updated_at ]) do
      {
        print_pricings: print_pricings.count,
        printers: printers.count,
        filaments: filaments.count,
        invoices: invoices.count,
        clients: clients.count
      }
    end
  end

  # Clear usage cache when resources change via touch
  def clear_usage_cache
    # Note: Not needed when using updated_at in cache key, but keeping for explicit clearing if needed
    Rails.cache.delete_matched("user/#{id}/usage_stats/*")
  end

  private

  def set_default_locale
    self.locale ||= "en"
  end

  def set_default_next_invoice_number
    self.next_invoice_number ||= 1
  end

  def set_trial_period
    # New users get a 30-day trial with Startup plan limits
    self.trial_ends_at ||= PlanLimits::TRIAL_DURATION.from_now
  end

  def clear_logo_cache
    Rails.cache.delete_matched("user/#{id}/company_logo/*")
  end
end
