# CalcuMake MCP Server

**CalcuMake** exposes a [Model Context Protocol (MCP)](https://modelcontextprotocol.io) server that lets AI agents and automation tools interact with your 3D print project data.

- **MCP endpoint:** `POST /mcp`  
- **Protocol:** JSON-RPC 2.0, MCP version 2024-11-05  
- **Authentication:** Bearer token (OAuth 2.1 PKCE or manual API token)  
- **Tool schema (JSON):** `GET /mcp/schema`  
- **This document (Markdown):** `GET /docs/mcp/markdown`

---

## Quick Start

### Option A — Manual API Token (fastest)

1. Log in to CalcuMake and go to **[API Tokens](/api_tokens)**.
2. Create a token and copy the value (shown once).
3. Use it in every MCP request:

```http
POST /mcp
Authorization: Bearer cm_your_token_here
Content-Type: application/json

{
  "jsonrpc": "2.0",
  "method": "initialize",
  "params": {
    "protocolVersion": "2024-11-05",
    "clientInfo": { "name": "my-agent", "version": "1.0" }
  },
  "id": 1
}
```

### Option B — OAuth 2.1 PKCE (for applications)

Use this flow when building an app that needs users to grant access without sharing their token.

```
1. Redirect user to:
   GET /oauth/authorize
     ?response_type=code
     &client_id=mcp
     &redirect_uri=https://your-app.com/callback
     &code_challenge=<S256 hash of verifier>
     &code_challenge_method=S256
     &state=<random>

2. User logs in (any provider: Google, GitHub, email, etc.)
   and clicks "Allow Access".

3. Server redirects to:
   https://your-app.com/callback?code=<auth_code>&state=<state>

4. Exchange code for token:
   POST /oauth/token
   Content-Type: application/x-www-form-urlencoded

   grant_type=authorization_code
   &code=<auth_code>
   &redirect_uri=https://your-app.com/callback
   &client_id=mcp
   &code_verifier=<original verifier>

5. Response:
   { "access_token": "cm_...", "token_type": "bearer", "expires_in": 7776000 }
```

---

## OAuth 2.1 Discovery

Auto-discovery follows RFC 8414 and RFC 9728:

| Endpoint | Description |
|---|---|
| `GET /.well-known/oauth-protected-resource` | Points to authorization server |
| `GET /.well-known/oauth-authorization-server` | Full OAuth server metadata |

MCP clients that support auto-discovery will find these automatically when they receive a `401` response from `/mcp`.

**Constraints:**
- `client_id` must be `"mcp"` (no registration required)
- `redirect_uri` must be HTTPS or `http://localhost/*`
- PKCE (`S256`) is required — no client secret needed
- Codes expire in **10 minutes** and are single-use

---

## MCP Session Flow

```
Client                          CalcuMake MCP
  |                                   |
  |-- POST /mcp (initialize) -------> |  Returns server info + capabilities
  |<- 200 {result: {protocolVersion}} |
  |                                   |
  |-- POST /mcp (notifications/init)  |  Notification — no response
  |                                   |
  |-- POST /mcp (tools/list) -------> |  Returns tool definitions
  |<- 200 {result: {tools: [...]}}    |
  |                                   |
  |-- POST /mcp (tools/call) -------> |  Executes a tool
  |<- 200 {result: {content: [...]}}  |
```

---

## Available Tools

All tools except `health_check` and `list_printer_profiles` require authentication.

### health_check

Check server health. No authentication required.

```json
{ "name": "health_check", "arguments": {} }
```

Returns: `{ "status": "ok", "service": "CalcuMake MCP", "timestamp": "..." }`

---

### get_profile

Get the authenticated user's profile.

```json
{ "name": "get_profile", "arguments": {} }
```

Returns: `{ "id": 1, "email": "...", "default_currency": "USD", "plan": "free", "locale": "en" }`

---

### list_printers

List the user's 3D printers.

| Argument | Type | Description |
|---|---|---|
| `technology` | string (fdm/resin) | Filter by printing technology |
| `page` | integer | Page number (default: 1) |
| `per_page` | integer | Items per page (default: 20, max: 100) |

Returns: `{ "data": [...], "meta": { "total": 5, "page": 1, "per_page": 20 } }`

---

### get_printer

Get a specific printer by ID.

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | integer | ✓ | Printer ID |

---

### create_printer

Create a new printer.

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | ✓ | Printer name |
| `manufacturer` | string | ✓ | Manufacturer/brand |
| `material_technology` | string (fdm/resin) | ✓ | Printing technology |
| `power_consumption` | number | ✓ | Power in watts |
| `cost` | number | ✓ | Purchase cost |
| `payoff_goal_years` | number | ✓ | Years to pay off |
| `daily_usage_hours` | number | ✓ | Average daily usage |
| `repair_cost_percentage` | number | | Annual repair cost % |
| `notes` | string | | Optional notes |

---

### update_printer

Update an existing printer.

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | integer | ✓ | Printer ID |
| (any field from create_printer) | | | Only provided fields are updated |

---

### delete_printer

Delete a printer by ID.

| Argument | Type | Required |
|---|---|---|
| `id` | integer | ✓ |

Returns: `{ "deleted": true, "id": 5 }`

---

### list_filaments

List the user's filaments.

| Argument | Type | Description |
|---|---|---|
| `q` | string | Search by name or brand |
| `material_type` | string | Filter by type (PLA, ABS, PETG, …) |
| `page` | integer | Page number |
| `per_page` | integer | Items per page (max 100) |

---

### get_filament

Get a specific filament.

| Argument | Type | Required |
|---|---|---|
| `id` | integer | ✓ |

---

### create_filament

Create a new filament.

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | ✓ | Filament name |
| `brand` | string | ✓ | Brand/manufacturer |
| `material_type` | string | ✓ | e.g. PLA, ABS, PETG |
| `color` | string | | Color name |
| `diameter` | number | | Diameter in mm (default 1.75) |
| `spool_weight` | number | | Spool weight in grams |
| `spool_price` | number | | Spool price |
| `notes` | string | | Optional notes |

---

### list_clients

List the user's clients.

| Argument | Type | Description |
|---|---|---|
| `q` | string | Search by name, email, or company |
| `page` | integer | Page number |
| `per_page` | integer | Items per page (max 100) |

---

### get_client

Get a specific client.

| Argument | Type | Required |
|---|---|---|
| `id` | integer | ✓ |

---

### create_client

Create a new client.

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | ✓ | Client name |
| `email` | string | | Email address |
| `phone` | string | | Phone number |
| `company_name` | string | | Company name |
| `address` | string | | Mailing address |
| `tax_id` | string | | Tax ID / VAT number |
| `notes` | string | | Optional notes |

---

### list_print_pricings

List the user's print pricing jobs.

| Argument | Type | Description |
|---|---|---|
| `q` | string | Search by job name |
| `page` | integer | Page number |
| `per_page` | integer | Items per page (max 100) |

Returns summary data (no plates). Use `get_print_pricing` for full detail.

---

### get_print_pricing

Get full details of a print pricing job including all plates and materials.

| Argument | Type | Required |
|---|---|---|
| `id` | integer | ✓ |

Returns: job details + `plates` array with filament/resin breakdown and costs.

---

### list_printer_profiles

List the public printer profile library. No authentication required.

| Argument | Type | Description |
|---|---|---|
| `page` | integer | Page number |
| `per_page` | integer | Items per page (max 100) |

---

## Error Handling

### JSON-RPC errors (transport/protocol errors)

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32001,
    "message": "Authentication required. Obtain a Bearer token via /api_tokens or the OAuth flow at /oauth/authorize."
  }
}
```

| Code | Meaning |
|---|---|
| -32700 | Parse error — invalid JSON |
| -32601 | Method not found |
| -32602 | Invalid params |
| -32603 | Internal error |
| -32001 | Authentication required |

### Tool errors (application-level errors)

When a tool itself fails, the response has HTTP 200 but `isError: true`:

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "result": {
    "content": [{ "type": "text", "text": "Error: Resource not found" }],
    "isError": true
  }
}
```

---

## Token Management

Tokens issued via OAuth are standard API tokens. You can manage them at `/api_tokens`:

- **List tokens:** `GET /api_tokens` (web UI)
- **Revoke via OAuth:** `POST /oauth/revoke` with `token=cm_...`
- **Revoke via API:** `DELETE /api/v1/api_tokens/:id`

Tokens expire in 90 days by default. The OAuth flow creates tokens named `"MCP OAuth (mcp)"`.

---

## Claude Desktop / claude_mcp_settings.json

To use with Claude Desktop, add to your MCP settings:

```json
{
  "mcpServers": {
    "calcumake": {
      "url": "https://calcumake.com/mcp",
      "transport": "http",
      "headers": {
        "Authorization": "Bearer cm_your_token_here"
      }
    }
  }
}
```

---

## Example: Full Session

```bash
# 1. Initialize
curl -X POST https://calcumake.com/mcp \
  -H "Authorization: Bearer cm_your_token" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","clientInfo":{"name":"curl","version":"1.0"}},"id":1}'

# 2. List tools
curl -X POST https://calcumake.com/mcp \
  -H "Authorization: Bearer cm_your_token" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":2}'

# 3. Call a tool
curl -X POST https://calcumake.com/mcp \
  -H "Authorization: Bearer cm_your_token" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"list_printers","arguments":{"technology":"fdm"}},"id":3}'

# 4. Get JSON Schema (no auth required)
curl https://calcumake.com/mcp/schema

# 5. Get this documentation as Markdown (no auth required)
curl https://calcumake.com/docs/mcp/markdown
```

---

## Security Notes

- All tokens use SHA-256 hashed storage — plain tokens are never logged or persisted.
- PKCE is mandatory for the OAuth flow (no client secrets).
- API tokens are scoped to a single user; cross-user access is not possible.
- Tokens can be revoked at any time from `/api_tokens`.

---

*© 2025 株式会社モアブ (MOAB Co., Ltd.) — [CalcuMake](https://calcumake.com)*
