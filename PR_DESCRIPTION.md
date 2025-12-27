## Summary
This PR implements a complete REST API for CalcuMake with secure token-based authentication and full support for the new resin material type.

### Token Authentication System
- SHA-256 hashed API tokens with `cm_` prefix for easy identification
- One-time token reveal on creation (60-second auto-hide for security)
- Configurable expiration: 30 days, 90 days, 1 year, or never
- Token management UI at `/api_tokens` with Turbo Stream updates
- ViewComponents: `TokenCardComponent`, `TokenRevealComponent`, `TokenFormComponent`
- Profile page integration showing active token count

### API Endpoints (v1)

| Resource | Endpoints | Features |
|----------|-----------|----------|
| `/api/v1/me` | GET, PATCH | User profile, usage stats, data export |
| `/api/v1/printers` | CRUD | `material_technology` filter (fdm/resin) |
| `/api/v1/filaments` | CRUD + duplicate | Search, material_type filter |
| `/api/v1/resins` | CRUD + duplicate | Search, resin_type filter |
| `/api/v1/materials` | GET | Combined filaments + resins library |
| `/api/v1/clients` | CRUD | Search support |
| `/api/v1/print_pricings` | CRUD + duplicate | Nested plates with filaments/resins |
| `/api/v1/printer_profiles` | GET (public) | Browse pre-defined printer profiles |
| `/api/v1/health` | GET (public) | Load balancer health check |

### Material Technology Support
- Printers and plates now support `material_technology` enum (fdm/resin)
- Plates include `plate_resins` for resin prints alongside `plate_filaments` for FDM
- Print pricings calculate costs correctly for both material types
- API responses include proper relationships for both filaments and resins

## Test plan
- [ ] Run `bin/rails db:migrate` to create `api_tokens` table
- [ ] Create an API token via Profile → API Access → Manage Tokens
- [ ] Verify token is shown once and auto-hides after 60 seconds
- [ ] Test API authentication: `curl -H "Authorization: Bearer cm_xxx" /api/v1/me`
- [ ] Verify 401 response without token
- [ ] Test resin endpoints: `GET /api/v1/resins`
- [ ] Test materials endpoint with technology filter: `GET /api/v1/materials?technology=resin`
- [ ] Create print pricing with resin plate via API
- [ ] Run `bin/rails test` to verify all tests pass
