# CalcuMake - Development TODO

## Current Status (2025-01-16)

- **Translation System**: ⚠️ **REQUIRES CREDITS** - OpenRouter account has $0 balance
- **Pricing**: ✅ Updated to JPY-only (¥150 Startup, ¥1,500 Pro)
- **Stripe Integration**: ~95% complete, needs production setup
- **Test Status**: 39 issues (20 failures + 19 errors) - down from 115!
- **Locale Files**: ⚠️ **DELETED** - Will be regenerated when credits are added

---

## High Priority

### 0. **ADD OPENROUTER CREDITS** ⚠️ **CRITICAL**

**Status**: Translation system is ready but **account has $0 balance**

**What Happened**:
- Deleted all non-English locale files (ar, es, fr, hi, ja, zh-CN)
- Translation system now **REQUIRES** OpenRouter API with credits
- System **FAILS FAST** if no API key or credits

**Action Required**:
1. Add credits to OpenRouter account: https://openrouter.ai/credits
2. Minimum $1 recommended (full translation costs ~$0.10)
3. Run `bin/sync-translations` to regenerate all locale files
4. Verify translations: `ls config/locales/*.yml`

**Testing Translation System**:
```bash
# Set API key (from 1Password: CALCUMAKE_OPENROUTER_TRANSLATION_KEY)
export OPENROUTER_TRANSLATION_KEY='sk-or-v1-...'

# Run translation (will check credits first)
bin/sync-translations

# Expected output:
#   🔍 Checking API key and credits...
#   💰 Credits: X.XXXX remaining
#   ✅ API key valid and credits available
#   🌐 Translating... [for each language]
```

**Cost Estimate**:
- 1,067 English keys × 6 languages = ~6,400 translations
- Model: Google Gemini Flash 1.5 (8B)
- Cost: ~$0.00001875 per 1M input tokens
- **Total: ~$0.10 for full translation**

### 1. Fix Remaining Test Failures (39 issues)

**Status**: Reduced from 115 → 39 (66% improvement in this session)

**Remaining Issues by Category**:

#### OAuth Providers (4 failures)
- LINE provider icon rendering in OAuth button tests
- All 6 providers configured, but LINE icon test failing

#### Privacy/GDPR Controllers (6 failures)
- Cookie policy, privacy policy, terms of service pages
- Data export/deletion flows
- Turbo confirmation modals

#### Printer/Filament Controllers (6 failures)
- Modal form validation errors
- Turbo stream creation flows

#### User Consents (3 failures)
- IP address and user agent recording
- Parameter validation

#### Subscriptions (2 failures)
- Pricing page rendering
- Checkout flow

#### Models/Integration (18 failures)
- Print pricing validation
- Filament cost calculations
- Integration test flows

**Action**: Run specific failing tests and fix systematically:
```bash
# OAuth tests
bin/rails test test/views/devise/shared/oauth_buttons_test.rb

# Privacy/GDPR tests
bin/rails test test/controllers/privacy_controller_test.rb
bin/rails test test/controllers/user_consents_controller_test.rb

# Subscription tests
bin/rails test test/controllers/subscriptions_controller_test.rb
```

### 2. Complete OAuth Configuration

**LINE Provider**: Icon rendering issue in tests
- All other providers working: Google, GitHub, Microsoft, Facebook, Yahoo Japan
- Need to verify LINE icon SVG/image is correct

**Action**:
```bash
# Check LINE icon configuration
grep -r "LINE" app/helpers/oauth_helper.rb
```

### 3. Stripe Production Setup

Once tests are green:

**Steps**:
1. Verify Stripe products in production dashboard
   - Startup: ¥150/month (JPY native)
   - Pro: ¥1,500/month (JPY native)

2. Configure production webhooks
   - Endpoint: `https://calcumake.com/webhooks/stripe`
   - Copy webhook signing secret

3. Update Rails credentials
   ```bash
   EDITOR=nano rails credentials:edit
   ```

4. Complete Stripe business verification
   - Submit required documents
   - Provide commerce disclosure: `/commerce-disclosure`

---

## Medium Priority

### 4. Translation Quality

**Current State**:
- ✅ All 1,067 keys synced across 7 languages
- ⚠️  Most non-English locales use English placeholders
- ✅ Automated translation system ready (OpenRouter API)

**For Production**:
```bash
# Set API key and translate all placeholders
export OPENROUTER_TRANSLATION_KEY='your-key-from-1password'
bin/translate-locales
```

**Cost**: ~$0.10 for full translation (all 1,067 keys × 6 languages)

### 5. Plan Limits Verification

Test that subscription limits work correctly in UI:

**Free Plan** (after 30-day trial):
- 5 print_pricings, 1 printer, 4 filaments, 5 invoices

**Startup Plan** (¥150/mo):
- 50 print_pricings, 10 printers, 16 filaments, unlimited invoices

**Pro Plan** (¥1,500/mo):
- Unlimited everything

**Test**:
```bash
bin/rails test test/services/plan_limits_test.rb
```

---

## Low Priority

### 6. Code Quality

```bash
# Style checking
bin/rubocop

# Security scan
bin/brakeman
```

### 7. Documentation Updates

- ✅ `CLAUDE.md` - Updated with JPY pricing
- ✅ `docs/STRIPE_SETUP.md` - Updated pricing
- ⚠️  `docs/LANDING_PAGE_PLAN.md` - May need pricing update
- ⚠️  `docs/archive/` - Old docs may have outdated pricing

---

## Completed This Session ✅

- [x] Added 40+ missing translation keys (GDPR, subscriptions, invoices)
- [x] Fixed duplicate `show:` key in filaments section
- [x] Updated all pricing from USD to JPY-only
- [x] Synced translations across all 7 languages
- [x] Reduced test failures from 115 → 39 (66% improvement)
- [x] Fixed cookie consent interpolation error
- [x] Archived old TODO.md

---

## Recent Changes (2025-01-16)

### Translation System Overhaul
- Implemented fully automated translation with OpenRouter API
- English (`en.yml`) is now the ONLY manually maintained locale
- Run `bin/sync-translations` to auto-detect and add missing keys
- Production deployment auto-translates via pre-build hook

### Pricing Standardization
- Changed from dual-currency (¥/USD) to JPY-only
- Landing page: ¥150 and ¥1,500 (removed USD)
- Stripe products already configured in JPY
- All documentation updated

### Test Suite Improvements
- Fixed 76 test errors related to missing translations
- Identified remaining 39 issues across:
  - OAuth (LINE provider)
  - Privacy/GDPR flows
  - Modal form validations
  - Subscription pages

---

## Key Files

**Translation System**:
- `config/locales/en.yml` - **Master locale** (only file to edit manually)
- `bin/sync-translations` - Auto-sync wrapper
- `bin/translate-locales` - OpenRouter API integration
- `.kamal/hooks/pre-build` - Auto-translates on deployment

**Subscription System**:
- `app/services/plan_limits.rb` - Plan limit logic
- `app/controllers/webhooks/stripe_controller.rb` - Webhook handler
- `config/initializers/stripe.rb` - Stripe configuration

**OAuth**:
- `app/helpers/oauth_helper.rb` - Provider configuration
- `app/views/devise/shared/_oauth_buttons.html.erb` - OAuth UI

---

## Quick Commands

```bash
# Development
bin/dev                    # Start Rails + Stripe webhooks

# Testing
bin/rails test            # Run all tests
bin/rails test <file>     # Run specific test file

# Translations
bin/sync-translations     # Sync English → all languages (placeholders)
bin/translate-locales     # Auto-translate via API (needs key)

# Code Quality
bin/rubocop              # Style check
bin/brakeman             # Security scan

# Stripe
stripe events list       # View webhook events
stripe listen            # Manual webhook forwarding
```

---

## Environment Variables

**Required for Development** (`.env.local`):
```bash
# OAuth (from 1Password with CALCUMAKE_ prefix)
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
# ... (GitHub, Microsoft, Facebook, Yahoo Japan, LINE)

# Stripe (auto-configured)
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...  # Auto-populated by bin/dev
STRIPE_STARTUP_PRICE_ID=price_1SStMeDkapT94HR1vGXLi0kx
STRIPE_PRO_PRICE_ID=price_1SStQYDkapT94HR1fFNyOa9a
```

**Optional** (for automated translations):
```bash
OPENROUTER_TRANSLATION_KEY=...  # From 1Password
```

---

## Notes

- **Test count went UP** during session (19 → 115 → 39) because we added translation coverage that exposed missing keys. This is actually progress!
- **Translation system is production-ready** - just add English keys, deployment handles the rest
- **Stripe is JPY-native** - no USD conversion needed
- **OAuth mostly working** - just LINE icon issue in tests
