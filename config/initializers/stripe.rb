# Stripe payment processing configuration
# Uses ENV variables for all environments (loaded by dotenv-rails in dev/test, Kamal in production)
#
# Development setup (.env.local):
#   STRIPE_PUBLISHABLE_KEY=pk_test_...
#   STRIPE_SECRET_KEY=sk_test_...
#   STRIPE_WEBHOOK_SECRET=whsec_...  # Auto-populated by bin/stripe-listen
#   STRIPE_STARTUP_PRICE_ID=price_...
#   STRIPE_PRO_PRICE_ID=price_...
#
# Production setup (Kamal):
#   Configure in .kamal/secrets (pulls from 1Password)
#   ENV variables are injected via config/deploy.yml

# Use ENV variables for all environments
# Development: from .env.local (loaded by dotenv-rails)
# Production: from Kamal secrets (injected via deploy.yml)
if ENV["STRIPE_SECRET_KEY"].present?
  Stripe.api_key = ENV["STRIPE_SECRET_KEY"]

  Rails.configuration.stripe = {
    publishable_key: ENV["STRIPE_PUBLISHABLE_KEY"],
    secret_key: ENV["STRIPE_SECRET_KEY"],
    webhook_secret: ENV["STRIPE_WEBHOOK_SECRET"],
    startup_price_id: ENV["STRIPE_STARTUP_PRICE_ID"],
    pro_price_id: ENV["STRIPE_PRO_PRICE_ID"]
  }
elsif ENV["SECRET_KEY_BASE_DUMMY"].present?
  # Asset precompilation doesn't need real Stripe credentials
  Stripe.api_key = "sk_dummy_for_precompile"

  Rails.configuration.stripe = {
    publishable_key: "pk_dummy_for_precompile",
    secret_key: "sk_dummy_for_precompile",
    webhook_secret: "whsec_dummy_for_precompile",
    startup_price_id: "price_dummy_startup",
    pro_price_id: "price_dummy_pro"
  }
else
  # Allow app to boot for tasks like db:prepare, but log warning
  warning_msg = Rails.env.development? ?
    "⚠️  Stripe ENV variables not configured. Add them to .env.local" :
    "⚠️  Stripe ENV variables not configured. Set via Kamal secrets"
  Rails.logger.warn warning_msg

  # Set dummy values to allow boot
  Stripe.api_key = "sk_dummy_for_boot"

  Rails.configuration.stripe = {
    publishable_key: "pk_dummy_for_boot",
    secret_key: "sk_dummy_for_boot",
    webhook_secret: "whsec_dummy_for_boot",
    startup_price_id: "price_dummy_startup",
    pro_price_id: "price_dummy_pro"
  }
end

# Stripe API version (update as needed)
Stripe.api_version = "2024-11-20.acacia"
