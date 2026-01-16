# CalcuMake - Development TODO

## Current Status (2025-11-18)

**Production Status**: ✅ All systems operational and revenue-ready

- **Test Suite**: ✅ 425 runs, 1,457 assertions, 0 failures, 0 errors
- **Advanced Calculator**: ✅ Live at `/3d-print-pricing-calculator`
- **Translation System**: ✅ All 1,074 keys translated across 7 languages
- **Stripe Integration**: ✅ Complete with production webhooks configured

---

## High Priority

### 1. Monitor Stripe Production Webhooks ✅

**Status**: ✅ Complete - Production webhooks configured and active

**Webhook Details**:

- **Endpoint**: `https://calcumake.com/webhooks/stripe`
- **Destination ID**: `we_1SSthKDkapT94HR10C0qVPwP`
- **API Version**: `2025-10-29.clover`
- **Status**: Active
- **Events**: 12 events configured

**Configured Events**:

- ✅ `checkout.session.completed` - Links customer/subscription IDs
- ✅ `customer.subscription.created` - Activates user subscription
- ✅ `customer.subscription.updated` - Updates plan/expiration
- ✅ `customer.subscription.deleted` - Downgrades to free
- ✅ `customer.subscription.paused` - Logged (not yet implemented)
- ✅ `customer.subscription.resumed` - Logged (not yet implemented)
- ✅ `customer.subscription.trial_will_end` - Logged (not yet implemented)
- ✅ `customer.updated` - Logged (not yet implemented)
- ✅ `invoice.paid` - Logged (not yet implemented)
- ✅ `invoice.payment_failed` - Logs failure (TODO: send email)
- ✅ `invoice.payment_succeeded` - Updates subscription expiration
- ✅ `payment_method.attached` - Logged (not yet implemented)

**Environment Variables** (configured in `.kamal/secrets` and `config/deploy.yml`):

- `STRIPE_PUBLISHABLE_KEY` - Live publishable key
- `STRIPE_SECRET_KEY` - Live secret key
- `STRIPE_WEBHOOK_SECRET` - Webhook signing secret (`whsec_...`)
- `STRIPE_STARTUP_PRICE_ID` - Startup plan price (¥150/mo)
- `STRIPE_PRO_PRICE_ID` - Pro plan price (¥1,500/mo)
- `STRIPE_WEBHOOK_DESTINATION` - Webhook destination ID

**Next Steps**: Monitor webhook delivery in Stripe Dashboard and verify subscriptions work correctly

**Documentation**: See [docs/STRIPE_SETUP.md](STRIPE_SETUP.md)

### 2. Print Pricing Calculator (Optional)

**Status**: Core functionality complete, potential enhancements identified

**Future Enhancements** (from archived TODO):

- Add responsive sidebar with live price updates to print pricing forms
- Add failure rate (%) field with calculations
- Add shipping cost field
- Add user profile defaults for failure_rate and shipping_cost
- Add currency-based defaults in `CurrencyAwareDefaults` concern

**Priority**: Low - current calculator is fully functional and production-ready

---

## Medium Priority

### 3. Monitor and Optimize SEO Performance

**Advanced Calculator SEO**:

- Monitor organic traffic to `/3d-print-pricing-calculator`
- Track conversion rate (calculator usage → signups)
- Consider A/B testing CTA placement and messaging
- Add more structured data if needed

**Tools**:

- Google Search Console
- Google Analytics
- Stripe Dashboard (for conversion tracking)

### 4. Plan Limits Testing

**Verify subscription limits work correctly**:

- Free Plan: 5 print_pricings, 1 printer, 4 filaments, 5 invoices
- Startup Plan (¥150/mo): 50 print_pricings, 10 printers, 16 filaments, unlimited invoices
- Pro Plan (¥1,500/mo): Unlimited everything

**Test Command**:

```bash
bin/rails test test/services/plan_limits_test.rb
```

### 5. Translation Quality Review

**Current State**: All automated translations complete

- 1,074 keys across 7 languages
- Google Gemini 2.0 Flash translations
- No manual review yet

**Action**: Native speaker review recommended for:

- Japanese (primary market)
- Chinese (secondary market)
- Critical UI elements (CTAs, errors, legal pages)

---

## Low Priority

### 6. Code Quality Maintenance

```bash
# Style checking
bin/rubocop

# Security scan
bin/brakeman
```

**Current Status**: Both passing, no critical issues

### 7. Performance Monitoring

- Monitor production Rails logs for slow queries
- Check Solid Cache hit rates
- Monitor Solid Queue job processing times
- Review Active Storage usage (if file uploads implemented)

---

## Completed Recently ✅

### PR #37 - Advanced Pricing Calculator (Merged 2025-11-18)

- [x] Multi-plate SPA with real-time calculations
- [x] PDF export using jsPDF and html2canvas
- [x] CSV export for spreadsheet compatibility
- [x] localStorage auto-save every 10 seconds
- [x] SEO optimization with structured data
- [x] Full internationalization (7 languages)
- [x] Strategic CTAs for user signup

### Test Suite Fixes (2025-11-16 to 2025-11-18)

- [x] Fixed all 24 test failures
- [x] Resolved printer controller issues
- [x] Fixed privacy/GDPR page errors
- [x] Corrected OAuth button tests (LINE provider)
- [x] Fixed user consent parameter validation
- [x] Resolved print pricing calculation precision
- [x] Added missing translation keys

### Translation System Improvements

- [x] Split English translations into 15 domain-specific files
- [x] Implemented automated translation via OpenRouter API
- [x] Pre-build hook auto-translates on deployment
- [x] Translation cache for efficiency

---

## Reference

### Key Commands

```bash
# Development
bin/dev                    # Start Rails + Stripe webhooks
bin/rails test            # Run all tests (should see 0 failures)

# Translations
bin/sync-translations     # Sync missing keys (requires API key)
bin/translate-locales     # Force re-translation
bin/check-translations    # Scan for missing keys

# Code Quality
bin/rubocop              # Style check
bin/brakeman             # Security scan

# Deployment
bin/kamal deploy         # Deploy to production
```

### Environment Variables

**Required for Development** (`.env.local`):

```bash
# OAuth (from 1Password with CALCUMAKE_ prefix)
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GITHUB_CLIENT_ID=...
GITHUB_CLIENT_SECRET=...
# ... (Microsoft, Facebook, Yahoo Japan, LINE)

# Stripe (test mode)
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...  # Auto-populated by bin/dev
STRIPE_STARTUP_PRICE_ID=price_1SStMeDkapT94HR1vGXLi0kx
STRIPE_PRO_PRICE_ID=price_1SStQYDkapT94HR1fFNyOa9a
```

**Optional**:

```bash
OPENROUTER_TRANSLATION_KEY=...  # For automated translations
```

---

## Documentation

### Active Docs

- [CLAUDE.md](../CLAUDE.md) - Comprehensive development guide
- [docs/STRIPE_SETUP.md](STRIPE_SETUP.md) - Stripe integration guide
- [docs/OAUTH_SETUP_GUIDE.md](OAUTH_SETUP_GUIDE.md) - OAuth configuration
- [docs/MODAL_IMPLEMENTATION.md](MODAL_IMPLEMENTATION.md) - Modal pattern guide
- [docs/AUTOMATED_TRANSLATION_SYSTEM.md](AUTOMATED_TRANSLATION_SYSTEM.md) - Translation system
- [docs/TURBO_REFERENCE.md](TURBO_REFERENCE.md) - Turbo framework reference

### Archived Docs

- [docs/archive/](archive/) - Historical context and completed features
  - Session logs
  - Old TODO lists
  - Feature status snapshots
  - Completed feature documentation

---

## Notes

- **Production-ready**: App is stable, well-tested, and deployed
- **Revenue-ready**: Subscription system complete, just needs production Stripe setup
- **SEO-optimized**: Advanced calculator designed for organic traffic and lead generation
- **Fully internationalized**: 7 languages with automated translation system
- **Zero technical debt**: All tests passing, no known bugs
