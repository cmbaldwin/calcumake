# Stripe payment processing configuration
# API keys are stored in Rails credentials (encrypted)
#
# To set up Stripe credentials:
# 1. Run: EDITOR=nano rails credentials:edit
# 2. Add the following:
#    stripe:
#      publishable_key: pk_test_...  # Your Stripe publishable key
#      secret_key: sk_test_...        # Your Stripe secret key
#      webhook_secret: whsec_...      # Your webhook signing secret
#
# For production, use live keys (pk_live_... and sk_live_...)

if Rails.application.credentials.stripe.present?
  Stripe.api_key = Rails.application.credentials.stripe[:secret_key]

  Rails.configuration.stripe = {
    publishable_key: Rails.application.credentials.stripe[:publishable_key],
    secret_key: Rails.application.credentials.stripe[:secret_key],
    webhook_secret: Rails.application.credentials.stripe[:webhook_secret]
  }
else
  Rails.logger.warn "⚠️  Stripe credentials not configured. Add them with 'rails credentials:edit'"

  # Set dummy values for development if credentials aren't set
  if Rails.env.development? || Rails.env.test?
    Stripe.api_key = "sk_test_REDACTED_key_for_development"

    Rails.configuration.stripe = {
      publishable_key: "pk_test_REDACTED_key_for_development",
      secret_key: "sk_test_REDACTED_key_for_development",
      webhook_secret: "whsec_dummy_secret_for_development"
    }
  end
end

# Stripe API version (update as needed)
Stripe.api_version = "2024-11-20.acacia"
