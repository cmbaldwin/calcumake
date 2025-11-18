# CLAUDE.md

## Application Overview
**CalcuMake** - Rails 8.1.1 3D print project management with invoicing, cost tracking, and pricing calculations. Multi-currency support, Devise authentication with OAuth and email confirmation.

**Copyright**: © 2025 株式会社モアブ (MOAB Co., Ltd.)

## Development Commands
- `bin/setup` - Complete setup
- `bin/dev` - Development server
- `bin/rails test` - Run tests
- `bin/rubocop` - Style checking
- `bin/brakeman` - Security scan
- `bin/sync-translations` - Sync and auto-translate missing keys (uses OpenRouter API if key available)
- `bin/translate-locales` - Direct automated translation via OpenRouter API (requires OPENROUTER_TRANSLATION_KEY)
- `bin/force-retranslate` - Clear cache for English placeholder values to force re-translation
- `bin/check-translations` - Scan code for missing translation keys and hardcoded strings

## Core Architecture

### Models
- **User**: Currency/energy defaults, company info, logo, confirmable, omniauthable
- **Client**: Customer management (searchable via Ransack)
- **Printer**: Power consumption, payoff tracking
- **PrintPricing**: Job calculations (1-10 plates), linked to clients
- **Plate**: Individual build plates with time/material specs
- **Invoice**: Auto-numbered, status tracking, client integration
- **InvoiceLineItem**: Categorized cost breakdowns

### Public Features
- **Advanced Pricing Calculator** (`/3d-print-pricing-calculator`) - No-signup SPA for lead generation
  - Multi-plate calculations (up to 10 plates)
  - Multiple filaments per plate (up to 16)
  - Real-time cost breakdowns (filament, electricity, labor, machine, other)
  - PDF export with professional formatting (jsPDF + html2canvas)
  - CSV export for spreadsheet compatibility
  - Auto-save to localStorage every 10 seconds
  - Strategic CTAs to drive account creation

### Multi-Plate System
Each PrintPricing contains 1-10 plates. Use `build` → `save!` pattern:

```ruby
pricing = user.print_pricings.build(job_name: "Job", printer: printer)
pricing.plates.build(printing_time_hours: 2, filament_weight: 50.0, ...)
pricing.save!
```

**Never access** old attributes like `pricing.printing_time_hours` (removed). Use `pricing.plates.sum(&:filament_weight)`.

### Key Patterns
- Nested attributes: `plates_attributes`, `plate_filaments_attributes`
- Dynamic forms via Stimulus outlets: `nested_form_controller` → `dynamic_list_controller`
- Filament management: `filament_list_controller` → `dynamic_list_controller`
- Calculations sum across all plates
- Always build at least one plate with at least one filament for tests

## Frontend Stack
- **Stimulus** for interactions
- **Turbo** for SPA-like behavior
- **Bootstrap 5** pure implementation
- **Import Maps** for JS modules

### Critical Turbo Frame Pattern
Never replace frames directly - wrap content:

```erb
<%= turbo_frame_tag "stats_cards" do %>
  <div id="stats_cards_content">
    <%= render "component" %>
  </div>
<% end %>

<!-- Update content, not frame -->
<%= turbo_stream.replace "stats_cards_content" do %>
  <%= render "component" %>
<% end %>
```

### JavaScript Modules
- **Rails 8 importmap-only project** - NO Node.js, npm, or yarn
- Uses CDN imports for external libraries (Bootstrap, jsPDF, html2canvas)
- Stimulus controllers loaded via `pin_all_from` with `preload: false`
- Test JavaScript through browser/Rails server at localhost:3000 with `bin/dev`
- UMD versions for importmap compatibility
- Rails Admin uses separate importmap (`config/importmap.rails_admin.rb`)
- Never pin `rails_admin` in main importmap

### Stimulus Architecture
- Use **outlets** and **events** for controller communication, not inheritance
- Controllers connect in order: `connect()` → `outletConnected()` → initialize functionality
- Wait for outlet connections before accessing outlet targets
- Limits: 10 plates max, 16 filaments per plate, minimum 1 of each

### Modal Pattern (Turbo + Stimulus)
**Custom Event-Based Modal System** for creating records within forms:

**Controllers:**
- `modal_controller.js` - Manages Bootstrap modal lifecycle and loading states
- `modal_link_controller.js` - Dispatches custom `open-modal` event on link click

**Pattern:**
```erb
<!-- Link to open modal -->
<%= link_to new_resource_path(format: :turbo_stream),
    data: {
      controller: "modal-link",
      action: "click->modal-link#open",
      turbo_frame: "modal_content"
    } %>
```

**Key Behaviors:**
1. Modal link dispatches `open-modal` custom event (document-level)
2. Modal controller listens for event and shows loading spinner immediately
3. Turbo frame loads content into `modal_content` frame
4. Success: Turbo stream updates specific dropdown + closes modal
5. Error: Modal stays open showing validation errors

**Turbo Stream Response Pattern:**
```erb
# Update specific dropdown only (not full page reload)
<%= turbo_stream.update "resource_select_frame" do %>
  <%= render_select_with_new_option %>
<% end %>

# Close modal via JavaScript
<%= turbo_stream.append "modal" do %>
  <script>
    bootstrap.Modal.getInstance(document.getElementById('modal'))?.hide()
  </script>
<% end %>
```

**Active Implementations:**
- Clients in invoice forms → updates `client_select_frame`
- Printers in print pricing forms → updates `printer_select_frame`
- Filaments in plate fields → updates all `[data-filament-select-frame]` (multiple instances)

## Internationalization
Supports 7 languages: en, ja, zh-CN, hi, es, fr, ar

**CRITICAL**: Only maintain English source files in `config/locales/en/` and `config/locales/devise.en.yml` - all other locales are auto-translated.

### Translation File Structure

**English Source Files** (manually maintained):
```
config/locales/
├── en/                          # Split by domain for maintainability
│   ├── activerecord.yml         # Model validations & errors
│   ├── navigation.yml           # Nav, actions, flash, common
│   ├── print_pricings.yml       # Print pricing features
│   ├── printers.yml             # Printer management
│   ├── invoices.yml             # Invoice features
│   ├── filaments.yml            # Filament management
│   ├── clients.yml              # Client management
│   ├── profile.yml              # User profile & settings
│   ├── currency.yml             # Currency & energy
│   ├── application.yml          # App-wide strings
│   ├── support.yml              # Support page
│   ├── legal.yml                # Legal pages
│   ├── landing.yml              # Landing page & marketing
│   ├── subscriptions.yml        # Subscription features
│   └── gdpr.yml                 # GDPR & privacy
└── devise.en.yml                # Devise authentication
```

**Auto-Generated Files** (single file per language):
- `ja.yml`, `es.yml`, `fr.yml`, `ar.yml`, `hi.yml`, `zh-CN.yml`

### Automated Translation System

**Development Workflow** (Local):
1. Add new keys to files in `config/locales/en/` or `config/locales/devise.en.yml`
2. Run `bin/sync-translations` (requires API key for automated translation)
3. Test with `bin/rails test` to ensure nothing broke

**Production Workflow** (Deployment):
1. Add new keys to English master files
2. Commit and push changes
3. Pre-build hook automatically translates all missing keys via OpenRouter API
4. Translations committed automatically before deployment

**Translation Scripts**:

`bin/sync-translations` - Intelligent wrapper script:
- **With API key**: Calls `bin/translate-locales` for automated translation
- **Without API key**: Exits with error (we no longer use English placeholders)
- Merges all `en/*.yml` files before translation
- Auto-detects missing keys across all 6 languages

`bin/translate-locales` - OpenRouter API integration via `open_router` gem:
- **Model**: Google Gemini 2.0 Flash (`google/gemini-2.0-flash-001`) - extremely fast and cost-effective
- **Implementation**: Uses official `open_router` Ruby gem (v0.3.3) for clean, maintainable API calls
- **Batch processing**: 50 keys per request for optimal performance
- **Smart caching**: Stores translations in `tmp/translation_cache/` to avoid re-translating
- **Validation**: Ensures interpolation variables (%{name}, etc.) are preserved
- **JSON parsing**: Handles both JSON and plain-text translation responses
- **Resume capability**: Can restart from cache if interrupted
- **Total keys**: 1,074 keys across 6 languages (ja, es, fr, ar, hi, zh-CN)

**Key Features**:
- Preserves interpolation variables (`%{variable}`)
- Maintains HTML tags and ERB syntax
- Validates translation quality before writing
- Context-aware for 3D printing terminology
- Automatic deployment integration via pre-build hook

**Environment Variables**:
- `OPENROUTER_TRANSLATION_KEY` - API key for automated translations (stored in 1Password)
- Set locally for testing: `export OPENROUTER_TRANSLATION_KEY='your-key'`
- Automatically available in deployment via Kamal secrets

**Merging Translation Conflicts**: When merging branches with locale file conflicts, use `bin/merge-locale-yml` for semantic YAML merging (see `docs/TRANSLATION_MERGE_WORKFLOW.md` for full workflow).

## Database
PostgreSQL with plates table storing per-plate data. Always test with fixtures for both `print_pricings.yml` and `plates.yml`.

## Authentication
Devise with confirmable and omniauthable modules. OAuth providers: Google, GitHub, Microsoft, Facebook, Yahoo Japan, LINE. Email confirmation via Resend (noreply@calcumake.com). Rails Admin at `/admin` (requires `admin: true`).

**Local Development**: Requires `dotenv-rails` gem and `.env.local` file (see `.env.local.example`). OAuth credentials stored in 1Password with `CALCUMAKE_` prefix, used in app without prefix.

## PWA (Progressive Web App)
- Built-in Rails 8 PWA with manifest + service worker
- Auto-registration via `pwa_registration_controller.js`
- Routes: `/manifest` and `/service-worker`

## Subscription System (Stripe)
- **Plans**: Free (trial), Startup (¥150/mo), Pro (¥1,500/mo)
- **Implementation**: PR #26 merged - Stripe Checkout with webhooks
- **Status**: ~95% complete, needs API credentials configuration
- **Controllers**: `SubscriptionsController`, `Webhooks::StripeController`
- **Testing**: WebMock stubs for unit tests, Stripe Sandbox for integration
- **Sandbox Mode**: Uses NEW Stripe Sandbox system (not legacy test mode)
- **Credentials needed**: `publishable_key`, `secret_key`, `webhook_secret`, `startup_price_id`, `pro_price_id`
- **Configuration**: See `config/initializers/stripe.rb` for setup
- **Development**: `bin/dev` runs Rails + Stripe webhook forwarding via foreman
- **Webhook Testing**: Stripe CLI forwards to `localhost:3000/webhooks/stripe`
- **Test Cards**: Use `4242 4242 4242 4242` (Visa) or `pm_card_visa` payment method ID

## Deployment
- **Kamal** with Docker
- **Hetzner S3** for file storage
- Hooks in `.kamal/hooks/` (no file extensions)

## Testing
Minitest with Turbo Stream tests. Test both HTML and turbo_stream formats.

## Design Standards
**Moab Desert Theme** - Compact design system inspired by Utah's natural landscapes:
- **Color Palette**: Deep red primary (#c8102e), sandstone orange secondary (#d2691e), desert sage success (#9caf88)
- **Typography**: 15-25% smaller than standard Bootstrap
- **Spacing**: 25-40% reduction from standard
- **Buttons**: Universal `0.6rem 1.2rem` padding, gradient backgrounds
- **Cards**: Glass-morphism effect with backdrop-filter and subtle shadows
- **Forms**: Authentication forms constrained to 28rem max-width, centered on large screens
- **Responsive**: Mobile-first with container adjustments

## Code Standards & Tools
- **Ruby Style**: Omakase Ruby style guide with Rubocop
- **CSS**: Bootstrap 5 CDN + custom CSS variables for theming
- **Testing**: Minitest with parallel workers, system tests via Capybara/Selenium
- **Security**: Brakeman static analysis, CSP headers, CSRF protection
- **SEO**: Comprehensive meta tags, structured data, sitemap generation
- **Performance**: Asset pipeline with Propshaft, CDN imports, PWA caching

## Key Files
- `app/models/user.rb` - User model with Devise confirmable + omniauthable
- `app/models/client.rb` - Client management model
- `app/models/plate.rb` - Individual plate model
- `app/helpers/oauth_helper.rb` - OAuth provider configuration
- `app/helpers/application_helper.rb` - OAuth buttons and icons for views
- `app/views/devise/shared/_oauth_buttons.html.erb` - OAuth login buttons partial
- `app/javascript/controllers/nested_form_controller.js` - Dynamic plate management
- `app/javascript/controllers/modal_controller.js` - Modal lifecycle management
- `app/javascript/controllers/modal_link_controller.js` - Modal open event dispatcher
- `app/javascript/controllers/advanced_calculator_controller.js` - Public pricing calculator SPA
- `app/views/shared/_modal.html.erb` - Reusable modal component
- `app/views/pages/pricing_calculator.html.erb` - Advanced calculator public page
- `app/helpers/print_pricings_helper.rb` - View formatting
- `app/assets/stylesheets/application.css` - Moab theme styling
- `config/locales/en/*.yml` - English master translations split by domain (manually maintained)
- `config/locales/devise.en.yml` - English Devise translations (manually maintained)
- `config/locales/*.yml` - Auto-translated locale files (ja, es, fr, ar, hi, zh-CN) - single combined files
- `bin/split-translations` - Helper to split en.yml into domain files (one-time use)
- `bin/sync-translations` - Translation wrapper (auto-detects API key)
- `bin/translate-locales` - Automated translation via OpenRouter API (merges en/ files before translating)
- `.kamal/hooks/pre-build` - Deployment hook (runs translations + tests + auto-commit)
- `.env.local` - OAuth credentials (gitignored, see `.env.local.example`)

## Documentation Context Reference

### Active Documentation
**OAuth Setup:** `docs/OAUTH_SETUP_GUIDE.md`
**Stripe Integration:** `docs/STRIPE_SETUP.md`
**Landing Page:** `docs/LANDING_PAGE_PLAN.md`
**Turbo Framework:** `docs/TURBO_REFERENCE.md` | `docs/TURBO_CHEATSHEET.md`
**Modal Pattern:** `docs/MODAL_IMPLEMENTATION.md` - Complete guide for custom event-based modal system
**Translation System:** `docs/AUTOMATED_TRANSLATION_SYSTEM.md` - OpenRouter API automated translations
**Translation Workflow:** `docs/TRANSLATION_MERGE_WORKFLOW.md` - Locale file merging and sync procedures

### Historical Context (Archive)
When additional context is needed for historical decisions or completed features:
- **Monetization & Legal:** `docs/archive/2025-11-05-monetization-legal-compliance-report.md` - Complete legal compliance analysis for paid plans, privacy policies, and subscription system
- **Feature Status:** `docs/archive/MONETIZATION_UPDATE_SUMMARY.md`, `docs/archive/TRANSLATION_STATUS.md` - Historical implementation records
- **Future Plans:** `docs/archive/ADSENSE_PREPARATION.md` - Prepared but not implemented features

*Reference documentation only when specific context is required.*
## Recent Updates

### 2025-11-18: Production-Ready & Revenue-Enabled ✅
- **All tests passing**: 425 runs, 1,457 assertions, 0 failures, 0 errors
- **Advanced calculator launched**: `/3d-print-pricing-calculator` - full-featured SPA with PDF/CSV export
- **Multi-plate support**: Up to 10 plates with 16 filaments each, real-time calculations
- **Export functionality**: Professional PDF generation with jsPDF, CSV export for spreadsheets
- **Stripe production webhooks**: Configured and active at `https://calcumake.com/webhooks/stripe`
- **Revenue-ready**: Subscription system fully operational (¥150 Startup, ¥1,500 Pro)
- **SEO optimized**: Strategic route, meta tags, structured data for search engines
- **Fully internationalized**: 7 languages with automated translation system

### 2025-11-16: Translation Files Refactored
- **Split English translations** from single `en.yml` (1,365 lines) into 15 domain-specific files in `config/locales/en/`
- **Updated `bin/translate-locales`** to automatically merge all `en/*.yml` files before translation
- **Benefits**: Easier to edit, less prone to YAML corruption, better organization, easier code reviews

### 2025-01-16: Translation System Refactored to use `open_router` Gem
- Replaced manual HTTP calls with official `open_router` Ruby gem (v0.3.3)
- Switched to **Gemini 2.0 Flash** (`google/gemini-2.0-flash-001`)
- All 1,074 keys successfully translated across 6 languages (ja, es, fr, ar, hi, zh-CN)
- Translation cache in `tmp/translation_cache/` for efficiency
- Fail-fast: exits with error code 1 if translations fail (no silent fallbacks)
