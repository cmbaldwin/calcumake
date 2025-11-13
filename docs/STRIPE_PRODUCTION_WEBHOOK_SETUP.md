# Stripe Production Webhook Setup - Quick Reference

## Current Status

You're at the "Create an event destination" screen in Stripe Dashboard for production webhooks.

## Configuration Details

### Form Fields to Fill

1. **Destination name**: `calcumake-production-webhooks` (or keep "charismatic-breeze")
2. **Endpoint URL**: `https://calcumake.com/webhooks/stripe`
3. **Description**: `CalcuMake subscription and payment webhooks for production environment`
4. **Events from**: Your account
5. **Payload style**: Snapshot
6. **API version**: `2025-10-29.clover` (as shown in your dashboard)
7. **Listening to**: 12 events (see below)

### Events to Select

Select these 12 events before clicking "Create destination":

**Checkout Events (1):**
- ✅ `checkout.session.completed`

**Customer Events (2):**
- ✅ `customer.subscription.created`
- ✅ `customer.subscription.deleted`
- ✅ `customer.subscription.paused`
- ✅ `customer.subscription.resumed`
- ✅ `customer.subscription.trial_will_end`
- ✅ `customer.subscription.updated`
- ✅ `customer.updated`

**Invoice Events (3):**
- ✅ `invoice.paid`
- ✅ `invoice.payment_failed`
- ✅ `invoice.payment_succeeded`

**Payment Method Events (1):**
- ✅ `payment_method.attached`

### After Creating Webhook

1. **Copy the webhook signing secret** (starts with `whsec_`)
2. **Add to Rails credentials** (do NOT add to .env.local for production):

```bash
EDITOR=nano rails credentials:edit
```

Add:
```yaml
stripe:
  publishable_key: pk_live_...  # Your live publishable key
  secret_key: sk_live_...        # Your live secret key
  webhook_secret: whsec_...      # From webhook creation screen
  startup_price_id: price_...    # Live price ID for Startup plan
  pro_price_id: price_...        # Live price ID for Pro plan
```

3. **Deploy to production** with updated credentials
4. **Test webhook** by creating a test subscription in production dashboard

## Important Notes

### About invoice.payment_action_required

This event **does not exist** in Stripe's current API. Authentication issues (SCA/3D Secure) are handled through:
- `invoice.payment_failed` - Catches authentication failures
- Customer portal automatically handles SCA when needed

### Unhandled Events

The webhook controller logs unhandled events safely:
```ruby
Rails.logger.info "Unhandled event type: #{event.type}"
```

So enabling extra events won't cause issues - they'll just be logged for future implementation.

### Current Handler Implementation

✅ Fully implemented:
- `customer.subscription.created` → Activates user subscription
- `customer.subscription.updated` → Updates plan/expiration
- `customer.subscription.deleted` → Downgrades to free
- `invoice.payment_succeeded` → Updates subscription expiration
- `invoice.payment_failed` → Logs failure (TODO: send email)
- `checkout.session.completed` → Links customer/subscription IDs

⏸️ Not yet implemented (will be logged only):
- `customer.subscription.paused`
- `customer.subscription.resumed`
- `customer.subscription.trial_will_end`
- `customer.updated`
- `invoice.paid`
- `payment_method.attached`

## Verification

After setup, verify webhooks work:

1. Go to Stripe Dashboard → Developers → Webhooks
2. Click on your endpoint
3. Click "Send test webhook"
4. Select `customer.subscription.created`
5. Check response is `200 OK`
6. Check Rails logs for: `✓ Subscription created for user...`

## Troubleshooting

**Webhook returns 400/500:**
- Check Rails logs: `tail -f log/production.log | grep Stripe`
- Verify webhook secret in credentials matches Stripe Dashboard
- Ensure endpoint is accessible: `curl https://calcumake.com/webhooks/stripe`

**Events not triggering:**
- Verify events are selected in Stripe Dashboard
- Check webhook is enabled (not paused)
- Test with "Send test webhook" button
