# CalcuMake

**Professional 3D print management platform** - Full-stack Rails 8.1 application for cost calculation, invoicing, and job tracking with multi-plate support and RESTful API.

[![Rails 8.1](https://img.shields.io/badge/Rails-8.1.1-red.svg)](https://rubyonrails.org/)
[![Test Status](https://img.shields.io/badge/tests-1496%20passing-brightgreen.svg)](https://github.com/your-repo/calcumake)
[![API](https://img.shields.io/badge/API-v1-blue.svg)](https://calcumake.com/api/v1)

## Features

### 🚀 RESTful API (New!)
- **JSON:API compliant** - standardized responses with versioning (`/api/v1`)
- **Bearer token authentication** - SHA-256 hashed tokens with expiration
- **Full CRUD operations** - printers, filaments, resins, clients, print pricings, invoices
- **User management** - profile, usage stats, GDPR data export
- **Public endpoints** - health check, pricing calculator (no auth)
- **234 comprehensive tests** - robust coverage for all endpoints

**Quick Start:**
```bash
# Create API token via web UI at /api_tokens
curl https://calcumake.com/api/v1/printers \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 🧮 Advanced Pricing Calculator (Public)
- **No signup required** - `/3d-print-pricing-calculator` for lead generation
- **Multi-plate support** - up to 10 plates, 16 filaments per plate
- **Real-time calculations** - instant cost breakdowns (material, labor, electricity, markup)
- **Export tools** - professional PDF reports and CSV spreadsheets
- **Auto-save** - localStorage prevents data loss (10s intervals)
- **SEO optimized** - structured data for search engines

### 📊 Print Job Management
- **Multi-plate calculations** - 1-10 plates per job with individual filament tracking
- **FDM & Resin support** - material technology switching with validation
- **Cost analysis** - material, electricity, labor, machine cost, markup
- **Printer database** - power consumption, payoff tracking, usage hours
- **Material library** - filaments and resins with pricing and specs

### 💼 Invoicing & Clients
- **Professional invoices** - auto-numbered with status tracking (draft/sent/paid/cancelled)
- **Client management** - searchable database with project history
- **Line items** - categorized cost breakdowns with descriptions
- **Multi-currency** - user-default currency with energy rate tracking

### 🌍 Internationalization
- **7 languages**: English, Japanese (日本語), Spanish (Español), French (Français), Arabic (العربية), Hindi (हिन्दी), Simplified Chinese (简体中文)
- **Automated translation** - OpenRouter API + Google Gemini 2.0 Flash (1,074+ keys)
- **Locale detection** - geographic and browser-based suggestions
- **Deployment integration** - pre-build hook auto-translates missing keys

### 🔐 Authentication & Subscriptions
- **OAuth providers** - Google, GitHub, Microsoft, Facebook, Yahoo Japan, LINE
- **Email confirmation** - Resend integration (noreply@calcumake.com)
- **Stripe subscriptions**:
  - **Free** - Trial tier with basic features
  - **Startup** - ¥150/month (10 printers, 50 calculations)
  - **Pro** - ¥1,500/month (unlimited resources)
- **Usage limits** - tier-based restrictions with upgrade prompts

### 🎨 Design System
- **Moab Desert Theme** - custom Bootstrap 5 styling inspired by Utah landscapes
- **Color palette** - Deep red primary (#c8102e), sandstone orange, desert sage
- **Compact UI** - 15-25% smaller typography, 25-40% reduced spacing
- **Glass-morphism** - backdrop-filter effects on cards
- **Mobile-first** - responsive design with PWA support

## Tech Stack

### Backend
- **Rails 8.1.1** - Omakase stack with importmap (no Node.js in production)
- **PostgreSQL** - multi-plate nested attributes, full-text search
- **Devise** - authentication with omniauthable + confirmable modules
- **Stripe** - subscription billing with webhooks
- **Resend** - transactional email delivery

### Frontend
- **Stimulus** - event-driven controllers with outlets pattern
- **Turbo** - SPA navigation with frame isolation
- **Bootstrap 5** - pure CDN implementation (no Sass compilation)
- **Import Maps** - ES modules without bundling
- **PWA** - progressive web app with service worker

### Testing
- **Minitest** - 1,496 tests in ~4.5s (1,075 Rails, 421 API)
- **Jest** - 20 JavaScript tests for Stimulus mixins
- **Capybara** - system tests with Selenium
- **WebMock** - HTTP stubbing for external APIs

### Infrastructure
- **Kamal** - Docker deployment to Hetzner
- **Hetzner S3** - file storage for uploads
- **Cloudflare** - CDN and edge caching
- **SolidCache** - database-backed cache store

## Quick Start

### Installation
```bash
# Clone repository
git clone https://github.com/your-org/calcumake.git
cd calcumake

# Setup (dependencies, DB, seeds)
bin/setup

# Configure OAuth credentials (copy .env.local.example to .env.local)
cp .env.local.example .env.local
# Add OAuth keys to .env.local (see 1Password: CALCUMAKE_*)

# Start development server (Rails + Stripe webhooks)
bin/dev
```

Visit http://localhost:3000

### Development Commands
```bash
# Testing
bin/ci                    # Run all CI checks (security, linting, tests)
bin/rails test            # Rails tests only (~3.5s)
npm test                  # JavaScript tests (~0.3s)
bin/rails test:system     # System tests (slower)

# Code quality
bin/rubocop              # Style checking (auto-fix: -A)
bin/brakeman             # Security scanning

# Translations
bin/sync-translations            # Auto-translate missing keys
bin/translate-locales           # Full translation via API
bin/check-translations          # Find hardcoded strings
bin/merge-locale-yml            # Semantic YAML merge for conflicts

# Sitemap & SEO
bin/rails sitemap:refresh:no_ping   # Regenerate sitemap (auto-runs daily at 4am UTC)

# Database
bin/rails db:migrate          # Run pending migrations
bin/rails db:seed            # Load sample data
```

### Environment Variables
Required for full functionality:

```bash
# OAuth Providers (1Password: CALCUMAKE_*)
CALCUMAKE_GOOGLE_CLIENT_ID
CALCUMAKE_GOOGLE_CLIENT_SECRET
CALCUMAKE_GITHUB_CLIENT_ID
CALCUMAKE_GITHUB_CLIENT_SECRET
# ... (see .env.local.example)

# Stripe
STRIPE_PUBLISHABLE_KEY
STRIPE_SECRET_KEY
STRIPE_WEBHOOK_SECRET
STRIPE_STARTUP_PRICE_ID
STRIPE_PRO_PRICE_ID

# Translation API
OPENROUTER_TRANSLATION_KEY    # Optional, for automated translations

# Email
RESEND_API_KEY
```

## API Documentation

### Authentication
```bash
# Create token via web UI: https://calcumake.com/api_tokens
# Or via API:
curl -X POST https://calcumake.com/api/v1/api_tokens \
  -H "Authorization: Bearer EXISTING_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"api_token": {"name": "My Integration", "expiration": 90}}'
```

### Example Requests
```bash
# List printers
curl https://calcumake.com/api/v1/printers \
  -H "Authorization: Bearer YOUR_TOKEN"

# Create print pricing
curl -X POST https://calcumake.com/api/v1/print_pricings \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "print_pricing": {
      "job_name": "Custom Part",
      "plates_attributes": [{
        "printing_time_hours": 5,
        "printing_time_minutes": 30,
        "material_technology": "fdm",
        "plate_filaments_attributes": [{
          "filament_id": 123,
          "filament_weight": 85.5
        }]
      }]
    }
  }'

# Get user profile
curl https://calcumake.com/api/v1/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Full API docs**: See PR #82 description or test files in `test/controllers/api/v1/`

## Architecture

### Key Patterns

**Multi-Plate System:**
```ruby
# PrintPricing has_many :plates (1-10)
# Plate has_many :plate_filaments (1-16 for FDM)
pricing = user.print_pricings.build(job_name: "Job")
pricing.plates.build(
  printing_time_hours: 2,
  printing_time_minutes: 30,
  material_technology: "fdm",
  plate_filaments_attributes: [
    { filament_id: 1, filament_weight: 50.0 }
  ]
)
pricing.save!
```

**Turbo Frame Pattern:**
```erb
<%# Wrap content, never replace frame directly %>
<%= turbo_frame_tag "stats_cards" do %>
  <div id="stats_cards_content">
    <%= render "component" %>
  </div>
<% end %>

<%# Update content via turbo stream %>
<%= turbo_stream.replace "stats_cards_content" do %>
  <%= render "component" %>
<% end %>
```

**Modal Pattern (Custom Events):**
```erb
<%# Link with modal-link controller %>
<%= link_to new_client_path(format: :turbo_stream),
    data: {
      controller: "modal-link",
      action: "click->modal-link#open",
      turbo_frame: "modal_content"
    } %>
```

**Caching Strategy:**
```ruby
# Fragment cache with auto-invalidation
<% cache [current_user, "stats", @pricings.maximum(:updated_at)] do %>
  <%= render "stats_cards" %>
<% end %>

# Application cache with TTL
Rails.cache.fetch("user_stats_#{user.id}", expires_in: 5.minutes) do
  calculate_expensive_stats
end
```

### Testing Philosophy
- **Unit tests** for models and helpers
- **Integration tests** for controllers (API and web)
- **System tests** for critical user flows only
- **Jest tests** for JavaScript business logic
- **Pre-commit hook** runs full suite before deployment

## Translation Workflow

**CRITICAL**: Only maintain English source files. All other languages are auto-translated.

### Adding New Translations
1. Add keys to `config/locales/en/*.yml` (split by domain)
2. Run `bin/sync-translations` (requires API key)
3. Test with `bin/rails test`
4. Commit English + auto-generated files

### Updating Existing Text
1. Edit English file: `config/locales/en/navigation.yml`
2. **Delete** the same key from ALL non-English files (ja.yml, es.yml, fr.yml, ar.yml, hi.yml, zh-CN.yml)
3. **Do NOT manually re-translate**
4. Pre-build hook auto-translates on deployment

### Merge Conflicts
Use `bin/merge-locale-yml` for semantic YAML merging (see `docs/TRANSLATION_MERGE_WORKFLOW.md`)

## Deployment

### Kamal (Production)
```bash
# Deploy to production
kamal deploy

# Deploy accessories (PostgreSQL, Redis)
kamal accessory deploy all

# View logs
kamal app logs -f

# Rollback
kamal rollback
```

### Pre-Build Hook
Automatically runs before deployment:
1. Syncs translations (missing keys)
2. Runs Rails + Jest tests
3. Auto-commits locale files
4. Blocks deployment on test failure

### Stripe Webhooks
- **Development**: Stripe CLI forwards to `localhost:3000/webhooks/stripe`
- **Production**: Direct webhook at `https://calcumake.com/webhooks/stripe`

## Documentation

### Primary Docs
- **[CLAUDE.md](CLAUDE.md)** - Complete development guide (AI context)
- **[docs/TESTING_GUIDE.md](docs/TESTING_GUIDE.md)** - Testing strategy and patterns
- **[docs/CACHING_STRATEGY.md](docs/CACHING_STRATEGY.md)** - Multi-layer caching implementation
- **[docs/MODAL_IMPLEMENTATION.md](docs/MODAL_IMPLEMENTATION.md)** - Custom event-based modals
- **[docs/AUTOMATED_TRANSLATION_SYSTEM.md](docs/AUTOMATED_TRANSLATION_SYSTEM.md)** - OpenRouter API integration

### Reference Docs
- **[docs/TURBO_REFERENCE.md](docs/TURBO_REFERENCE.md)** - Turbo framework patterns
- **[docs/OAUTH_SETUP_GUIDE.md](docs/OAUTH_SETUP_GUIDE.md)** - OAuth provider configuration
- **[docs/STRIPE_SETUP.md](docs/STRIPE_SETUP.md)** - Stripe integration guide
- **[docs/VIEWCOMPONENT_MIGRATION_ROADMAP.md](docs/VIEWCOMPONENT_MIGRATION_ROADMAP.md)** - ViewComponent strategy

### Archive
- **[docs/archive/](docs/archive/)** - Historical decisions and completed features

## Contributing

### Code Standards
- **Ruby**: Omakase style guide with Rubocop
- **JavaScript**: ESLint with standard config
- **CSS**: Bootstrap 5 utilities + custom CSS variables
- **Testing**: Minitest + Jest with comprehensive coverage
- **Security**: Brakeman scanning, CSP headers, CSRF protection

### Git Workflow
1. Create feature branch from `master`
2. Make changes with descriptive commits
3. Run `bin/ci` before pushing
4. Open PR with description
5. Merge with `gh pr merge <number> --merge` (preserves history)

### PR Merge Strategy
**IMPORTANT**: Use `--merge` to preserve commit history:
```bash
gh pr merge 82 --merge  # NOT --squash
```

This maintains branch references and context for future development.

## Performance

### Benchmarks
- **Dashboard load**: <200ms (with caching)
- **API response**: <100ms average
- **Test suite**: 1,496 tests in ~4.5s
- **Translation**: 1,074 keys across 6 languages in ~30s

### Optimization
- **SolidCache** - database-backed cache store
- **Cloudflare CDN** - edge caching for static assets
- **Fragment caching** - expensive view components
- **Counter caches** - eliminate COUNT(*) queries
- **Eager loading** - prevent N+1 queries

## License

This project is open source. [Please choose a license to insert here].

---

**Live Site**: https://calcumake.com
**Support**: support@calcumake.com
**Status**: Production-ready
