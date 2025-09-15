# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Application Overview

This is a Rails 8.0 3D printing cost calculator application that helps users calculate pricing for 3D print jobs. The app includes user authentication via Devise and supports multi-currency calculations with configurable energy costs.

## Development Commands

### Setup and Development
- `bin/setup` - Complete project setup (installs dependencies, prepares database, starts server)
- `bin/dev` - Start development server
- `bin/rails server` - Start Rails server manually
- `bin/rails console` - Rails console
- `bin/rails db:migrate` - Run database migrations
- `bin/rails db:prepare` - Prepare database (create/migrate/seed as needed)

### Testing and Quality
- `bin/rails test` - Run all tests
- `bin/rails test test/models/user_test.rb` - Run specific test file
- `bin/brakeman` - Security vulnerability scanning
- `bin/rubocop` - Ruby code style checking (Omakase Rails style)

## Core Architecture

### Models and Relationships
- **User**: Authenticated users with default currency and energy cost settings
- **Printer**: User-owned 3D printers with power consumption, cost, and payoff tracking
- **PrintPricing**: Individual print job calculations with comprehensive cost breakdown

```
User (1) -> (many) Printers
User (1) -> (many) PrintPricings
```

### Key Pricing Calculation Components
The `PrintPricing` model handles complex cost calculations including:
- Filament costs (based on weight, spool price, markup)
- Electricity costs (power consumption × time × energy rate)
- Labor costs (prep and post-processing time)
- Machine upkeep costs (depreciation and repair factors)
- VAT and final pricing calculations

### Currency Support
Multi-currency support via `CurrencyHelper`:
- Supports USD, EUR, GBP, JPY, CAD, AUD
- Different decimal precision per currency (e.g., JPY has 0 decimals)
- Format and validation utilities

### Printer Management
- 23 predefined manufacturers (Prusa, Bambu Lab, Creality, etc.)
- Payoff tracking with `paid_off?` and `months_to_payoff` methods
- Automatic date tracking for purchase date

## Frontend Technology Stack
- **Stimulus** (Hotwire) for JavaScript interactions
- **Turbo** for SPA-like navigation
- **Import Maps** for JavaScript module management
- **Propshaft** for asset pipeline

## Database
- **PostgreSQL** as primary database
- User profile settings stored in users table
- Comprehensive pricing data with decimal precision for financial calculations

## Authentication & Authorization
- **Devise** handles user authentication
- All main features require authenticated users
- User-specific data isolation (users can only access their own printers/pricings)

## Deployment
- **Kamal** deployment configuration available
- **Docker** containerization support
- **Thruster** for production HTTP acceleration

### Kamal Hooks
Kamal automatically executes hooks during deployment stages. To customize deployment behavior:
- Create bash scripts in `.kamal/hooks/` directory (no file extensions)
- Hook files are named after deployment stages: `pre-build`, `post-build`, `pre-deploy`, `post-deploy`
- **Important**: Do NOT add `hooks:` section to `config/deploy.yml` - Kamal automatically finds and executes hook files
- Example: `.kamal/hooks/pre-build` runs before Docker image build

## Testing
Uses Rails default testing framework (Minitest) with:
- Model tests for business logic validation
- Controller tests for request handling
- System tests with Capybara and Selenium for integration testing