source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
# ⚠️  IMPORTANT: When updating to Rails 8.1.2+, remove the minitest pin below! ⚠️
# Rails 8.1.2 will include minitest 6.0 compatibility (PR #56207 merged Dec 19, 2025)
gem "rails", "~> 8.1.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Authentication
gem "devise"

# Email service
gem "resend"

# OAuth providers
gem "omniauth"
gem "omniauth-google-oauth2"
gem "omniauth-github"
gem "omniauth-microsoft_graph"
gem "omniauth-facebook"
gem "omniauth-yahoojp"
gem "omniauth-line"
gem "omniauth-rails_csrf_protection"

# Payment processing
gem "stripe"

# Translation API
gem "open_router"

# Admin interface
gem "rails_admin"

# SEO and sitemap
gem "sitemap_generator"
gem "cgi", "~> 0.4.1"  # Required for sitemap_generator in Ruby 4.0+

# Search functionality
gem "ransack"

# View components
gem "view_component"

# Rich text editor (Lexxy)
gem "lexxy", "~> 0.7.4.beta"

# Translations for models (better than built-in i18n for rich text)
gem "mobility", "~> 1.2"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# AWS SDK for S3 Active Storage
gem "aws-sdk-s3", require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Load environment variables from .env files
  gem "dotenv-rails"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"

  # Stub HTTP requests for testing external APIs like Stripe
  gem "webmock"

  # Controller testing helpers for assigns and assert_template
  gem "rails-controller-testing"

  # Ruby test coverage reports and minimum coverage gates in CI
  gem "simplecov", require: false

  # ⚠️⚠️⚠️ REMOVE THIS PIN WHEN UPDATING TO RAILS 8.1.2+ ⚠️⚠️⚠️
  # Pin minitest to 5.x until Rails 8.1.2 is released
  # Minitest 6.0.0 changed the run() method signature, breaking Rails 8.1.0-8.1.1
  # Fix merged to rails/rails 8-1-stable on Dec 19, 2025 (PR #56207)
  # When Rails 8.1.2 is released, remove this line to use minitest 6.x
  # See: https://github.com/rails/rails/pull/56207
  gem "minitest", "~> 5.0"
end
