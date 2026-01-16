# CalcuMake API Design Documentation

## Overview

This document outlines the comprehensive REST API for CalcuMake, enabling third-party integrations, mobile apps, and automation workflows for 3D print cost management.

**Stack:** Rails 8.1.1, Importmaps, Turbo/Hotwire, Stimulus, ViewComponents

## Table of Contents

1. [Authentication](#authentication)
2. [Token Security Architecture](#token-security-architecture)
3. [API Versioning](#api-versioning)
4. [Response Format](#response-format)
5. [Error Handling](#error-handling)
6. [Rate Limiting](#rate-limiting)
7. [Caching Strategy](#caching-strategy)
8. [Endpoints](#endpoints)
9. [Token Management UI](#token-management-ui)
10. [Implementation Plan](#implementation-plan)

---

## Authentication

### API Token Authentication

The API uses Bearer token authentication via `Authorization` header.

```bash
curl -H "Authorization: Bearer YOUR_API_TOKEN" \
     https://calcumake.com/api/v1/print_pricings
```

### Token Generation

Users generate API tokens from their profile settings. Each token:
- Is a 32-character secure random string
- Can be revoked at any time
- Has optional expiration date
- Records last used timestamp for security auditing

### Token Scopes (Future Enhancement)

| Scope | Access Level |
|-------|-------------|
| `read` | Read-only access to all resources |
| `write` | Create, update, delete access |
| `invoices` | Invoice-specific operations |
| `admin` | Full administrative access |

---

## Token Security Architecture

### Database Security

**CRITICAL:** Tokens are NEVER stored in plain text.

```ruby
# app/models/api_token.rb
class ApiToken < ApplicationRecord
  belongs_to :user

  # Token is only available in memory immediately after creation
  attr_accessor :plain_token

  # Secure defaults
  EXPIRATION_OPTIONS = {
    '30_days' => 30.days,
    '90_days' => 90.days,
    '1_year' => 1.year,
    'never' => nil
  }.freeze

  DEFAULT_EXPIRATION = '90_days'
  TOKEN_PREFIX = 'cm_'
  TOKEN_LENGTH = 32

  validates :name, presence: true, length: { maximum: 100 }
  validates :token_digest, presence: true, uniqueness: true
  validates :token_hint, presence: true
  validates :expires_at, presence: true, unless: :never_expires?

  before_validation :generate_token, on: :create
  before_validation :set_default_expiration, on: :create

  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def never_expires?
    expires_at.nil?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def revoked?
    revoked_at.present?
  end

  def active?
    !revoked? && !expired?
  end

  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end

  # Class method to authenticate - constant-time comparison
  def self.authenticate(token)
    return nil if token.blank?
    return nil unless token.start_with?(TOKEN_PREFIX)

    # Use secure comparison to prevent timing attacks
    digest = Digest::SHA256.hexdigest(token)
    api_token = find_by(token_digest: digest)

    return nil unless api_token&.active?

    api_token.touch_last_used!
    api_token
  end

  private

  def generate_token
    # Generate cryptographically secure random token
    raw_token = SecureRandom.urlsafe_base64(TOKEN_LENGTH)
    self.plain_token = "#{TOKEN_PREFIX}#{raw_token}"

    # Store only the hash - NEVER the plain token
    self.token_digest = Digest::SHA256.hexdigest(plain_token)

    # Store hint for user identification (first 4 + last 4 chars)
    self.token_hint = "#{plain_token[0..6]}...#{plain_token[-4..]}"
  end

  def set_default_expiration
    return if expires_at.present?

    duration = EXPIRATION_OPTIONS[DEFAULT_EXPIRATION]
    self.expires_at = duration ? duration.from_now : nil
  end
end
```

### Database Migration

```ruby
# db/migrate/[timestamp]_create_api_tokens.rb
class CreateApiTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :api_tokens do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.string :token_digest, null: false
      t.string :token_hint, null: false  # "cm_abc...xyz" for display
      t.datetime :last_used_at
      t.datetime :expires_at
      t.datetime :revoked_at
      t.inet :created_from_ip  # Security audit trail
      t.string :user_agent     # Security audit trail
      t.timestamps
    end

    # Unique index on digest for fast lookups
    add_index :api_tokens, :token_digest, unique: true

    # Index for listing user's tokens
    add_index :api_tokens, [:user_id, :created_at]

    # Index for cleanup of expired tokens
    add_index :api_tokens, :expires_at, where: 'expires_at IS NOT NULL'
  end
end
```

### One-Time Token Reveal

**CRITICAL SECURITY REQUIREMENT:** The full token is ONLY shown once at creation.

```ruby
# After creation, plain_token is available in memory
token = current_user.api_tokens.create!(name: "My Integration")
token.plain_token  # => "cm_abc123def456..." (available NOW only)

# After reload or subsequent fetches, it's gone forever
token.reload
token.plain_token  # => nil (NEVER recoverable)
```

### Browser Security

```javascript
// app/javascript/controllers/api_token_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tokenDisplay", "copyButton", "revealSection"]
  static values = { revealed: Boolean }

  connect() {
    // Token display auto-hides after 60 seconds for security
    if (this.revealedValue) {
      this.startAutoHideTimer()
    }
  }

  startAutoHideTimer() {
    this.timeout = setTimeout(() => {
      this.hideToken()
    }, 60000) // 60 seconds
  }

  hideToken() {
    if (this.hasRevealSectionTarget) {
      this.revealSectionTarget.innerHTML = `
        <div class="alert alert-warning">
          <i class="bi bi-shield-lock me-2"></i>
          Token hidden for security. This token cannot be revealed again.
        </div>
      `
    }
  }

  async copy() {
    const token = this.tokenDisplayTarget.textContent.trim()

    try {
      await navigator.clipboard.writeText(token)
      this.showCopySuccess()
    } catch (err) {
      this.showCopyFallback(token)
    }
  }

  showCopySuccess() {
    const originalText = this.copyButtonTarget.innerHTML
    this.copyButtonTarget.innerHTML = '<i class="bi bi-check"></i> Copied!'
    this.copyButtonTarget.classList.add('btn-success')
    this.copyButtonTarget.classList.remove('btn-outline-primary')

    setTimeout(() => {
      this.copyButtonTarget.innerHTML = originalText
      this.copyButtonTarget.classList.remove('btn-success')
      this.copyButtonTarget.classList.add('btn-outline-primary')
    }, 2000)
  }

  showCopyFallback(token) {
    // Fallback for browsers without clipboard API
    const textArea = document.createElement('textarea')
    textArea.value = token
    textArea.style.position = 'fixed'
    textArea.style.opacity = '0'
    document.body.appendChild(textArea)
    textArea.select()
    document.execCommand('copy')
    document.body.removeChild(textArea)
    this.showCopySuccess()
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }
}
```

### Token Expiration Policies

| Expiration | Use Case | Security Level |
|------------|----------|----------------|
| 30 days | CI/CD pipelines, temporary access | High |
| 90 days | Regular integrations (default) | Medium |
| 1 year | Long-running automations | Lower |
| Never | Legacy systems (discouraged) | Lowest |

**Best Practice:** Encourage 90-day tokens with automatic renewal reminders.

### Security Audit Trail

Every API request logs:
- Token hint (not full token)
- IP address
- User agent
- Endpoint accessed
- Response status
- Timestamp

```ruby
# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ActionController::API
  before_action :authenticate_api_token!
  after_action :log_api_access

  private

  def log_api_access
    return unless @current_api_token

    Rails.logger.info({
      event: 'api_access',
      token_hint: @current_api_token.token_hint,
      user_id: @current_api_token.user_id,
      ip: request.remote_ip,
      path: request.path,
      method: request.method,
      status: response.status,
      timestamp: Time.current.iso8601
    }.to_json)
  end
end
```

---

## API Versioning

### URL-Based Versioning

All API endpoints are prefixed with version number:

```
/api/v1/print_pricings
/api/v1/invoices
```

### Version Lifecycle

- **Current**: v1 (stable)
- **Deprecation Notice**: 6 months before removal
- **Version Support**: Minimum 12 months after deprecation notice

---

## Response Format

### Success Response

```json
{
  "data": {
    "id": 123,
    "type": "print_pricing",
    "attributes": {
      "job_name": "Phone Stand",
      "final_price": "25.50",
      "currency": "USD",
      "created_at": "2025-12-19T10:30:00Z",
      "updated_at": "2025-12-19T10:30:00Z"
    },
    "relationships": {
      "printer": { "data": { "id": 1, "type": "printer" } },
      "client": { "data": { "id": 5, "type": "client" } },
      "plates": { "data": [{ "id": 1, "type": "plate" }] }
    }
  },
  "included": []
}
```

### Collection Response

```json
{
  "data": [...],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 47,
    "per_page": 10
  },
  "links": {
    "self": "/api/v1/print_pricings?page=1",
    "first": "/api/v1/print_pricings?page=1",
    "prev": null,
    "next": "/api/v1/print_pricings?page=2",
    "last": "/api/v1/print_pricings?page=5"
  }
}
```

---

## Error Handling

### Error Response Format

```json
{
  "errors": [
    {
      "status": "422",
      "code": "validation_error",
      "title": "Validation Failed",
      "detail": "Job name can't be blank",
      "source": { "pointer": "/data/attributes/job_name" }
    }
  ]
}
```

### HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 204 | No Content (successful delete) |
| 400 | Bad Request (malformed JSON) |
| 401 | Unauthorized (missing/invalid token) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not Found |
| 422 | Unprocessable Entity (validation errors) |
| 429 | Too Many Requests (rate limited) |
| 500 | Internal Server Error |

---

## Rate Limiting

### Limits by Plan

| Plan | Requests/Hour | Requests/Day |
|------|---------------|--------------|
| Free | 100 | 1,000 |
| Startup | 1,000 | 10,000 |
| Pro | 10,000 | 100,000 |

### Rate Limit Headers

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1703001600
```

---

## Caching Strategy

### API Response Caching

Leverage the existing SolidCache infrastructure for API responses:

```ruby
# app/controllers/api/v1/base_controller.rb
class Api::V1::BaseController < ActionController::API
  include ActionController::Caching

  private

  # Cache individual resource responses
  def cache_resource(resource, &block)
    cache_key = [
      "api/v1",
      resource.class.name.underscore,
      resource.id,
      resource.updated_at.to_i
    ]

    Rails.cache.fetch(cache_key, expires_in: 15.minutes, &block)
  end

  # Cache collection responses with pagination
  def cache_collection(scope, cache_key_base, &block)
    cache_key = [
      "api/v1",
      cache_key_base,
      current_user.id,
      scope.maximum(:updated_at)&.to_i,
      params[:page],
      params[:per_page]
    ]

    Rails.cache.fetch(cache_key, expires_in: 5.minutes, &block)
  end
end
```

### HTTP Caching Headers

```ruby
# Private resources - user-specific data
def show
  @print_pricing = current_user.print_pricings.find(params[:id])

  # ETag for conditional requests
  fresh_when(
    etag: @print_pricing,
    last_modified: @print_pricing.updated_at,
    public: false
  )
end

# Public endpoints - aggressive caching
def calculator
  # Allow CDN and browser caching
  expires_in 1.hour, public: true
  response.headers['Cache-Control'] = 'public, max-age=3600'
end
```

### Cache Invalidation

```ruby
# app/models/print_pricing.rb
class PrintPricing < ApplicationRecord
  after_save :invalidate_api_cache
  after_destroy :invalidate_api_cache

  private

  def invalidate_api_cache
    # Clear collection cache for user
    Rails.cache.delete_matched("api/v1/print_pricing*user/#{user_id}*")

    # Individual resource cache auto-invalidates via updated_at in key
  end
end
```

### Rate Limiter with Caching

```ruby
# app/services/api/rate_limiter.rb
class Api::RateLimiter
  LIMITS = {
    'free' => { hourly: 100, daily: 1_000 },
    'startup' => { hourly: 1_000, daily: 10_000 },
    'pro' => { hourly: 10_000, daily: 100_000 }
  }.freeze

  def initialize(user)
    @user = user
    @plan = user.plan || 'free'
  end

  def allowed?
    within_hourly_limit? && within_daily_limit?
  end

  def remaining_hourly
    limit = LIMITS[@plan][:hourly]
    limit - current_hourly_count
  end

  def remaining_daily
    limit = LIMITS[@plan][:daily]
    limit - current_daily_count
  end

  def increment!
    Rails.cache.increment(hourly_key, 1, expires_in: 1.hour)
    Rails.cache.increment(daily_key, 1, expires_in: 24.hours)
  end

  private

  def within_hourly_limit?
    current_hourly_count < LIMITS[@plan][:hourly]
  end

  def within_daily_limit?
    current_daily_count < LIMITS[@plan][:daily]
  end

  def current_hourly_count
    Rails.cache.read(hourly_key).to_i
  end

  def current_daily_count
    Rails.cache.read(daily_key).to_i
  end

  def hourly_key
    "api_rate/#{@user.id}/hourly/#{Time.current.beginning_of_hour.to_i}"
  end

  def daily_key
    "api_rate/#{@user.id}/daily/#{Date.current.to_s}"
  end
end
```

---

## Endpoints

### Print Pricings

The core resource for 3D print job cost calculations.

#### List Print Pricings

```
GET /api/v1/print_pricings
```

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `page` | integer | Page number (default: 1) |
| `per_page` | integer | Items per page (max: 100, default: 25) |
| `sort` | string | Sort field (created_at, job_name, final_price) |
| `order` | string | Sort order (asc, desc) |
| `q[job_name_cont]` | string | Search by job name |
| `q[printer_id_eq]` | integer | Filter by printer |
| `q[client_id_eq]` | integer | Filter by client |
| `q[created_at_gteq]` | datetime | Created after |
| `q[created_at_lteq]` | datetime | Created before |

**Response:**

```json
{
  "data": [
    {
      "id": 1,
      "type": "print_pricing",
      "attributes": {
        "job_name": "Phone Stand",
        "units": 1,
        "times_printed": 3,
        "final_price": "25.50",
        "per_unit_price": "25.50",
        "total_filament_cost": "5.25",
        "total_electricity_cost": "0.45",
        "total_labor_cost": "10.00",
        "total_machine_upkeep_cost": "2.80",
        "other_costs": "0.00",
        "failure_rate_percentage": "5.0",
        "vat_percentage": "10.0",
        "prep_time_minutes": 15,
        "postprocessing_time_minutes": 30,
        "created_at": "2025-12-19T10:30:00Z",
        "updated_at": "2025-12-19T10:30:00Z"
      },
      "relationships": {
        "printer": { "data": { "id": 1, "type": "printer" } },
        "client": { "data": null },
        "plates": { "data": [{ "id": 1, "type": "plate" }] }
      }
    }
  ],
  "meta": { "current_page": 1, "total_pages": 1, "total_count": 1 }
}
```

#### Get Print Pricing

```
GET /api/v1/print_pricings/:id
```

**Response includes:**
- Full print pricing attributes
- Nested plates with filaments
- Printer details
- Client details (if assigned)
- Cost breakdown calculations

#### Create Print Pricing

```
POST /api/v1/print_pricings
```

**Request Body:**

```json
{
  "print_pricing": {
    "job_name": "Custom Bracket",
    "printer_id": 1,
    "client_id": 5,
    "units": 10,
    "failure_rate_percentage": 5.0,
    "vat_percentage": 10.0,
    "prep_time_minutes": 15,
    "prep_cost_per_hour": 25.00,
    "postprocessing_time_minutes": 30,
    "postprocessing_cost_per_hour": 20.00,
    "other_costs": 5.00,
    "listing_cost_percentage": 3.0,
    "payment_processing_cost_percentage": 2.5,
    "plates_attributes": [
      {
        "printing_time_hours": 2,
        "printing_time_minutes": 30,
        "plate_filaments_attributes": [
          {
            "filament_id": 1,
            "filament_weight": 50.0
          }
        ]
      }
    ]
  }
}
```

#### Update Print Pricing

```
PATCH /api/v1/print_pricings/:id
```

Supports partial updates. Nested plates can be:
- Created (no `id` field)
- Updated (include `id` field)
- Deleted (include `id` and `_destroy: true`)

#### Delete Print Pricing

```
DELETE /api/v1/print_pricings/:id
```

Returns `204 No Content` on success.

#### Duplicate Print Pricing

```
POST /api/v1/print_pricings/:id/duplicate
```

Creates a copy with "(Copy)" appended to job name.

#### Increment/Decrement Times Printed

```
PATCH /api/v1/print_pricings/:id/increment_times_printed
PATCH /api/v1/print_pricings/:id/decrement_times_printed
```

---

### Plates

Plates are nested under print pricings but can also be accessed directly.

#### List Plates for Print Pricing

```
GET /api/v1/print_pricings/:print_pricing_id/plates
```

#### Get Plate

```
GET /api/v1/print_pricings/:print_pricing_id/plates/:id
```

**Response:**

```json
{
  "data": {
    "id": 1,
    "type": "plate",
    "attributes": {
      "printing_time_hours": 2,
      "printing_time_minutes": 30,
      "total_printing_time_minutes": 150,
      "total_filament_cost": "5.25",
      "total_filament_weight": 50.0
    },
    "relationships": {
      "plate_filaments": {
        "data": [{ "id": 1, "type": "plate_filament" }]
      }
    }
  }
}
```

---

### Printers

Manage 3D printers for cost calculations.

#### List Printers

```
GET /api/v1/printers
```

#### Get Printer

```
GET /api/v1/printers/:id
```

**Response:**

```json
{
  "data": {
    "id": 1,
    "type": "printer",
    "attributes": {
      "name": "Prusa MK4",
      "manufacturer": "Prusa",
      "power_consumption": 150,
      "cost": 799.00,
      "payoff_goal_years": 3,
      "daily_usage_hours": 8,
      "repair_cost_percentage": 10.0,
      "date_added": "2024-01-15",
      "paid_off": false,
      "months_to_payoff": 24
    }
  }
}
```

#### Create Printer

```
POST /api/v1/printers
```

**Request Body:**

```json
{
  "printer": {
    "name": "Bambu Lab X1C",
    "manufacturer": "Bambu Lab",
    "power_consumption": 350,
    "cost": 1449.00,
    "payoff_goal_years": 2,
    "daily_usage_hours": 12,
    "repair_cost_percentage": 5.0
  }
}
```

#### Update Printer

```
PATCH /api/v1/printers/:id
```

#### Delete Printer

```
DELETE /api/v1/printers/:id
```

---

### Filaments

Manage filament inventory and pricing.

#### List Filaments

```
GET /api/v1/filaments
```

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `q[material_type_eq]` | string | Filter by material (PLA, ABS, PETG, etc.) |
| `q[brand_cont]` | string | Search by brand |
| `q[color_cont]` | string | Search by color |

#### Get Filament

```
GET /api/v1/filaments/:id
```

**Response:**

```json
{
  "data": {
    "id": 1,
    "type": "filament",
    "attributes": {
      "name": "Galaxy Black",
      "brand": "Prusament",
      "material_type": "PLA",
      "color": "Black",
      "diameter": 1.75,
      "spool_weight": 1000,
      "spool_price": 24.99,
      "cost_per_gram": 0.025,
      "print_temperature_min": 210,
      "print_temperature_max": 220,
      "heated_bed_temperature": 60,
      "print_speed_max": 200,
      "density": 1.24,
      "moisture_sensitive": true,
      "notes": "Great for detailed prints"
    }
  }
}
```

#### Create Filament

```
POST /api/v1/filaments
```

#### Update Filament

```
PATCH /api/v1/filaments/:id
```

#### Delete Filament

```
DELETE /api/v1/filaments/:id
```

#### Duplicate Filament

```
POST /api/v1/filaments/:id/duplicate
```

---

### Clients

Manage customer information.

#### List Clients

```
GET /api/v1/clients
```

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `q[name_cont]` | string | Search by name |
| `q[company_name_cont]` | string | Search by company |
| `q[email_cont]` | string | Search by email |

#### Get Client

```
GET /api/v1/clients/:id
```

**Response:**

```json
{
  "data": {
    "id": 5,
    "type": "client",
    "attributes": {
      "name": "John Smith",
      "company_name": "Acme Corp",
      "email": "john@acme.com",
      "phone": "+1-555-0123",
      "address": "123 Main St, City, ST 12345",
      "tax_id": "12-3456789",
      "notes": "Preferred customer",
      "display_name": "Acme Corp (John Smith)"
    },
    "relationships": {
      "invoices": { "data": [{ "id": 10, "type": "invoice" }] },
      "print_pricings": { "data": [{ "id": 1, "type": "print_pricing" }] }
    }
  }
}
```

#### Create Client

```
POST /api/v1/clients
```

#### Update Client

```
PATCH /api/v1/clients/:id
```

#### Delete Client

```
DELETE /api/v1/clients/:id
```

---

### Invoices

Manage invoices linked to print pricings.

#### List All Invoices

```
GET /api/v1/invoices
```

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `status` | string | Filter by status (draft, sent, paid, cancelled) |
| `q[invoice_number_cont]` | string | Search by invoice number |
| `q[client_id_eq]` | integer | Filter by client |
| `q[invoice_date_gteq]` | date | Invoice date after |
| `q[invoice_date_lteq]` | date | Invoice date before |

#### List Invoices for Print Pricing

```
GET /api/v1/print_pricings/:print_pricing_id/invoices
```

#### Get Invoice

```
GET /api/v1/invoices/:id
```

**Response:**

```json
{
  "data": {
    "id": 10,
    "type": "invoice",
    "attributes": {
      "invoice_number": "INV-000042",
      "reference_id": "CM-20251219-A3F9D2E1",
      "status": "sent",
      "invoice_date": "2025-12-19",
      "due_date": "2026-01-18",
      "currency": "USD",
      "subtotal": "125.50",
      "tax_amount": "12.55",
      "tax_percentage": 10.0,
      "total": "138.05",
      "overdue": false,
      "company_name": "CalcuMake LLC",
      "company_address": "123 Print St",
      "company_email": "billing@calcumake.com",
      "company_phone": "+1-555-0100",
      "payment_details": "Bank: Example Bank\nAccount: 12345678",
      "notes": "Thank you for your business!"
    },
    "relationships": {
      "print_pricing": { "data": { "id": 1, "type": "print_pricing" } },
      "client": { "data": { "id": 5, "type": "client" } },
      "invoice_line_items": {
        "data": [
          { "id": 1, "type": "invoice_line_item" }
        ]
      }
    }
  }
}
```

#### Create Invoice

```
POST /api/v1/print_pricings/:print_pricing_id/invoices
```

**Request Body:**

```json
{
  "invoice": {
    "client_id": 5,
    "invoice_date": "2025-12-19",
    "due_date": "2026-01-18",
    "notes": "Net 30 payment terms",
    "auto_generate_line_items": true,
    "invoice_line_items_attributes": [
      {
        "description": "Additional service fee",
        "quantity": 1,
        "unit_price": 25.00,
        "line_item_type": "other"
      }
    ]
  }
}
```

When `auto_generate_line_items: true`, the API automatically creates line items from the print pricing cost breakdown.

#### Update Invoice

```
PATCH /api/v1/invoices/:id
```

#### Delete Invoice

```
DELETE /api/v1/invoices/:id
```

#### Invoice Status Actions

```
PATCH /api/v1/invoices/:id/mark_as_sent
PATCH /api/v1/invoices/:id/mark_as_paid
PATCH /api/v1/invoices/:id/mark_as_cancelled
```

---

### Invoice Line Items

Manage individual line items on invoices.

#### List Line Items

```
GET /api/v1/invoices/:invoice_id/line_items
```

#### Create Line Item

```
POST /api/v1/invoices/:invoice_id/line_items
```

**Request Body:**

```json
{
  "invoice_line_item": {
    "description": "Rush processing fee",
    "quantity": 1,
    "unit_price": 15.00,
    "line_item_type": "other",
    "order_position": 5
  }
}
```

#### Update Line Item

```
PATCH /api/v1/invoices/:invoice_id/line_items/:id
```

#### Delete Line Item

```
DELETE /api/v1/invoices/:invoice_id/line_items/:id
```

---

### User Profile

Access and update user settings.

#### Get Current User

```
GET /api/v1/me
```

**Response:**

```json
{
  "data": {
    "id": 1,
    "type": "user",
    "attributes": {
      "email": "user@example.com",
      "locale": "en",
      "default_currency": "USD",
      "default_energy_cost_per_kwh": 0.12,
      "default_vat_percentage": 10.0,
      "default_prep_time_minutes": 15,
      "default_prep_cost_per_hour": 25.00,
      "default_postprocessing_time_minutes": 30,
      "default_postprocessing_cost_per_hour": 20.00,
      "default_listing_cost_percentage": 3.0,
      "default_payment_processing_cost_percentage": 2.5,
      "plan": "startup",
      "trial_ends_at": "2026-01-19T00:00:00Z",
      "in_trial_period": true,
      "trial_days_remaining": 31,
      "active_subscription": true
    },
    "meta": {
      "usage": {
        "print_pricings": { "current": 45, "limit": 100 },
        "printers": { "current": 3, "limit": 10 },
        "filaments": { "current": 12, "limit": 50 },
        "invoices": { "current": 28, "limit": 100 },
        "clients": { "current": 8, "limit": 50 }
      }
    }
  }
}
```

#### Update User Settings

```
PATCH /api/v1/me
```

**Request Body:**

```json
{
  "user": {
    "locale": "ja",
    "default_currency": "JPY",
    "default_energy_cost_per_kwh": 25.0,
    "default_vat_percentage": 10.0,
    "default_company_name": "My Print Shop",
    "default_company_address": "123 Maker Lane",
    "default_company_email": "billing@myshop.com",
    "default_payment_details": "Pay to: My Print Shop"
  }
}
```

#### Export User Data (GDPR)

```
GET /api/v1/me/export
```

Returns complete data export in JSON format for GDPR compliance.

---

### API Tokens

Manage API authentication tokens.

#### List API Tokens

```
GET /api/v1/api_tokens
```

**Response:**

```json
{
  "data": [
    {
      "id": 1,
      "type": "api_token",
      "attributes": {
        "name": "Production Integration",
        "token_prefix": "cm_*****abc",
        "last_used_at": "2025-12-19T08:30:00Z",
        "expires_at": null,
        "created_at": "2025-12-01T10:00:00Z"
      }
    }
  ]
}
```

#### Create API Token

```
POST /api/v1/api_tokens
```

**Request Body:**

```json
{
  "api_token": {
    "name": "Mobile App",
    "expires_at": "2026-12-19T00:00:00Z"
  }
}
```

**Response includes full token (only shown once):**

```json
{
  "data": {
    "id": 2,
    "type": "api_token",
    "attributes": {
      "name": "Mobile App",
      "token": "cm_abc123def456ghi789jkl012mno345",
      "token_prefix": "cm_*****345",
      "expires_at": "2026-12-19T00:00:00Z"
    }
  },
  "meta": {
    "warning": "Store this token securely. It will not be shown again."
  }
}
```

#### Revoke API Token

```
DELETE /api/v1/api_tokens/:id
```

---

### Calculator (Public Endpoint)

Public pricing calculation without authentication.

#### Calculate Pricing

```
POST /api/v1/calculator
```

**Request Body:**

```json
{
  "calculation": {
    "currency": "USD",
    "energy_cost_per_kwh": 0.12,
    "printer": {
      "power_consumption": 150,
      "cost": 799.00,
      "payoff_goal_years": 3,
      "daily_usage_hours": 8,
      "repair_cost_percentage": 10.0
    },
    "plates": [
      {
        "printing_time_hours": 2,
        "printing_time_minutes": 30,
        "filaments": [
          { "weight": 50.0, "cost_per_kg": 25.00 }
        ]
      }
    ],
    "labor": {
      "prep_time_minutes": 15,
      "prep_cost_per_hour": 25.00,
      "postprocessing_time_minutes": 30,
      "postprocessing_cost_per_hour": 20.00
    },
    "other_costs": 5.00,
    "failure_rate_percentage": 5.0,
    "units": 10,
    "vat_percentage": 10.0,
    "listing_cost_percentage": 3.0,
    "payment_processing_cost_percentage": 2.5
  }
}
```

**Response:**

```json
{
  "data": {
    "type": "calculation",
    "attributes": {
      "currency": "USD",
      "breakdown": {
        "filament_cost": "5.25",
        "electricity_cost": "0.45",
        "labor_cost": "10.00",
        "machine_upkeep_cost": "2.80",
        "other_costs": "5.00",
        "subtotal": "23.50",
        "listing_fee": "0.71",
        "payment_processing_fee": "0.59",
        "vat_amount": "2.48",
        "final_price": "27.28",
        "per_unit_price": "2.73"
      },
      "plates": [
        {
          "printing_time_minutes": 150,
          "filament_cost": "5.25",
          "filament_weight": 50.0
        }
      ]
    }
  }
}
```

---

## Token Management UI

### Architecture Overview

The token management interface is built with:
- **Rails 8.1.1** with Importmaps (no Node.js build step)
- **Turbo/Hotwire** for seamless SPA-like interactions
- **Stimulus** controllers for JavaScript behavior
- **ViewComponents** for reusable, testable UI components

### ViewComponent Structure

```
app/components/
├── api_tokens/
│   ├── token_list_component.rb
│   ├── token_list_component.html.erb
│   ├── token_card_component.rb
│   ├── token_card_component.html.erb
│   ├── token_form_component.rb
│   ├── token_form_component.html.erb
│   ├── token_reveal_component.rb      # One-time reveal modal
│   └── token_reveal_component.html.erb
└── shared/
    └── ... (existing components)

test/components/
└── api_tokens/
    ├── token_list_component_test.rb
    ├── token_card_component_test.rb
    ├── token_form_component_test.rb
    └── token_reveal_component_test.rb
```

### Token Card Component

```ruby
# app/components/api_tokens/token_card_component.rb
class ApiTokens::TokenCardComponent < ViewComponent::Base
  def initialize(token:)
    @token = token
  end

  def status_badge_class
    if @token.revoked?
      "bg-danger"
    elsif @token.expired?
      "bg-warning text-dark"
    else
      "bg-success"
    end
  end

  def status_text
    if @token.revoked?
      t('api_tokens.status.revoked')
    elsif @token.expired?
      t('api_tokens.status.expired')
    else
      t('api_tokens.status.active')
    end
  end

  def expires_text
    return t('api_tokens.never_expires') if @token.never_expires?
    return t('api_tokens.expired_on', date: l(@token.expires_at, format: :short)) if @token.expired?

    t('api_tokens.expires_on', date: l(@token.expires_at, format: :short))
  end

  def last_used_text
    return t('api_tokens.never_used') unless @token.last_used_at

    t('api_tokens.last_used', time: time_ago_in_words(@token.last_used_at))
  end
end
```

```erb
<%# app/components/api_tokens/token_card_component.html.erb %>
<div class="card mb-3" data-controller="api-token-card">
  <div class="card-body">
    <div class="d-flex justify-content-between align-items-start">
      <div>
        <h5 class="card-title mb-1">
          <%= @token.name %>
          <span class="badge <%= status_badge_class %> ms-2"><%= status_text %></span>
        </h5>
        <p class="text-muted mb-2">
          <code class="user-select-all"><%= @token.token_hint %></code>
        </p>
      </div>

      <% if @token.active? %>
        <%= button_to api_token_path(@token),
              method: :delete,
              class: "btn btn-outline-danger btn-sm",
              form: { data: { turbo_confirm: t('api_tokens.revoke_confirm') } } do %>
          <i class="bi bi-x-circle me-1"></i>
          <%= t('api_tokens.revoke') %>
        <% end %>
      <% end %>
    </div>

    <div class="row text-muted small mt-3">
      <div class="col-auto">
        <i class="bi bi-calendar me-1"></i>
        <%= t('api_tokens.created', date: l(@token.created_at, format: :short)) %>
      </div>
      <div class="col-auto">
        <i class="bi bi-clock me-1"></i>
        <%= expires_text %>
      </div>
      <div class="col-auto">
        <i class="bi bi-activity me-1"></i>
        <%= last_used_text %>
      </div>
    </div>
  </div>
</div>
```

### Token Reveal Component (One-Time Display)

```ruby
# app/components/api_tokens/token_reveal_component.rb
class ApiTokens::TokenRevealComponent < ViewComponent::Base
  def initialize(token:, plain_token:)
    @token = token
    @plain_token = plain_token
  end

  # Security: This component should only be rendered immediately after token creation
  # The plain_token is only available in memory at creation time
end
```

```erb
<%# app/components/api_tokens/token_reveal_component.html.erb %>
<div class="card border-warning" data-controller="api-token" data-api-token-revealed-value="true">
  <div class="card-header bg-warning text-dark">
    <i class="bi bi-exclamation-triangle me-2"></i>
    <strong><%= t('api_tokens.reveal.title') %></strong>
  </div>

  <div class="card-body" data-api-token-target="revealSection">
    <div class="alert alert-danger mb-3">
      <i class="bi bi-shield-exclamation me-2"></i>
      <strong><%= t('api_tokens.reveal.warning') %></strong>
      <p class="mb-0 mt-2"><%= t('api_tokens.reveal.warning_detail') %></p>
    </div>

    <div class="mb-3">
      <label class="form-label fw-bold"><%= t('api_tokens.reveal.your_token') %></label>
      <div class="input-group">
        <code class="form-control bg-light user-select-all font-monospace"
              data-api-token-target="tokenDisplay"
              style="word-break: break-all;">
          <%= @plain_token %>
        </code>
        <button type="button"
                class="btn btn-outline-primary"
                data-api-token-target="copyButton"
                data-action="click->api-token#copy">
          <i class="bi bi-clipboard"></i>
          <%= t('api_tokens.copy') %>
        </button>
      </div>
    </div>

    <div class="alert alert-info mb-0">
      <i class="bi bi-info-circle me-2"></i>
      <%= t('api_tokens.reveal.auto_hide_notice') %>
    </div>
  </div>
</div>
```

### Token Form Component

```ruby
# app/components/api_tokens/token_form_component.rb
class ApiTokens::TokenFormComponent < ViewComponent::Base
  def initialize(token:)
    @token = token
  end

  def expiration_options
    ApiToken::EXPIRATION_OPTIONS.map do |key, _duration|
      [t("api_tokens.expiration.#{key}"), key]
    end
  end
end
```

```erb
<%# app/components/api_tokens/token_form_component.html.erb %>
<%= form_with model: @token, url: api_tokens_path, data: { turbo_frame: "api_tokens_list" } do |form| %>
  <%= render Forms::ErrorsComponent.new(model: @token) %>

  <div class="row g-3">
    <%= render Forms::FieldComponent.new(
      form: form,
      attribute: :name,
      type: :text,
      label: t('api_tokens.fields.name'),
      hint: t('api_tokens.fields.name_hint'),
      wrapper_class: "col-md-6",
      options: { placeholder: t('api_tokens.fields.name_placeholder'), autofocus: true }
    ) %>

    <%= render Forms::SelectFieldComponent.new(
      form: form,
      attribute: :expiration,
      choices: expiration_options,
      label: t('api_tokens.fields.expiration'),
      hint: t('api_tokens.fields.expiration_hint'),
      wrapper_class: "col-md-6"
    ) %>
  </div>

  <div class="mt-4">
    <%= form.submit t('api_tokens.create'), class: "btn btn-primary" %>
    <%= link_to t('actions.cancel'), user_profile_path(anchor: 'api-tokens'), class: "btn btn-outline-secondary ms-2" %>
  </div>
<% end %>
```

### Profile Page Integration

```erb
<%# Add to app/views/user_profiles/show.html.erb %>

<!-- API Tokens Section -->
<div class="col-12" id="api-tokens">
  <div class="card">
    <div class="card-header d-flex justify-content-between align-items-center">
      <h5 class="mb-0">
        <i class="bi bi-key me-2"></i>
        <%= t('api_tokens.title') %>
      </h5>
      <%= link_to new_api_token_path,
            class: "btn btn-primary btn-sm",
            data: { turbo_frame: "api_token_modal" } do %>
        <i class="bi bi-plus-lg me-1"></i>
        <%= t('api_tokens.new') %>
      <% end %>
    </div>

    <div class="card-body">
      <p class="text-muted mb-4"><%= t('api_tokens.description') %></p>

      <%= turbo_frame_tag "api_tokens_list" do %>
        <% if @api_tokens.any? %>
          <% @api_tokens.each do |token| %>
            <%= render ApiTokens::TokenCardComponent.new(token: token) %>
          <% end %>
        <% else %>
          <div class="text-center text-muted py-4">
            <i class="bi bi-key display-4 mb-3 d-block opacity-50"></i>
            <p><%= t('api_tokens.empty') %></p>
          </div>
        <% end %>
      <% end %>
    </div>
  </div>
</div>

<!-- Modal for token creation/reveal -->
<%= render 'shared/modal', id: 'api_token_modal' %>
```

### Stimulus Controllers

```javascript
// app/javascript/controllers/api_token_controller.js
// (Already defined in Token Security Architecture section above)

// app/javascript/controllers/api_token_card_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["revokeButton"]

  connect() {
    // Highlight newly created tokens
    if (this.element.dataset.newToken === "true") {
      this.element.classList.add("border-success", "border-2")
      setTimeout(() => {
        this.element.classList.remove("border-success", "border-2")
      }, 3000)
    }
  }
}
```

### Turbo Stream Responses

```ruby
# app/controllers/api_tokens_controller.rb
class ApiTokensController < ApplicationController
  before_action :authenticate_user!

  def index
    @api_tokens = current_user.api_tokens.order(created_at: :desc)
  end

  def new
    @api_token = current_user.api_tokens.build
  end

  def create
    @api_token = current_user.api_tokens.build(api_token_params)
    @api_token.created_from_ip = request.remote_ip
    @api_token.user_agent = request.user_agent

    if @api_token.save
      # Store plain token temporarily for one-time reveal
      @plain_token = @api_token.plain_token

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to user_profile_path(anchor: 'api-tokens') }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @api_token = current_user.api_tokens.find(params[:id])
    @api_token.revoke!

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(@api_token, partial: "api_tokens/token_card", locals: { token: @api_token }) }
      format.html { redirect_to user_profile_path(anchor: 'api-tokens'), notice: t('api_tokens.revoked_success') }
    end
  end

  private

  def api_token_params
    params.require(:api_token).permit(:name, :expiration)
  end
end
```

```erb
<%# app/views/api_tokens/create.turbo_stream.erb %>

<%# Close the modal %>
<%= turbo_stream.update "api_token_modal" do %>
  <%= render 'shared/modal', id: 'api_token_modal' %>
<% end %>

<%# Show the one-time token reveal %>
<%= turbo_stream.prepend "api_tokens_list" do %>
  <%= render ApiTokens::TokenRevealComponent.new(token: @api_token, plain_token: @plain_token) %>
<% end %>

<%# Add the new token card below the reveal %>
<%= turbo_stream.append "api_tokens_list" do %>
  <div data-new-token="true">
    <%= render ApiTokens::TokenCardComponent.new(token: @api_token) %>
  </div>
<% end %>
```

### Component Tests

```ruby
# test/components/api_tokens/token_card_component_test.rb
require "test_helper"

class ApiTokens::TokenCardComponentTest < ViewComponent::TestCase
  test "renders active token with success badge" do
    token = api_tokens(:active)

    render_inline(ApiTokens::TokenCardComponent.new(token: token))

    assert_selector ".badge.bg-success", text: I18n.t('api_tokens.status.active')
    assert_selector "code", text: token.token_hint
    assert_selector "button", text: I18n.t('api_tokens.revoke')
  end

  test "renders expired token with warning badge" do
    token = api_tokens(:expired)

    render_inline(ApiTokens::TokenCardComponent.new(token: token))

    assert_selector ".badge.bg-warning", text: I18n.t('api_tokens.status.expired')
    refute_selector "button", text: I18n.t('api_tokens.revoke')
  end

  test "renders revoked token with danger badge" do
    token = api_tokens(:revoked)

    render_inline(ApiTokens::TokenCardComponent.new(token: token))

    assert_selector ".badge.bg-danger", text: I18n.t('api_tokens.status.revoked')
    refute_selector "button", text: I18n.t('api_tokens.revoke')
  end

  test "shows last used time when available" do
    token = api_tokens(:active)
    token.update!(last_used_at: 2.hours.ago)

    render_inline(ApiTokens::TokenCardComponent.new(token: token))

    assert_text "2 hours"
  end
end

# test/components/api_tokens/token_reveal_component_test.rb
require "test_helper"

class ApiTokens::TokenRevealComponentTest < ViewComponent::TestCase
  test "renders plain token in code block" do
    token = api_tokens(:active)
    plain_token = "cm_test123abc456def789"

    render_inline(ApiTokens::TokenRevealComponent.new(token: token, plain_token: plain_token))

    assert_selector "code", text: plain_token
    assert_selector "[data-api-token-revealed-value='true']"
  end

  test "shows security warning" do
    token = api_tokens(:active)
    plain_token = "cm_test123abc456def789"

    render_inline(ApiTokens::TokenRevealComponent.new(token: token, plain_token: plain_token))

    assert_selector ".alert-danger"
    assert_text I18n.t('api_tokens.reveal.warning')
  end
end
```

### Translations

```yaml
# config/locales/en/api_tokens.yml
en:
  api_tokens:
    title: "API Tokens"
    description: "Create tokens to access the CalcuMake API from external applications."
    new: "Create Token"
    create: "Create Token"
    revoke: "Revoke"
    copy: "Copy"
    empty: "No API tokens yet. Create one to get started."
    revoke_confirm: "Are you sure? This token will immediately stop working."
    revoked_success: "Token revoked successfully."
    never_expires: "Never expires"
    never_used: "Never used"
    expires_on: "Expires %{date}"
    expired_on: "Expired %{date}"
    last_used: "Last used %{time} ago"
    created: "Created %{date}"

    status:
      active: "Active"
      expired: "Expired"
      revoked: "Revoked"

    fields:
      name: "Token Name"
      name_hint: "A descriptive name to identify this token"
      name_placeholder: "e.g., Production Server, CI/CD Pipeline"
      expiration: "Expiration"
      expiration_hint: "When should this token expire?"

    expiration:
      30_days: "30 days"
      90_days: "90 days (recommended)"
      1_year: "1 year"
      never: "Never (not recommended)"

    reveal:
      title: "Your New API Token"
      warning: "Copy this token now!"
      warning_detail: "This is the only time you'll see this token. Store it securely - you won't be able to see it again."
      your_token: "Your API Token"
      auto_hide_notice: "This token will be hidden automatically in 60 seconds for security."
```

---

## Implementation Plan

### Phase 1: Foundation (Priority: Critical)

1. **API Base Controller**
   - Create `Api::V1::BaseController`
   - Token authentication via `authenticate_with_http_token`
   - JSON:API response formatting
   - Error handling and status codes
   - Rate limiting middleware

2. **API Token Model**
   - Create `ApiToken` model with secure token generation
   - Add `token_digest` column (never store plain tokens)
   - Token validation and expiration checks
   - Last used timestamp tracking

3. **Database Migration**
   ```ruby
   create_table :api_tokens do |t|
     t.references :user, null: false, foreign_key: true
     t.string :name, null: false
     t.string :token_digest, null: false
     t.string :token_prefix, null: false  # First/last 3 chars for identification
     t.datetime :last_used_at
     t.datetime :expires_at
     t.timestamps
   end
   add_index :api_tokens, :token_digest, unique: true
   ```

### Phase 2: Core Resources (Priority: High)

4. **Print Pricings API**
   - Full CRUD operations
   - Nested plates and filaments
   - Duplicate action
   - Times printed increment/decrement

5. **Printers API**
   - Full CRUD operations
   - Manufacturer list endpoint

6. **Filaments API**
   - Full CRUD operations
   - Material types list endpoint
   - Duplicate action

7. **Clients API**
   - Full CRUD operations
   - Search and filtering

### Phase 3: Invoicing (Priority: High)

8. **Invoices API**
   - Full CRUD with nested line items
   - Status transitions
   - Auto-generate line items from print pricing

9. **Invoice Line Items API**
   - Nested CRUD under invoices
   - Position ordering

### Phase 4: User & Settings (Priority: Medium)

10. **User Profile API**
    - Get/update current user
    - GDPR data export

11. **API Tokens Management**
    - List/create/revoke tokens
    - Token UI in profile settings

### Phase 5: Public & Advanced (Priority: Medium)

12. **Public Calculator API**
    - Unauthenticated pricing calculations
    - Rate limiting by IP

13. **Webhooks (Future)**
    - Invoice status changes
    - Print pricing creation
    - Subscription events

### File Structure

```
app/
├── controllers/
│   └── api/
│       └── v1/
│           ├── base_controller.rb
│           ├── print_pricings_controller.rb
│           ├── plates_controller.rb
│           ├── printers_controller.rb
│           ├── filaments_controller.rb
│           ├── clients_controller.rb
│           ├── invoices_controller.rb
│           ├── invoice_line_items_controller.rb
│           ├── users_controller.rb
│           ├── api_tokens_controller.rb
│           └── calculator_controller.rb
├── models/
│   └── api_token.rb
├── serializers/  (or app/views/api/v1/*.json.jbuilder)
│   └── api/
│       └── v1/
│           ├── print_pricing_serializer.rb
│           ├── printer_serializer.rb
│           └── ...
└── services/
    └── api/
        └── rate_limiter.rb

config/
└── routes.rb  # Add API namespace

test/
└── controllers/
    └── api/
        └── v1/
            ├── print_pricings_controller_test.rb
            └── ...
```

### Routes Configuration (Production-Ready)

**Best Practices Applied:**
- API namespace isolation for versioning
- Shallow nesting to keep URLs manageable
- Concerns for shared route patterns
- Constraints for format enforcement
- Health check endpoint for monitoring

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # ... existing web routes ...

  # ============================================
  # API Routes - Versioned, JSON-only
  # ============================================
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      # Health check for load balancers and monitoring
      get :health, to: 'health#show'

      # ----------------------------------------
      # Public endpoints (no authentication)
      # ----------------------------------------
      # Pricing calculator - public, rate-limited by IP
      post :calculator, to: 'calculator#create'

      # ----------------------------------------
      # Authenticated endpoints
      # ----------------------------------------
      # Current user profile and settings
      resource :me, controller: 'users', only: [:show, :update] do
        get :export, action: :export_data
        get :usage, action: :usage_stats
      end

      # API token management (web UI uses separate controller)
      resources :api_tokens, only: [:index, :create, :destroy]

      # ----------------------------------------
      # Core resources with shallow nesting
      # ----------------------------------------
      # Print pricings - primary resource
      resources :print_pricings do
        member do
          post :duplicate
          patch :increment_times_printed
          patch :decrement_times_printed
        end

        # Shallow nested resources - accessible via /plates/:id after creation
        resources :plates, shallow: true, only: [:index, :show, :create, :update, :destroy]

        # Invoices created under print_pricing, but accessible standalone
        resources :invoices, shallow: true do
          member do
            patch :mark_as_sent
            patch :mark_as_paid
            patch :mark_as_cancelled
          end
        end
      end

      # Printers - standalone CRUD
      resources :printers

      # Filaments - with duplicate action
      resources :filaments do
        member do
          post :duplicate
        end
      end

      # Clients - standalone CRUD
      resources :clients

      # Invoices - standalone access (shallow routes provide /invoices/:id)
      # Additional collection route for filtering across all invoices
      resources :invoices, only: [:index] do
        resources :line_items, controller: 'invoice_line_items',
                               shallow: true,
                               only: [:index, :show, :create, :update, :destroy]
      end

      # ----------------------------------------
      # Reference data endpoints
      # ----------------------------------------
      namespace :reference do
        get :currencies, to: 'data#currencies'
        get :material_types, to: 'data#material_types'
        get :printer_manufacturers, to: 'data#printer_manufacturers'
      end
    end

    # Future API versions
    # namespace :v2 do
    #   # V2 routes when needed
    # end
  end

  # ============================================
  # Web UI for API Token Management
  # ============================================
  resources :api_tokens, only: [:index, :new, :create, :destroy]
end
```

### Route Constraints

```ruby
# config/routes.rb - Add constraints for production safety
namespace :api, defaults: { format: :json } do
  namespace :v1 do
    # Enforce JSON format
    constraints format: :json do
      # ... all API routes ...
    end
  end
end

# lib/constraints/api_version_constraint.rb
class ApiVersionConstraint
  def initialize(version:, default: false)
    @version = version
    @default = default
  end

  def matches?(request)
    @default || accept_header_matches?(request)
  end

  private

  def accept_header_matches?(request)
    accept = request.headers['Accept']
    accept&.include?("application/vnd.calcumake.v#{@version}+json")
  end
end

# Alternative: Header-based versioning (future enhancement)
# namespace :api do
#   scope module: :v1, constraints: ApiVersionConstraint.new(version: 1, default: true) do
#     # v1 routes
#   end
# end
```

### URL Structure Summary

| Resource | URL Pattern | Description |
|----------|-------------|-------------|
| Health | `GET /api/v1/health` | API health check |
| Calculator | `POST /api/v1/calculator` | Public pricing calculator |
| Current User | `GET /api/v1/me` | Get authenticated user |
| User Settings | `PATCH /api/v1/me` | Update user settings |
| Data Export | `GET /api/v1/me/export` | GDPR data export |
| API Tokens | `GET /api/v1/api_tokens` | List user's tokens |
| Print Pricings | `GET /api/v1/print_pricings` | List pricings |
| Print Pricing | `GET /api/v1/print_pricings/:id` | Get single pricing |
| Plates | `GET /api/v1/print_pricings/:id/plates` | List plates (nested) |
| Plate | `GET /api/v1/plates/:id` | Get plate (shallow) |
| Invoices | `GET /api/v1/invoices` | List all invoices |
| Invoice | `GET /api/v1/invoices/:id` | Get invoice (shallow) |
| Line Items | `GET /api/v1/invoices/:id/line_items` | List line items |
| Line Item | `GET /api/v1/line_items/:id` | Get line item (shallow) |
| Printers | `GET /api/v1/printers` | List printers |
| Filaments | `GET /api/v1/filaments` | List filaments |
| Clients | `GET /api/v1/clients` | List clients |
| Currencies | `GET /api/v1/reference/currencies` | List supported currencies |

### Shallow Nesting Benefits

**Before (deeply nested):**
```
GET /api/v1/print_pricings/123/invoices/456/line_items/789
```

**After (shallow):**
```
GET /api/v1/line_items/789
```

- Shorter, cleaner URLs
- Easier to cache (simpler cache keys)
- Reduces coupling between resources
- Still maintains logical hierarchy for creation

### Testing Strategy

Each endpoint requires:
1. **Authentication tests** - Valid/invalid/missing token
2. **Authorization tests** - Can only access own resources
3. **CRUD tests** - Create, read, update, delete operations
4. **Validation tests** - Error responses for invalid data
5. **Pagination tests** - Proper meta and links
6. **Filter/search tests** - Query parameter handling

Example test structure:
```ruby
# test/controllers/api/v1/print_pricings_controller_test.rb
class Api::V1::PrintPricingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @token = api_tokens(:one)
    @headers = { 'Authorization' => "Bearer #{@token.token}" }
  end

  test "index returns paginated print pricings" do
    get api_v1_print_pricings_url, headers: @headers
    assert_response :success
    json = JSON.parse(response.body)
    assert json.key?('data')
    assert json.key?('meta')
  end

  test "returns 401 without token" do
    get api_v1_print_pricings_url
    assert_response :unauthorized
  end

  test "returns 404 for other user's resource" do
    other_pricing = print_pricings(:other_user)
    get api_v1_print_pricing_url(other_pricing), headers: @headers
    assert_response :not_found
  end
end
```

---

## Documentation

### OpenAPI/Swagger Specification

Generate OpenAPI 3.0 spec using `rswag` gem for:
- Interactive API documentation
- Client SDK generation
- API testing

### Developer Portal

Create `/api/docs` route with:
- Getting started guide
- Authentication setup
- Code examples in multiple languages
- Changelog and versioning info

---

## Security Considerations

### Database Security

| Measure | Implementation |
|---------|----------------|
| **Token Storage** | SHA-256 digest only, never plain text |
| **Token Hint** | First 7 + last 4 chars for display (`cm_abc...xyz`) |
| **Expiration** | Required (30d/90d/1y), "never" discouraged |
| **Revocation** | Immediate via `revoked_at` timestamp |
| **Audit Trail** | IP address, user agent, timestamps logged |
| **Cascade Delete** | Tokens deleted when user account deleted |

### API Security

| Measure | Implementation |
|---------|----------------|
| **Authentication** | Bearer token via `Authorization` header |
| **Timing Attacks** | SHA-256 digest comparison (constant-time lookup) |
| **Rate Limiting** | Per-user limits via SolidCache |
| **Input Validation** | Strong parameters, type coercion |
| **SQL Injection** | ActiveRecord parameterized queries |
| **Mass Assignment** | Explicit `permit` lists |

### Browser Security

| Measure | Implementation |
|---------|----------------|
| **One-Time Reveal** | Token shown only at creation, never recoverable |
| **Auto-Hide** | Token display hidden after 60 seconds |
| **Clipboard API** | Secure copy with fallback |
| **CSRF Protection** | Turbo handles automatically for web UI |
| **XSS Prevention** | Rails view helpers escape by default |

### Network Security

| Measure | Implementation |
|---------|----------------|
| **HTTPS Only** | Force SSL in production (`config.force_ssl = true`) |
| **CORS** | Whitelist allowed origins |
| **Content-Type** | Enforce `application/json` |
| **Security Headers** | CSP, X-Frame-Options via Rails defaults |

### CORS Configuration

```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch('API_CORS_ORIGINS', 'https://calcumake.com').split(',')

    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: false,
      max_age: 86400
  end
end
```

### Security Checklist

Before deployment:
- [ ] Verify tokens are never logged in plain text
- [ ] Test rate limiting under load
- [ ] Confirm HTTPS redirects work
- [ ] Validate CORS settings in staging
- [ ] Test token expiration behavior
- [ ] Verify cascade delete for user accounts
- [ ] Review audit log output format
- [ ] Penetration test authentication flow

---

## Summary

### Key Features

| Feature | Description |
|---------|-------------|
| **Token Auth** | Secure API tokens with SHA-256 hashing |
| **One-Time Reveal** | Tokens shown only at creation |
| **Expiration** | 30d/90d/1y options with renewal reminders |
| **Rate Limiting** | Tiered by subscription plan |
| **Caching** | SolidCache with automatic invalidation |
| **ViewComponents** | Testable, reusable UI components |
| **Turbo/Stimulus** | SPA-like experience without JavaScript build |

### Files to Create

```
app/
├── components/api_tokens/
│   ├── token_card_component.rb
│   ├── token_form_component.rb
│   └── token_reveal_component.rb
├── controllers/
│   ├── api/v1/base_controller.rb
│   ├── api/v1/*.rb (10 controllers)
│   └── api_tokens_controller.rb
├── javascript/controllers/
│   ├── api_token_controller.js
│   └── api_token_card_controller.js
├── models/api_token.rb
├── services/api/rate_limiter.rb
└── views/api_tokens/

config/
├── locales/en/api_tokens.yml
└── routes.rb (API namespace)

db/migrate/
└── [timestamp]_create_api_tokens.rb

test/
├── components/api_tokens/
├── controllers/api/v1/
└── models/api_token_test.rb
```

### Implementation Priority

1. **Week 1**: ApiToken model, migration, base controller
2. **Week 2**: Token UI (ViewComponents, Stimulus, Turbo)
3. **Week 3**: Core API endpoints (print_pricings, printers, filaments)
4. **Week 4**: Invoice endpoints, public calculator
5. **Week 5**: Testing, documentation, security audit

---

## Changelog

### v1.0.0 (Planned)
- Initial API release
- Full CRUD for all resources
- Token authentication
- Rate limiting
- Public calculator endpoint
