# Stripe Integration Setup Guide

## Overview

CalcuMake uses Stripe Checkout for subscription management with automatic webhook handling. The integration is 95% complete and ready for testing.

## Development Setup

### 1. Stripe CLI Authentication

The Stripe CLI should already be authenticated. Verify with:

```bash
stripe config --list
```

You should see:
- Account: `acct_1R9yZSDkapT94HR1`
- Test keys starting with `sk_test_51R9yZS...`

### 2. Environment Configuration

All Stripe configuration is in `.env.local`:

```bash
# Automatically configured
STRIPE_PUBLISHABLE_KEY=pk_test_51R9yZSDkapT94HR1yMHHFqD5XvRLOwpbKNB1oEVNJ9aCJU8sUdqpyloanCK46tU5kHAPk4iF4D9n21IdFCXy37VS00Q8GwfuVe
STRIPE_SECRET_KEY=sk_test_51R9yZSDkapT94HR19Qg4oYamzdP7sYrU9wmOgKsfVFMR7SpoR2MOK9mjzuZEz5TPgckkQ4q2MLWHM7E0uf7G3fL800ZbnHVKBC
STRIPE_WEBHOOK_SECRET=                                # Auto-populated by bin/stripe-listen
STRIPE_STARTUP_PRICE_ID=price_1SStMeDkapT94HR1vGXLi0kx  # $0.99/month
STRIPE_PRO_PRICE_ID=price_1SStQYDkapT94HR1fFNyOa9a      # $9.99/month
```

### 3. Products Created

Two subscription products are configured in your Stripe Sandbox:

**Startup Plan** ($0.99/month)
- Product ID: `prod_TPiaAO4HA5vz9x`
- Price ID: `price_1SStMeDkapT94HR1vGXLi0kx`
- Features: 50 print pricings, 10 printers, 16 filaments, unlimited invoices

**Pro Plan** ($9.99/month)
- Product ID: `prod_TPiq0Na4dHUHzn`
- Price ID: `price_1SStQYDkapT94HR1fFNyOa9a`
- Features: Unlimited everything

### 4. Start Development Server

```bash
bin/dev
```

This automatically:
1. Starts Rails server on port 3000
2. Starts Stripe webhook listener
3. Captures webhook secret and saves to `.env.local`
4. Forwards webhooks to `localhost:3000/webhooks/stripe`

## Testing the Integration

### 1. Test Checkout Flow

1. Start the server: `bin/dev`
2. Sign in to CalcuMake
3. Visit `/subscriptions/pricing`
4. Click "Upgrade to Startup" or "Upgrade to Pro"
5. Use test card: `4242 4242 4242 4242`
   - Expiry: Any future date (e.g., 12/34)
   - CVC: Any 3 digits (e.g., 123)
   - ZIP: Any 5 digits (e.g., 12345)

### 2. Test Webhooks

Trigger specific webhook events manually:

```bash
# Test successful subscription creation
stripe trigger customer.subscription.created

# Test subscription update
stripe trigger customer.subscription.updated

# Test subscription cancellation
stripe trigger customer.subscription.deleted

# Test successful payment
stripe trigger invoice.payment_succeeded

# Test failed payment
stripe trigger invoice.payment_failed
```

### 3. View Webhook Logs

Watch webhook activity in real-time:

```bash
# In the terminal running bin/dev, you'll see:
# stripe | --> customer.subscription.created [evt_...]
# stripe | <-- [200] POST http://localhost:3000/webhooks/stripe
```

Or check Rails logs:

```bash
tail -f log/development.log | grep Stripe
```

## What Works

✅ **Checkout Flow**
- Create customer in Stripe
- Generate checkout session
- Redirect to Stripe hosted checkout
- Handle successful payment
- Upgrade user plan

✅ **Webhooks**
- `customer.subscription.created` - Activates subscription
- `customer.subscription.updated` - Updates plan/renewal
- `customer.subscription.deleted` - Downgrades to free
- `invoice.payment_succeeded` - Extends subscription
- `invoice.payment_failed` - Logs failed payment
- `checkout.session.completed` - Links customer/subscription

**Production Webhook Events (12 recommended):**
- `checkout.session.completed`
- `customer.subscription.created`
- `customer.subscription.deleted`
- `customer.subscription.paused`
- `customer.subscription.resumed`
- `customer.subscription.trial_will_end`
- `customer.subscription.updated`
- `customer.updated`
- `invoice.paid`
- `invoice.payment_failed`
- `invoice.payment_succeeded`
- `payment_method.attached`

Note: `invoice.payment_action_required` does not exist in Stripe's event catalog. SCA/3D Secure failures are handled via `invoice.payment_failed`.

✅ **Customer Portal**
- Manage subscription
- Update payment method
- Cancel subscription
- View invoices

✅ **Plan Enforcement**
- Tracks usage for all resources
- Enforces limits per plan
- Shows usage percentage
- Blocks creation at limit

## What's Not Implemented Yet

⚠️ **Email Notifications**
- Failed payment emails (webhook handler has TODO)
- Subscription confirmation emails
- Approaching limit warnings

⚠️ **Controller Tests**
- SubscriptionsController tests (stubbed with WebMock)
- Webhooks::StripeController tests

## Troubleshooting

### Webhook secret not auto-populating

If `STRIPE_WEBHOOK_SECRET` remains empty:

1. Check that `bin/stripe-listen` is executable: `ls -la bin/stripe-listen`
2. Check that Stripe CLI is installed: `which stripe`
3. Manually get secret: `stripe listen --print-secret`
4. Add to `.env.local`: `STRIPE_WEBHOOK_SECRET=whsec_...`

### Wrong Stripe account

If you see products/prices from a different account:

1. Check Stripe CLI config: `stripe config --list`
2. Login to correct account: `stripe login`
3. Verify account ID matches: `acct_1R9yZSDkapT94HR1`

### Checkout redirects to wrong URL

Update success/cancel URLs in `app/controllers/subscriptions_controller.rb`:

```ruby
success_url: subscription_success_url(session_id: "{CHECKOUT_SESSION_ID}"),
cancel_url: pricing_subscriptions_url
```

## Production Setup

For production, use Rails encrypted credentials instead of ENV variables:

```bash
EDITOR=nano rails credentials:edit
```

Add:

```yaml
stripe:
  publishable_key: pk_live_...
  secret_key: sk_live_...
  webhook_secret: whsec_...  # From Stripe Dashboard webhook config
  startup_price_id: price_...
  pro_price_id: price_...
```

### Production Webhook Configuration

After deploying to production, configure webhooks in Stripe Dashboard:

1. **Go to**: Developers → Webhooks → Create an event destination
2. **Endpoint URL**: `https://calcumake.com/webhooks/stripe`
3. **API Version**: `2025-10-29.clover` (or latest available)
4. **Select Events** (12 events):
   - `checkout.session.completed`
   - `customer.subscription.created`
   - `customer.subscription.deleted`
   - `customer.subscription.paused`
   - `customer.subscription.resumed`
   - `customer.subscription.trial_will_end`
   - `customer.subscription.updated`
   - `customer.updated`
   - `invoice.paid`
   - `invoice.payment_failed`
   - `invoice.payment_succeeded`
   - `payment_method.attached`

5. **Copy webhook signing secret** (starts with `whsec_`) and add to Rails credentials:

```bash
EDITOR=nano rails credentials:edit
```

Add under `stripe:`:
```yaml
webhook_secret: whsec_...  # From Stripe Dashboard
```

6. **Deploy** and verify webhooks are working by checking Stripe Dashboard → Webhooks → [Your endpoint] → View logs
