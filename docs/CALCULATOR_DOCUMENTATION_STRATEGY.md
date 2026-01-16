# Calculator Documentation Strategy

**Date:** 2026-01-16
**Purpose:** Comprehensive documentation plan for CalcuMake's maker calculator suite

## Overview

CalcuMake's calculator documentation follows a **dual-track approach**:

1. **Web Documentation** - User-facing, SEO-optimized guides and interfaces
2. **Markdown Documentation** - Developer-focused API reference and code examples

This strategy maximizes both user engagement and developer adoption.

---

## Web Documentation Structure

### 1. Calculator Hub Page

**Route:** `/calculators`
**Purpose:** Central directory for all calculators

**Content Sections:**
```
├── Hero Section
│   ├── Headline: "Free Maker Calculators"
│   ├── Subheading: "26+ professional-grade calculators for woodworking, electronics, metalworking, and more"
│   └── Search bar: Find calculators by keyword
│
├── Featured Calculators (Phase 1 - 7 calculators)
│   └── Grid of cards with icon, name, description, "Calculate" CTA
│
├── Calculator Categories
│   ├── Woodworking (3 calculators)
│   ├── Electronics & PCB (4 calculators)
│   ├── Metalworking (2 calculators)
│   ├── Welding (1 calculator)
│   └── Coming Soon (Phase 2 & 3)
│
├── Why Use Our Calculators?
│   ├── Free & Open API
│   ├── No signup required
│   ├── Mobile-friendly
│   ├── Save calculations (with account)
│   └── Export to PDF/CSV
│
├── For Developers
│   ├── API Documentation link
│   ├── Code examples
│   └── GitHub repository
│
└── CTA: Create Free Account
```

**SEO Optimization:**
- **Title:** "Free Maker Calculators - Woodworking, Electronics, Metalworking | CalcuMake"
- **Meta Description:** "26+ free professional maker calculators. Board foot, LED resistor, wire gauge, metal weight, welding, and more. No signup required. Open API available."
- **Structured Data:** Collection schema with individual calculator listings
- **Keywords:** maker calculators, woodworking calculators, electronics calculators, metalworking tools

---

### 2. Individual Calculator Pages

**Route Pattern:** `/calculators/{calculator-name}`
**Example:** `/calculators/board-foot`

**Page Layout:**
```
┌─────────────────────────────────────────────────┐
│ Navigation Bar                                  │
├─────────────────────────────────────────────────┤
│ Breadcrumb: Home > Calculators > Board Foot    │
├─────────────────────────────────────────────────┤
│                                                 │
│  [Calculator Interface - Left Column]          │
│  • Input fields                                 │
│  • Real-time results                            │
│  • Export buttons (PDF, CSV)                    │
│  • Save/Share buttons                           │
│                                                 │
│  [Educational Content - Right Column]           │
│  • What is a board foot?                        │
│  • How to use this calculator                   │
│  • Formula explanation                          │
│  • Common use cases                             │
│  • Quick reference table                        │
│                                                 │
├─────────────────────────────────────────────────┤
│ Below-fold Content (SEO Rich)                   │
│                                                 │
│ ▼ Detailed Guide                                │
│   • Step-by-step instructions                   │
│   • Visual examples with images                 │
│   • Video tutorial (embedded YouTube)           │
│                                                 │
│ ▼ Practical Examples                            │
│   • Example 1: Hardwood flooring project        │
│   • Example 2: Cabinet building                 │
│   • Example 3: Furniture construction           │
│                                                 │
│ ▼ Formula & Math                                │
│   • Mathematical formula explanation            │
│   • Unit conversions                            │
│   • Related calculations                        │
│                                                 │
│ ▼ FAQ Section                                   │
│   • 5-10 common questions with answers          │
│   • Schema markup for rich snippets             │
│                                                 │
│ ▼ Related Calculators                           │
│   • Lumber Calculator                           │
│   • Lumber Weight Calculator                    │
│   • Wood Cost Estimator                         │
│                                                 │
│ ▼ For Developers                                │
│   • API endpoint documentation                  │
│   • Code examples (cURL, JS, Python)            │
│   • Link to full API docs                       │
│                                                 │
│ ▼ CTA: Create Free Account                      │
│   • Save your calculations                      │
│   • Access calculation history                  │
│   • Remove rate limits                          │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Calculator Interface Design:**

```html
<!-- Calculator Card Component -->
<div class="calculator-card">
  <div class="calculator-header">
    <h1>Board Foot Calculator</h1>
    <p class="subtitle">Calculate lumber volume in board feet</p>
  </div>

  <div class="calculator-body">
    <!-- Input Section -->
    <div class="input-section">
      <div class="form-group">
        <label>Length
          <span class="unit-toggle">[feet | meters]</span>
        </label>
        <input type="number" name="length" step="0.01" min="0" />
        <small class="help-text">Length of the board</small>
      </div>

      <div class="form-group">
        <label>Width <span class="unit">(inches)</span></label>
        <input type="number" name="width" step="0.01" min="0" />
      </div>

      <div class="form-group">
        <label>Thickness <span class="unit">(inches)</span></label>
        <input type="number" name="thickness" step="0.01" min="0" />
      </div>

      <div class="form-group">
        <label>Quantity <span class="optional">(optional)</span></label>
        <input type="number" name="quantity" value="1" min="1" />
      </div>

      <div class="unit-system-toggle">
        <label>
          <input type="radio" name="units" value="imperial" checked> Imperial
        </label>
        <label>
          <input type="radio" name="units" value="metric"> Metric
        </label>
      </div>
    </div>

    <!-- Results Section -->
    <div class="results-section">
      <h3>Results</h3>

      <div class="result-item primary">
        <span class="label">Total Board Feet:</span>
        <span class="value" data-target="boardFeet">—</span>
      </div>

      <div class="result-item">
        <span class="label">Cubic Feet:</span>
        <span class="value" data-target="cubicFeet">—</span>
      </div>

      <div class="result-item">
        <span class="label">Cubic Meters:</span>
        <span class="value" data-target="cubicMeters">—</span>
      </div>

      <div class="calculation-info">
        <small>Last calculated: <span data-target="timestamp">—</span></small>
      </div>
    </div>

    <!-- Actions -->
    <div class="calculator-actions">
      <button class="btn btn-primary" data-action="exportPDF">
        <i class="icon-pdf"></i> Export PDF
      </button>
      <button class="btn btn-secondary" data-action="exportCSV">
        <i class="icon-csv"></i> Export CSV
      </button>
      <button class="btn btn-secondary" data-action="share">
        <i class="icon-share"></i> Share
      </button>
      <button class="btn btn-secondary" data-action="save">
        <i class="icon-save"></i> Save
      </button>
    </div>
  </div>

  <!-- Formula Display (collapsible) -->
  <div class="formula-display">
    <button class="collapse-toggle">Show Formula</button>
    <div class="formula-content hidden">
      <code>
        board_feet = (length_ft × width_in × thickness_in) / 12
      </code>
    </div>
  </div>
</div>
```

**SEO Elements for Each Calculator Page:**

```html
<!-- Title Tag -->
<title>Board Foot Calculator - Free Lumber Volume Calculator | CalcuMake</title>

<!-- Meta Description -->
<meta name="description" content="Free board foot calculator. Calculate lumber volume in board feet from length, width, and thickness. Supports metric and imperial units. Export to PDF. No signup required.">

<!-- Canonical URL -->
<link rel="canonical" href="https://calcumake.com/calculators/board-foot">

<!-- Open Graph -->
<meta property="og:title" content="Board Foot Calculator - Free Lumber Volume Calculator">
<meta property="og:description" content="Calculate lumber volume in board feet instantly. Free tool for woodworkers.">
<meta property="og:image" content="https://calcumake.com/images/calculators/board-foot-og.png">
<meta property="og:url" content="https://calcumake.com/calculators/board-foot">

<!-- Structured Data (SoftwareApplication) -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "Board Foot Calculator",
  "applicationCategory": "UtilitiesApplication",
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "USD"
  },
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.8",
    "reviewCount": "234"
  }
}
</script>

<!-- FAQ Schema -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [{
    "@type": "Question",
    "name": "What is a board foot?",
    "acceptedAnswer": {
      "@type": "Answer",
      "text": "A board foot is a unit of measurement for lumber volume..."
    }
  }]
}
</script>
```

---

### 3. Calculator Guide Pages

**Route Pattern:** `/calculators/{calculator-name}/guide`
**Example:** `/calculators/board-foot/guide`

**Purpose:** Long-form educational content for SEO and user education

**Content Structure:**
```markdown
# Complete Guide to Board Foot Calculations

## Table of Contents
1. What is a Board Foot?
2. Why Use Board Feet?
3. How to Calculate Board Feet
4. Common Lumber Dimensions
5. Board Foot vs Linear Foot
6. Practical Examples
7. Tips for Buying Lumber
8. Frequently Asked Questions

## 1. What is a Board Foot?

[1000+ words of educational content with images, diagrams, and examples]

## 2. Why Use Board Feet?

[Historical context, industry standards, practical reasons]

## 3. How to Calculate Board Feet

[Step-by-step tutorial with visual examples]

[Interactive calculator embedded in article]

## 4. Common Lumber Dimensions

[Table of standard lumber sizes with board foot values]

| Nominal Size | Actual Size | Board Feet per Linear Foot |
|--------------|-------------|----------------------------|
| 1x4          | 3/4" x 3.5" | 0.219                      |
| 1x6          | 3/4" x 5.5" | 0.344                      |
| 2x4          | 1.5" x 3.5" | 0.438                      |
| 2x6          | 1.5" x 5.5" | 0.688                      |

## 5. Board Foot vs Linear Foot

[Comparison with examples showing when to use each]

## 6. Practical Examples

### Example 1: Hardwood Flooring Project
Calculate board feet needed for 500 sq ft room...

### Example 2: Building a Dining Table
Determine lumber requirements for tabletop...

### Example 3: Cabinet Construction
Estimate material costs for kitchen cabinets...

## 7. Tips for Buying Lumber

[Professional advice for lumber shopping]

## 8. Frequently Asked Questions

### How many board feet in a 2x4x8?
[Detailed answer with calculation]

### What's the difference between nominal and actual lumber dimensions?
[Explanation with examples]

[10+ more FAQ items]

---

## Try Our Board Foot Calculator

[CTA button linking to calculator]

## Related Calculators
- Lumber Calculator
- Lumber Weight Calculator
- Wood Cost Estimator

## For Developers
API documentation for integrating board foot calculations...
```

**SEO Strategy for Guides:**
- **Target Long-Tail Keywords:** "how to calculate board feet", "board foot formula", "board feet vs linear feet"
- **Internal Linking:** Link between calculator, guide, and related content
- **External Linking:** Link to authoritative sources (Wikipedia, lumber industry sites)
- **Rich Media:** Images, diagrams, videos to increase engagement
- **Long-Form Content:** 2000-3000 words for comprehensive coverage
- **FAQ Section:** Target featured snippets

---

### 4. API Documentation Pages

**Route:** `/calculators/{calculator-name}/api-docs`
**Example:** `/calculators/board-foot/api-docs`

**Purpose:** Developer-focused API documentation embedded in web interface

**Layout:**
```
┌─────────────────────────────────────────────────┐
│ Navigation: Docs | Guides | API | Examples      │
├─────────────────────────────────────────────────┤
│                                                 │
│ [Left Sidebar]           [Main Content]         │
│                                                 │
│ Overview                 # Board Foot API       │
│ ├─ Introduction                                 │
│ ├─ Authentication        ## Endpoint            │
│ └─ Quick Start           POST /api/v1/...       │
│                                                 │
│ Calculators              ## Request             │
│ ├─ Board Foot            ```json                │
│ ├─ Lumber                { ... }                │
│ ├─ LED Resistor          ```                    │
│ └─ ...                                          │
│                          ## Response            │
│ Reference                ```json                │
│ ├─ Error Codes           { ... }                │
│ ├─ Rate Limits           ```                    │
│ └─ Changelog                                    │
│                          ## Code Examples       │
│ SDKs                     [Tabs: cURL | JS | Python]
│ ├─ JavaScript                                   │
│ ├─ Python                ```bash                │
│ └─ Ruby                  curl ...               │
│                          ```                    │
│                                                 │
│                          ## Try It Live         │
│                          [Interactive API tester]
│                                                 │
└─────────────────────────────────────────────────┘
```

**Interactive API Tester:**
```html
<div class="api-tester">
  <h3>Try It Live</h3>

  <div class="request-builder">
    <label>Request Body</label>
    <textarea class="code-editor" data-language="json">
{
  "calculator": {
    "length": 8,
    "width": 6,
    "thickness": 1,
    "quantity": 10
  }
}
    </textarea>

    <button class="btn btn-primary" data-action="sendRequest">
      Send Request
    </button>
  </div>

  <div class="response-viewer">
    <label>Response</label>
    <pre class="code-block" data-target="response">
      // Response will appear here
    </pre>

    <div class="response-meta">
      <span>Status: <span data-target="status">—</span></span>
      <span>Time: <span data-target="responseTime">—</span>ms</span>
    </div>
  </div>
</div>
```

---

## Markdown Documentation Structure

### File Organization

```
docs/
├── api/
│   ├── README.md                        # API Overview
│   ├── CALCULATOR_API_SPECIFICATION.md  # Complete API spec
│   ├── authentication.md                # Auth guide
│   ├── rate-limiting.md                 # Rate limits
│   ├── errors.md                        # Error reference
│   │
│   ├── calculators/
│   │   ├── README.md                    # Calculator index
│   │   ├── board-foot.md
│   │   ├── lumber.md
│   │   ├── led-resistor.md
│   │   ├── wire-gauge.md
│   │   ├── metal-weight.md
│   │   ├── welding.md
│   │   └── k-factor.md
│   │
│   └── examples/
│       ├── curl-examples.md
│       ├── javascript-examples.md
│       ├── python-examples.md
│       └── ruby-examples.md
│
├── calculators/
│   ├── README.md                        # Calculator hub
│   ├── board-foot.md                    # Calculator guide
│   ├── lumber.md
│   └── ...
│
└── guides/
    ├── getting-started.md
    ├── best-practices.md
    └── troubleshooting.md
```

---

### Markdown Template: Individual Calculator API Docs

**File:** `docs/api/calculators/board-foot.md`

````markdown
# Board Foot Calculator API

Calculate lumber volume in board feet from length, width, and thickness dimensions.

## Quick Reference

- **Endpoint:** `POST /api/v1/calculators/board-foot`
- **Authentication:** Not required (public endpoint)
- **Rate Limit:** 1000 requests/hour (public), 10,000/hour (authenticated)
- **Response Time:** ~50ms average

---

## Request

### Endpoint

```
POST https://calcumake.com/api/v1/calculators/board-foot
```

### Headers

```http
Content-Type: application/json
```

### Request Body

| Parameter  | Type   | Required | Description                           | Default |
|------------|--------|----------|---------------------------------------|---------|
| length     | number | Yes      | Length in feet (imperial) or meters   | —       |
| width      | number | Yes      | Width in inches (imperial) or cm      | —       |
| thickness  | number | Yes      | Thickness in inches (imperial) or cm  | —       |
| quantity   | number | No       | Number of pieces                      | 1       |
| units      | string | No       | Unit system: "imperial" or "metric"   | imperial|

### Validation Rules

- All dimensions must be positive numbers (> 0)
- `quantity` must be a positive integer
- `units` must be either "imperial" or "metric"

---

## Response

### Success Response (200 OK)

```json
{
  "inputs": {
    "length": 8,
    "width": 6,
    "thickness": 1,
    "quantity": 10,
    "units": "imperial"
  },
  "outputs": {
    "board_feet_per_piece": 4.0,
    "total_board_feet": 40.0,
    "cubic_feet": 3.333,
    "cubic_meters": 0.0944
  },
  "metadata": {
    "calculator_name": "board_foot_calculator",
    "calculation_time": "2026-01-16T12:34:56Z",
    "version": "1.0",
    "units": "imperial"
  }
}
```

### Error Response (422 Unprocessable Entity)

```json
{
  "error": "Validation failed",
  "details": {
    "length": ["must be greater than 0"],
    "width": ["must be greater than 0"]
  },
  "status": 422
}
```

---

## Code Examples

### cURL

```bash
curl -X POST https://calcumake.com/api/v1/calculators/board-foot \
  -H "Content-Type: application/json" \
  -d '{
    "calculator": {
      "length": 8,
      "width": 6,
      "thickness": 1,
      "quantity": 10
    }
  }'
```

### JavaScript (Fetch API)

```javascript
const calculateBoardFeet = async (length, width, thickness, quantity = 1) => {
  const response = await fetch('https://calcumake.com/api/v1/calculators/board-foot', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      calculator: { length, width, thickness, quantity }
    })
  });

  if (!response.ok) {
    throw new Error(`API error: ${response.statusText}`);
  }

  const result = await response.json();
  return result.outputs.total_board_feet;
};

// Usage
const boardFeet = await calculateBoardFeet(8, 6, 1, 10);
console.log(`Total: ${boardFeet} board feet`);
```

### JavaScript (Axios)

```javascript
const axios = require('axios');

async function calculateBoardFeet(dimensions) {
  try {
    const response = await axios.post(
      'https://calcumake.com/api/v1/calculators/board-foot',
      { calculator: dimensions }
    );

    return response.data.outputs;

  } catch (error) {
    if (error.response) {
      console.error('API Error:', error.response.data);
    } else {
      console.error('Network Error:', error.message);
    }
    throw error;
  }
}

// Usage
const result = await calculateBoardFeet({
  length: 8,
  width: 6,
  thickness: 1,
  quantity: 10
});
console.log(result);
```

### Python (requests)

```python
import requests

def calculate_board_feet(length, width, thickness, quantity=1):
    """Calculate board feet using CalcuMake API"""

    url = 'https://calcumake.com/api/v1/calculators/board-foot'
    payload = {
        'calculator': {
            'length': length,
            'width': width,
            'thickness': thickness,
            'quantity': quantity
        }
    }

    response = requests.post(url, json=payload)
    response.raise_for_status()

    return response.json()['outputs']['total_board_feet']

# Usage
board_feet = calculate_board_feet(8, 6, 1, 10)
print(f"Total: {board_feet} board feet")
```

### Ruby

```ruby
require 'net/http'
require 'json'

def calculate_board_feet(length, width, thickness, quantity = 1)
  uri = URI('https://calcumake.com/api/v1/calculators/board-foot')

  request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
  request.body = {
    calculator: {
      length: length,
      width: width,
      thickness: thickness,
      quantity: quantity
    }
  }.to_json

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  result = JSON.parse(response.body)
  result['outputs']['total_board_feet']
end

# Usage
board_feet = calculate_board_feet(8, 6, 1, 10)
puts "Total: #{board_feet} board feet"
```

---

## Use Cases

### Use Case 1: Lumber Purchase Calculator

Build a shopping cart that calculates total board feet:

```javascript
class LumberCart {
  constructor() {
    this.items = [];
  }

  async addItem(length, width, thickness, quantity) {
    const response = await fetch('https://calcumake.com/api/v1/calculators/board-foot', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        calculator: { length, width, thickness, quantity }
      })
    });

    const result = await response.json();

    this.items.push({
      dimensions: { length, width, thickness, quantity },
      board_feet: result.outputs.total_board_feet
    });

    return this.getTotalBoardFeet();
  }

  getTotalBoardFeet() {
    return this.items.reduce((sum, item) => sum + item.board_feet, 0);
  }
}

// Usage
const cart = new LumberCart();
await cart.addItem(8, 6, 1, 10);  // 40 BF
await cart.addItem(10, 8, 2, 5);  // 66.67 BF
console.log(`Total: ${cart.getTotalBoardFeet()} board feet`);
```

### Use Case 2: Batch Processing

Calculate board feet for multiple lumber pieces:

```python
import requests
import concurrent.futures

def calculate_single(dimensions):
    """Calculate board feet for a single piece"""
    response = requests.post(
        'https://calcumake.com/api/v1/calculators/board-foot',
        json={'calculator': dimensions}
    )
    return response.json()['outputs']['total_board_feet']

def calculate_batch(lumber_list):
    """Calculate board feet for multiple pieces in parallel"""
    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
        futures = [executor.submit(calculate_single, dims) for dims in lumber_list]
        results = [future.result() for future in concurrent.futures.as_completed(futures)]

    return sum(results)

# Usage
lumber = [
    {'length': 8, 'width': 6, 'thickness': 1, 'quantity': 10},
    {'length': 10, 'width': 8, 'thickness': 2, 'quantity': 5},
    {'length': 12, 'width': 4, 'thickness': 1, 'quantity': 20}
]

total = calculate_batch(lumber)
print(f"Total: {total} board feet")
```

---

## Formula

The board foot formula calculates volume normalized to a 1" x 12" x 12" board:

```
board_feet = (length_ft × width_in × thickness_in) / 12

total_board_feet = board_feet × quantity
```

**Example:**
- Length: 8 feet
- Width: 6 inches
- Thickness: 1 inch
- Quantity: 10

```
board_feet_per_piece = (8 × 6 × 1) / 12 = 4.0
total_board_feet = 4.0 × 10 = 40.0
```

---

## Related Calculators

- [Lumber Calculator](lumber.md) - Calculate volume, length, and cost
- [Lumber Weight Calculator](lumber-weight.md) - Calculate weight by wood type
- [Wood Cost Estimator](wood-cost.md) - Estimate project costs

---

## Support

- **API Documentation:** [Full API Reference](../CALCULATOR_API_SPECIFICATION.md)
- **Web Calculator:** [Try it online](https://calcumake.com/calculators/board-foot)
- **Issues:** [GitHub Issues](https://github.com/calcumake/api-feedback)
- **Email:** api@calcumake.com
````

---

## Content Generation Workflow

### 1. Calculator Implementation Phase

**Developer Tasks:**
- [ ] Build calculator service class
- [ ] Create API endpoint
- [ ] Build frontend UI
- [ ] Write unit tests
- [ ] Write integration tests
- [ ] Write system tests

**Documentation Tasks (Parallel):**
- [ ] Write markdown API reference
- [ ] Create code examples (cURL, JS, Python, Ruby)
- [ ] Write web API docs page
- [ ] Create calculator guide outline

### 2. Content Creation Phase

**Technical Writer Tasks:**
- [ ] Write comprehensive calculator guide (2000-3000 words)
- [ ] Create diagrams and visual examples
- [ ] Record video tutorial (5-10 minutes)
- [ ] Write FAQ section (10+ questions)
- [ ] Create comparison articles
- [ ] Write use case examples

**SEO Tasks:**
- [ ] Keyword research for calculator
- [ ] Optimize meta tags
- [ ] Add structured data markup
- [ ] Internal linking strategy
- [ ] Create shareable graphics

### 3. Review & Publishing Phase

**Review Checklist:**
- [ ] Technical accuracy verified
- [ ] Code examples tested
- [ ] SEO optimization completed
- [ ] Accessibility audit passed
- [ ] Mobile responsiveness verified
- [ ] Cross-browser testing completed
- [ ] Translations ready (if applicable)

**Publishing:**
- [ ] Deploy to production
- [ ] Add to sitemap
- [ ] Submit to Google Search Console
- [ ] Announce on social media
- [ ] Share in relevant communities

---

## Documentation Maintenance

### Regular Updates

**Monthly:**
- Review analytics for popular calculators
- Update examples based on user feedback
- Add new use cases from community
- Fix reported documentation bugs

**Quarterly:**
- SEO performance review
- Content refresh for outdated information
- Add new code examples for trending languages
- Update video tutorials if UI changed

**Annually:**
- Comprehensive content audit
- Major SEO optimization
- Refresh all screenshots and visuals
- Survey users for improvement suggestions

---

## Success Metrics

### Web Documentation KPIs

**Traffic Metrics:**
- Page views per calculator
- Average time on page
- Bounce rate
- Pages per session

**Engagement Metrics:**
- Calculator usage per page view
- Export actions (PDF/CSV)
- Account signups from calculator pages
- API documentation views

**SEO Metrics:**
- Organic traffic growth
- Keyword rankings (target: top 10 for primary keywords)
- Backlinks acquired
- Featured snippet appearances

### Markdown Documentation KPIs

**GitHub Metrics:**
- Documentation page views
- Stars/forks of example repositories
- Issues/questions filed
- Community contributions (PRs)

**API Adoption:**
- API calls per calculator endpoint
- Unique API users
- SDK downloads
- Community-built integrations

---

## Tools & Technologies

### Web Documentation

**CMS/Platform:**
- Rails views with ERB templates
- Markdown support via `redcarpet` gem
- Syntax highlighting via `rouge` gem

**SEO Tools:**
- Google Search Console
- Google Analytics 4
- Ahrefs/SEMrush for keyword research
- Schema markup validator

**Media Creation:**
- Figma for diagrams and graphics
- Loom for video tutorials
- Canva for social media graphics

### Markdown Documentation

**Editing:**
- VS Code with markdown extensions
- Markdown lint for consistency
- Prettier for formatting

**Hosting:**
- GitHub repository (public)
- GitHub Pages for rendered docs (optional)
- Synced to website via automated builds

**Code Examples:**
- Automated testing of code examples
- CI/CD validation before merge
- Version pinning for dependencies

---

## Translation Strategy (Future)

**Phase 1:** English only (initial launch)

**Phase 2:** Translate web calculator interfaces
- Japanese, Spanish, French (high-traffic languages)
- Automated translation with manual review
- Use existing CalcuMake translation infrastructure

**Phase 3:** Translate documentation
- API docs remain English (developer standard)
- Calculator guides translated to 7 languages
- SEO optimization for each language market

---

## Next Steps

1. **Approve documentation strategy** ✅
2. **Create documentation templates** - For reuse across all calculators
3. **Hire/assign content creators** - Technical writers, video creators
4. **Set up documentation infrastructure** - CMS, version control, deployment
5. **Begin Phase 1 documentation** - Board Foot Calculator as pilot
6. **Iterate and improve** - Based on user feedback and analytics

---

## Resources

- [MAKER_CALCULATORS_RESEARCH.md](MAKER_CALCULATORS_RESEARCH.md) - Calculator research
- [CALCULATOR_IMPLEMENTATION_PLAN.md](CALCULATOR_IMPLEMENTATION_PLAN.md) - Implementation roadmap
- [CALCULATOR_API_SPECIFICATION.md](api/CALCULATOR_API_SPECIFICATION.md) - Complete API spec
- [CalcuMake Translation System](AUTOMATED_TRANSLATION_SYSTEM.md) - Translation infrastructure
