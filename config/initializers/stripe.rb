# Stripe payment processing configuration
# For development/test: Use ENV variables from .env.local (loaded by dotenv-rails)
# For production: Use Rails credentials (encrypted)
#
# Development setup (.env.local):
#   STRIPE_PUBLISHABLE_KEY=pk_test_...
#   STRIPE_SECRET_KEY=sk_test_...
#   STRIPE_WEBHOOK_SECRET=whsec_...  # Auto-populated by bin/stripe-listen
#   STRIPE_STARTUP_PRICE_ID=price_...
#   STRIPE_PRO_PRICE_ID=price_...
#
# Production setup:
#   Run: EDITOR=nano rails credentials:edit
#   Add:
#     stripe:
#       publishable_key: pk_live_...
#       secret_key: sk_live_...
#       webhook_secret: whsec_...
#       startup_price_id: price_...
#       pro_price_id: price_...

# Determine source: ENV vars (dev/test) or credentials (production)
if Rails.env.development? || Rails.env.test?
  # Use ENV variables from .env.local
  if ENV["STRIPE_SECRET_KEY"].present?
    Stripe.api_key = ENV["STRIPE_SECRET_KEY"]

    Rails.configuration.stripe = {
      publishable_key: ENV["STRIPE_PUBLISHABLE_KEY"],
      secret_key: ENV["STRIPE_SECRET_KEY"],
      webhook_secret: ENV["STRIPE_WEBHOOK_SECRET"],
      startup_price_id: ENV["STRIPE_STARTUP_PRICE_ID"],
      pro_price_id: ENV["STRIPE_PRO_PRICE_ID"]
    }
  else
    Rails.logger.warn "⚠️  Stripe ENV variables not configured. Add them to .env.local"

    # Set dummy values if not configured
    Stripe.api_key = "sk_test_dummy_key_for_development"

    Rails.configuration.stripe = {
      publishable_key: "pk_test_dummy_key_for_development",
      secret_key: "sk_test_dummy_key_for_development",
      webhook_secret: "whsec_dummy_secret_for_development",
      startup_price_id: "price_dummy_startup",
      pro_price_id: "price_dummy_pro"
    }
  end
else
  # Production: Use Rails credentials
  if Rails.application.credentials.stripe.present?
    Stripe.api_key = Rails.application.credentials.stripe[:secret_key]

    Rails.configuration.stripe = {
      publishable_key: Rails.application.credentials.stripe[:publishable_key],
      secret_key: Rails.application.credentials.stripe[:secret_key],
      webhook_secret: Rails.application.credentials.stripe[:webhook_secret],
      startup_price_id: Rails.application.credentials.stripe[:startup_price_id],
      pro_price_id: Rails.application.credentials.stripe[:pro_price_id]
    }
  else
    raise "Stripe credentials not configured for production. Run: EDITOR=nano rails credentials:edit"
  end
end

# Stripe API version (update as needed)
Stripe.api_version = "2024-11-20.acacia"
