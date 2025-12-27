# January 2025 Update: REST API Launch & Developer Tools

**Author:** CalcuMake Team
**Published:** January 15, 2025
**Featured:** Yes

---

## Excerpt

CalcuMake now offers a comprehensive REST API! Build custom integrations, automate your 3D printing workflow, and connect CalcuMake with your existing tools. Plus: improved API token management and enhanced system stability.

---

## What's New in January 2025

We're thrilled to announce the launch of the CalcuMake REST API—our most requested feature! This update empowers developers to integrate CalcuMake's powerful pricing calculations into their own applications, automation scripts, and business workflows.

## CalcuMake REST API v1

Build powerful 3D printing workflow integrations with our comprehensive, production-ready REST API.

### 50+ Endpoints Across All Resources

The API provides full programmatic access to all CalcuMake features:

**Print Pricings (8 endpoints)**
- List, create, view, update, and delete pricing calculations
- Duplicate existing calculations
- Increment/decrement times printed counter
- Full multi-plate support with nested relationships

**Printers (5 endpoints)**
- Manage your printer inventory
- Retrieve specifications and power consumption data
- Track printer costs and payoff calculations

**Materials (12 endpoints)**
- **Filaments**: Complete CRUD operations plus duplication
- **Resins**: Full management for resin printing materials
- **Unified Materials Library**: Browse all materials in one request

**Clients (5 endpoints)**
- Customer management and tracking
- Link clients to pricing calculations and invoices

**User Management (3 endpoints)**
- Get and update user profile
- Export user data (GDPR compliance)
- Usage statistics and analytics

**API Tokens (3 endpoints)**
- List active tokens
- Create new tokens with expiration
- Revoke tokens securely

### RESTful Design with JSON Responses

The API follows REST best practices:

- **Standard HTTP methods**: GET, POST, PATCH, DELETE
- **JSON request/response format**: Clean, predictable structure
- **Proper status codes**: 200, 201, 400, 401, 404, 422, 500
- **Bearer token authentication**: Secure, industry-standard approach
- **Pagination support**: Handle large datasets efficiently

### Comprehensive API Documentation

We've created a complete reference guide at [/api-documentation](/api-documentation):

**Getting Started Guide**
- Base URL and endpoint structure
- Quick examples to test the API
- Authentication setup walkthrough

**Code Examples in 3 Languages**
- **cURL**: Quick command-line testing
- **JavaScript (Node.js)**: Modern async/await examples
- **Ruby**: Native Rails-friendly examples

**Complete Endpoint Reference**
- Detailed descriptions for all 50+ endpoints
- Request parameter tables
- Response format examples
- Error handling documentation

**Authentication Guide**
- How to create API tokens
- Bearer token format and usage
- Security best practices

### Syntax Highlighting & Interactive Tabs

The documentation features:
- Prism.js syntax highlighting for all code examples
- Tab-based switching between languages
- Copy-to-clipboard functionality (coming in Phase 2)
- Responsive design for mobile and desktop

### Accessible from Navbar

Find the API documentation easily:
1. Click **Help** in the navbar
2. Navigate to **Developer** section
- Select **API Documentation**

## Improved API Token Management

We've completely overhauled the API token creation and management experience.

### One-Time Token Display

**Security-First Design:**
- API tokens are displayed **only once** immediately after creation
- Tokens are SHA-256 hashed before storage
- Plain text tokens never appear again after initial display
- Clear warning prompts users to copy the token

**Better User Experience:**
- Token appears in a highlighted warning card
- Automatic copy-to-clipboard button
- Visual indicators that this is a one-time view
- Clear instructions on token storage

### Fixed Toast Notifications

**Consistent Notification System:**
- Auto-dismiss after 5 seconds
- Manual close button with ✕ icon
- No more duplicate or malformed toasts
- Proper Stimulus controller integration

**Session-Based Token Storage:**
- Tokens stored in session (not flash) to prevent toast rendering
- Only the success message shows as a toast
- Cleaner, less noisy user interface

### Streamlined Creation Flow

**Redirect-Based Pattern:**
- Create token → redirect to tokens list
- Token revealed immediately on the index page
- No Turbo Stream complexity
- More predictable and reliable

**Updated Tests:**
- All 24 API token tests passing
- Comprehensive coverage of new flow
- Tests verify session storage and one-time display

## System Stability Improvements

We've made several behind-the-scenes improvements to enhance reliability and maintainability.

### Cleaned Up Debug Logging

**Removed 22 console.log statements** across JavaScript controllers:
- `toast_controller.js`: 5 debug logs removed
- `modal_controller.js`: 4 form submission logs removed
- `pdf_generator_controller.js`: 2 generation logs removed
- `pwa_install_controller.js`: 3 install flow logs removed
- `advanced_calculator_controller.js`: Connection log removed
- `modal_link_controller.js`: Modal dispatch log removed
- `locale_suggestion_controller.js`: 2 error logs removed

**Preserved Important Logging:**
- `console.error()` and `console.warn()` kept for production errors
- Reduced browser console noise
- Cleaner debugging experience for developers

### Test Suite Enhancements

**Image Upload Tests:**
- Fixed file input selectors to accept all image types
- Updated error container visibility checks
- Validates company logo upload on profile page

**PDF Generator Tests:**
- Fixed date assertion flexibility (handles multiple formats)
- Tests validate PDF generation on invoice pages
- Critical features now have complete system test coverage

**Overall Test Health:**
- **1,503 Rails tests** passing (0 failures, 0 errors)
- **44 Jest tests** for JavaScript mixins
- All tests run in ~4.5 seconds
- 100% passing rate maintained

## Translation & Internationalization

The API documentation is fully translatable and ready for our 7-language system:

**Supported Languages:**
- English (en)
- Japanese (ja)
- Spanish (es)
- French (fr)
- Arabic (ar)
- Hindi (hi)
- Simplified Chinese (zh-CN)

**Automated Translation:**
- English source file created with 100+ translation keys
- Automated translation via OpenRouter API (Gemini 2.0 Flash)
- Translations run automatically during deployment
- No manual translation work required

## API Usage Examples

Here are some quick examples to get you started:

### List All Print Pricings

```bash
curl https://calcumake.com/api/v1/print_pricings \
  -H "Authorization: Bearer YOUR_API_TOKEN"
```

```javascript
const response = await fetch('https://calcumake.com/api/v1/print_pricings', {
  headers: {
    'Authorization': 'Bearer YOUR_API_TOKEN'
  }
});
const data = await response.json();
```

### Create a New Printer

```bash
curl https://calcumake.com/api/v1/printers \
  -X POST \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "printer": {
      "name": "Bambu Lab X1 Carbon",
      "power_consumption": 350,
      "material_technology": "fdm"
    }
  }'
```

### Get Usage Statistics

```bash
curl https://calcumake.com/api/v1/me/usage \
  -H "Authorization: Bearer YOUR_API_TOKEN"
```

## Try It Now

The API and all improvements are available immediately to all CalcuMake users:

### Get Started with the API
1. **[Create an API Token](/api_tokens/new)** - Generate your first token
2. **[Read the Documentation](/api-documentation)** - Complete reference guide
3. **[Test the Health Endpoint](https://calcumake.com/api/v1/health)** - No auth required!

### Explore the Features
- **[View Your API Tokens](/api_tokens)** - Manage active tokens
- **[Check API Status](/api-documentation#getting-started)** - Get the base URL
- **[Browse Code Examples](/api-documentation#authentication)** - See implementation patterns

## What's Next?

We're already working on Phase 2 enhancements for the API:

**Interactive Documentation Features:**
- Copy-to-clipboard for all code examples
- Smooth scroll navigation
- Active section highlighting in sidebar
- Tab persistence across page loads

**Additional Endpoints:**
- Invoice management API
- Plate-level operations
- Batch operations for efficiency
- Webhook support for real-time notifications

**Developer Tools:**
- API client libraries (Ruby, JavaScript, Python)
- Postman collection
- OpenAPI/Swagger specification
- Rate limiting and usage analytics

## Need Help?

Have questions about the API or need assistance integrating CalcuMake into your workflow?

- **[Read the Documentation](/api-documentation)** - Comprehensive reference
- **[Contact Support](/support)** - Email us at cody@moab.jp
- **[Report Issues](https://github.com/cmbaldwin/moab-printing/issues)** - GitHub Issues

We're excited to see what you build with the CalcuMake API!

---

## Technical Details

For developers interested in the implementation:

**Architecture:**
- Rails 8.1.1 API controllers with versioning (`/api/v1/`)
- JSON:API-compliant response format
- Bearer token authentication via `ApiToken` model
- SHA-256 token hashing for security
- Comprehensive test coverage (1,503+ tests)

**Technologies:**
- Prism.js for syntax highlighting (CDN)
- Bootstrap 5 tabs for code examples
- Stimulus controllers for interactivity
- Turbo for SPA-like navigation
- I18n with automated translation

**Performance:**
- Sticky sidebar navigation (CSS position: sticky)
- Responsive design with mobile optimization
- CDN-loaded syntax highlighting
- Minimal JavaScript footprint

---

## SEO Metadata

**Meta Description:** CalcuMake January 2025 update: Launch of comprehensive REST API with 50+ endpoints, improved API token management, developer documentation, and enhanced system stability.

**Meta Keywords:** calcumake api, rest api, 3d printing api, developer tools, api documentation, print pricing api, automation, integration, api tokens
