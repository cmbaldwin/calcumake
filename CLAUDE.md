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

## Core Architecture

### Models
- **User**: Currency/energy defaults, company info, logo, confirmable, omniauthable
- **Client**: Customer management (searchable via Ransack)
- **Printer**: Power consumption, payoff tracking
- **PrintPricing**: Job calculations (1-10 plates), linked to clients
- **Plate**: Individual build plates with time/material specs
- **Invoice**: Auto-numbered, status tracking, client integration
- **InvoiceLineItem**: Categorized cost breakdowns

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

**CRITICAL**: Only maintain `en.yml` and `devise.en.yml` - all other locales are auto-translated.

### Automated Translation System

**Development Workflow** (Local):
1. Add new keys to `config/locales/en.yml` or `config/locales/devise.en.yml`
2. Run `bin/sync-translations` (uses English placeholders without API key)
3. Test with `bin/rails test` to ensure nothing broke

**Production Workflow** (Deployment):
1. Add new keys to English master files
2. Commit and push changes
3. Pre-build hook automatically translates all missing keys via OpenRouter API
4. Translations committed automatically before deployment

**Translation Scripts**:

`bin/sync-translations` - Intelligent wrapper script:
- **With API key**: Calls `bin/translate-locales` for automated translation
- **Without API key**: Falls back to English placeholder sync
- Compares `en.yml` + `devise.en.yml` against all target locales
- Auto-detects missing keys across all 6 languages

`bin/translate-locales` - OpenRouter API integration:
- **Model**: Google Gemini Flash 1.5 (8B) - extremely fast and cost-effective (~$0.00001875/1M tokens)
- **Batch processing**: 50 keys per request for optimal performance
- **Smart caching**: Stores translations in `tmp/translation_cache/` to avoid re-translating
- **Validation**: Ensures interpolation variables (%{name}, etc.) are preserved
- **Resume capability**: Can restart from cache if interrupted
- **Cost**: ~$0.10 for full translation of all 1265+ keys across 6 languages

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
- **Plans**: Free (trial), Startup ($0.99/mo), Pro ($9.99/mo)
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
- `app/views/shared/_modal.html.erb` - Reusable modal component
- `app/helpers/print_pricings_helper.rb` - View formatting
- `app/assets/stylesheets/application.css` - Moab theme styling
- `config/locales/en.yml` - English master locale (only file to manually maintain)
- `config/locales/devise.en.yml` - English Devise translations (only file to manually maintain)
- `config/locales/*.yml` - Auto-translated locale files (ja, es, fr, ar, hi, zh-CN)
- `bin/sync-translations` - Translation wrapper (auto-detects API key)
- `bin/translate-locales` - Automated translation via OpenRouter API
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