# CalcuMake API Design Documentation

## Overview

This document outlines the comprehensive REST API for CalcuMake, enabling third-party integrations, mobile apps, and automation workflows for 3D print cost management.

## Table of Contents

1. [Authentication](#authentication)
2. [API Versioning](#api-versioning)
3. [Response Format](#response-format)
4. [Error Handling](#error-handling)
5. [Rate Limiting](#rate-limiting)
6. [Endpoints](#endpoints)
7. [Implementation Plan](#implementation-plan)

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

### Routes Configuration

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    # Current user
    resource :me, controller: 'users', only: [:show, :update] do
      get :export
    end

    # API token management
    resources :api_tokens, only: [:index, :create, :destroy]

    # Core resources
    resources :print_pricings do
      member do
        post :duplicate
        patch :increment_times_printed
        patch :decrement_times_printed
      end
      resources :plates, only: [:index, :show]
      resources :invoices
    end

    resources :printers
    resources :filaments do
      member do
        post :duplicate
      end
    end
    resources :clients

    # Standalone invoice access
    resources :invoices, only: [:index, :show, :update, :destroy] do
      member do
        patch :mark_as_sent
        patch :mark_as_paid
        patch :mark_as_cancelled
      end
      resources :line_items, controller: 'invoice_line_items'
    end

    # Public calculator (no auth required)
    post :calculator, to: 'calculator#create'
  end
end
```

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

1. **Token Storage**: Never store plain tokens, use `BCrypt` or `Argon2` for digests
2. **Rate Limiting**: Prevent abuse with tiered limits
3. **Input Validation**: Sanitize all inputs, use strong parameters
4. **CORS**: Configure allowed origins for browser-based API access
5. **Logging**: Log API access without sensitive data (tokens, passwords)
6. **HTTPS Only**: Reject non-HTTPS requests in production

---

## Changelog

### v1.0.0 (Planned)
- Initial API release
- Full CRUD for all resources
- Token authentication
- Rate limiting
- Public calculator endpoint
