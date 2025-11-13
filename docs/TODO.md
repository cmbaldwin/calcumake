# CalcuMake - Remaining Tasks

## Current Status
- **Pricing Updated**: ¥150/month ($1.50 USD) Startup, ¥1500/month ($15 USD) Pro
- **Test Results**: 17 failures + 12 errors (down from 21F + 15E)
- **Stripe Integration**: ~95% complete, needs final testing
- **Commerce Disclosure**: Ready at `/commerce-disclosure` for Stripe verification

## High Priority

### 1. Test Remaining Failures (17 failures, 12 errors)
Current test results show 29 issues remaining. Most are likely:
- Missing translation keys
- Controller test failures (navbar, authentication redirects)
- PrintPricingTest calculation issues
- View/partial rendering issues

**Action**: Run individual failing tests to identify specific issues:
```bash
bin/rails test --verbose
```

### 2. Test Stripe Integration in Development
**What to test**:
- Start server with webhook forwarding: `bin/dev`
- Verify webhook secret is captured automatically
- Test subscription checkout flow (both Startup and Pro tiers)
- Verify webhook events are received:
  - `customer.subscription.created`
  - `customer.subscription.updated`
  - `invoice.payment_succeeded`
- Test Customer Portal (manage subscription, cancel, update payment)

**Expected behavior**:
- Webhook secret auto-populates in `.env.local`
- Both Rails server (port 3000) and Stripe webhook listener start
- Checkout redirects to Stripe's hosted page
- Subscription activates after successful payment

### 3. Stripe Production Setup
Once dev testing is complete:

1. **Create Products in Stripe Production**:
   ```bash
   # Switch to production keys
   stripe login

   # Create Startup product
   stripe products create \
     --name="Startup" \
     --description="CalcuMake Startup Plan"

   # Create Startup price
   stripe prices create \
     --product=prod_xxx \
     --unit-amount=150 \
     --currency=jpy \
     --recurring[interval]=month

   # Create Pro product
   stripe products create \
     --name="Pro" \
     --description="CalcuMake Pro Plan"

   # Create Pro price
   stripe prices create \
     --product=prod_yyy \
     --unit-amount=1500 \
     --currency=jpy \
     --recurring[interval]=month
   ```

2. **Configure Production Webhooks**:
   - Go to Stripe Dashboard → Developers → Webhooks
   - Create endpoint: `https://calcumake.com/webhooks/stripe`
   - Add 12 events (see `docs/STRIPE_PRODUCTION_WEBHOOK_SETUP.md`)
   - Copy webhook signing secret

3. **Update Rails Credentials**:
   ```bash
   EDITOR=nano rails credentials:edit
   ```

   Add:
   ```yaml
   stripe:
     publishable_key: pk_live_...
     secret_key: sk_live_...
     webhook_secret: whsec_...
     startup_price_id: price_...
     pro_price_id: price_...
   ```

4. **Complete Stripe Business Verification**:
   - Submit Tokibo-Tohon (登記簿謄本) and supporting documents
   - Provide commerce disclosure URL: `https://calcumake.com/commerce-disclosure`

## Medium Priority

### 4. Fix Translation Coverage
Some translations may still be using placeholder English text. Verify all keys are properly translated:

```bash
# Check for "Total Estimated Sales" placeholder in non-English files
grep -r "Total Estimated Sales" config/locales/*.yml
```

If found, translations should be:
- **ja**: 推定総売上
- **zh-CN**: 预估总销售额
- **hi**: कुल अनुमानित बिक्री
- **es**: Ventas Totales Estimadas
- **fr**: Total des Ventes Estimées
- **ar**: إجمالي المبيعات المقدرة

### 5. Verify Plan Limits Enforcement
Test that plan limits are properly enforced in the UI:

**Free Plan Limits** (after 30-day trial):
- 5 print_pricings
- 1 printer
- 4 filaments
- 5 invoices

**Startup Plan Limits**:
- 50 print_pricings
- 10 printers
- 16 filaments
- Unlimited invoices

**Pro Plan**:
- Unlimited everything

**Test scenarios**:
1. Create printer when at limit → Should show flash message
2. Create filament when at limit → Should show flash message
3. Create print_pricing when at limit → Should show flash message
4. Create invoice when at limit → Should show flash message
5. Verify "Upgrade" link redirects to `/subscriptions/pricing`

### 6. Landing Page Pricing Update
Verify landing page displays correct pricing (currently may show old $0.99/$9.99):
- Check `app/views/pages/landing.html.erb` or pricing partial
- Should display: $1.50/month (Startup), $15/month (Pro)

## Low Priority

### 7. Update Documentation
- Update `CLAUDE.md` with final Stripe integration status
- Archive any obsolete documentation in `docs/archive/`
- Ensure all Stripe docs reference correct pricing

### 8. Code Quality
- Run Rubocop: `bin/rubocop`
- Run Brakeman security scan: `bin/brakeman`
- Address any critical security issues

### 9. Performance Testing
- Test with realistic data volumes
- Monitor Stripe API call performance
- Check database query efficiency for plan limit checks

## Notes

### Recent Changes
- **2025-01-13**: Updated pricing from ¥99/$0.99 and ¥999/$9.99 to ¥150/$1.50 and ¥1500/$15
- **2025-01-13**: Fixed PlanLimits tests - all 25 tests now passing
- **2025-01-13**: Created `shared/_flash` partial for limit warnings
- **2025-01-13**: Updated `usage_limits.limit_reached` translation with parameters
- **2025-01-13**: Refactored plan limits from UsageTracking to actual record counts

### Key Files
- Plan Limits Service: `app/services/plan_limits.rb`
- Webhook Handler: `app/controllers/webhooks/stripe_controller.rb`
- Usage Enforcement: `app/controllers/concerns/usage_trackable.rb`
- Stripe Config: `config/initializers/stripe.rb`
- Dev Startup Script: `bin/dev` (auto-captures webhook secret)

### Environment Variables (.env.local)
```bash
# Stripe Sandbox/Test Keys
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...  # Auto-populated by bin/dev
STRIPE_STARTUP_PRICE_ID=price_1SStMeDkapT94HR1vGXLi0kx
STRIPE_PRO_PRICE_ID=price_1SStQYDkapT94HR1fFNyOa9a
```

### Test Commands
```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/services/plan_limits_test.rb

# Run specific test
bin/rails test test/services/plan_limits_test.rb:31

# Start dev server with Stripe webhooks
bin/dev

# Trigger test webhook event
stripe trigger payment_intent.succeeded
```

### Helpful Stripe CLI Commands
```bash
# View webhook events
stripe events list --limit 10

# View specific event
stripe events retrieve evt_xxx

# Test webhook forwarding
stripe listen --forward-to localhost:3000/webhooks/stripe

# Get webhook signing secret
stripe listen --print-secret
```

## Session End Checklist
- [x] Pricing updated to ¥150/$1.50 and ¥1500/$15
- [x] Commerce disclosure page ready
- [x] PlanLimits tests passing (25/25)
- [x] Flash partial created for limit warnings
- [x] Translations updated for all 7 languages
- [x] Test failures reduced from 36 to 29
- [ ] Final dev testing of Stripe integration
- [ ] Production Stripe setup
- [ ] Remaining test failures addressed
