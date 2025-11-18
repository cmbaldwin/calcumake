# CalcuMake

**Professional 3D print project management** - Rails 8.1 application for calculating costs, managing invoices, and tracking print jobs with multi-plate support.

## Core Features

### Advanced Pricing Calculator (Public)
- **No signup required** - `/3d-print-pricing-calculator` lead generation tool
- **Multi-plate support** - up to 10 plates with 16 filaments each
- **Real-time calculations** - instant cost breakdowns with detailed components
- **Export tools** - professional PDF generation and CSV spreadsheet export
- **Auto-save** - localStorage persistence prevents data loss
- **SEO optimized** - structured data and meta tags for organic traffic

### Print Job Management (App)
- **Multi-plate calculations** (1-10 plates per job) with individual filament tracking
- **Real-time cost analysis** - material, electricity, labor, markup calculations
- **Printer tracking** - power consumption, payoff analysis, printer-specific settings
- **Filament library** - comprehensive material database with specs and pricing

### Invoicing & Clients
- **Professional invoices** - auto-numbered, status tracking, client integration
- **Client management** - searchable database with project history
- **Multi-currency support** - default currency per user with energy rate tracking

### Internationalization
- **7 languages supported**: English, Japanese, Spanish, French, Arabic, Hindi, Simplified Chinese
- **Automated translation** - OpenRouter API with Google Gemini 2.0 Flash
- **Locale detection** - geographic and browser-based suggestions
- **1,074+ translation keys** - fully localized UI across all languages

### Authentication & Subscriptions
- **OAuth login** - Google, GitHub, Microsoft, Facebook, Yahoo Japan, LINE
- **Email confirmation** - via Resend (noreply@calcumake.com)
- **Stripe subscriptions** - Free, Startup (¥150/mo), Pro (¥1,500/mo) tiers
- **Usage limits** - tier-based restrictions on calculations and printers

## Tech Stack

- **Rails 8.1.1** - Omakase with importmap (no Node.js/npm required)
- **PostgreSQL** - multi-plate data with nested attributes
- **Bootstrap 5** - pure CDN implementation with custom Moab Desert theme
- **Stimulus** - event-driven controllers with outlets pattern
- **Turbo** - SPA-like navigation with frame isolation
- **PWA** - progressive web app with service worker

## Quick Start

```bash
# Setup (installs dependencies, creates DB, loads fixtures)
bin/setup

# Development server (Rails + foreman)
bin/dev

# Run tests
bin/rails test

# Code quality
bin/rubocop         # Style checking
bin/brakeman        # Security scan
```

## Translation System

```bash
# Sync translations (auto-translates missing keys)
bin/sync-translations

# Force re-translation (requires OpenRouter API key)
bin/translate-locales

# Check for missing translations
bin/check-translations
```

**Environment**: Set `OPENROUTER_TRANSLATION_KEY` for automated translations. Keys stored in 1Password (`CALCUMAKE_OPENROUTER_TRANSLATION_KEY`).

## Development Notes

- **No manual translation editing** - only maintain `config/locales/en/*.yml` files
- **Multi-plate pattern** - use `build` → `save!` with nested attributes
- **Turbo frame isolation** - wrap content divs, never replace frames directly
- **Modal pattern** - custom event-based system for on-the-fly record creation
- **OAuth credentials** - `.env.local` required (see `.env.local.example`)
- **All tests passing** - 425 runs, 1,457 assertions, 0 failures, 0 errors

## Deployment

- **Kamal** - Docker-based deployment to Hetzner
- **Pre-build hook** - auto-translates, runs tests, commits locale files
- **Hetzner S3** - file storage for user uploads and assets
- **Stripe webhook** - forwarding via CLI in development, direct in production

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - comprehensive development guide
- **[docs/](docs/)** - feature-specific documentation
- **[docs/archive/](docs/archive/)** - historical context and completed features

## Copyright

© 2025 株式会社モアブ (MOAB Co., Ltd.)
