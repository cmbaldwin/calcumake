# Calculator Implementation Plan

**Date:** 2026-01-16
**Status:** Planning Phase
**Related:** [MAKER_CALCULATORS_RESEARCH.md](MAKER_CALCULATORS_RESEARCH.md)

## Executive Summary

This plan outlines the implementation of 26 maker-oriented calculators for CalcuMake, organized into 3 phases based on user value, SEO potential, and development complexity. Each calculator will be available as both a web interface and a public API endpoint.

---

## Phase 1: Core Maker Tools (HIGH Priority)

**Target Launch:** 3 weeks from start
**Calculators:** 7 core tools
**Expected Traffic:** High - these are frequently searched terms

### 1.1 Board Foot Calculator
**Complexity:** LOW
**Development Time:** 2 days

**Inputs:**
- Length (feet)
- Width (inches)
- Thickness (inches)
- Quantity (optional, default: 1)

**Outputs:**
- Board feet (BF)
- Total volume (cubic feet)
- Total volume (cubic meters)

**Formula:**
```
board_feet = (length_ft × width_in × thickness_in) / 12
total_board_feet = board_feet × quantity
```

**API Endpoint:** `POST /api/v1/calculators/board-foot`

**SEO Keywords:** board foot calculator, lumber calculator, hardwood volume

---

### 1.2 Lumber Calculator
**Complexity:** LOW-MEDIUM
**Development Time:** 2 days

**Inputs:**
- Length (feet/meters)
- Width (inches/cm)
- Thickness (inches/cm)
- Quantity
- Price per unit (optional)

**Outputs:**
- Total volume (board feet, cubic feet, cubic meters)
- Total length (feet/meters)
- Total cost (if price provided)
- Weight estimate (if wood type selected)

**Formula:**
```
volume_cubic_feet = (length_ft × width_in × thickness_in × quantity) / 144
total_cost = volume × price_per_unit
```

**API Endpoint:** `POST /api/v1/calculators/lumber`

**SEO Keywords:** lumber calculator, wood volume calculator, lumber cost estimator

---

### 1.3 LED Resistor Calculator
**Complexity:** MEDIUM
**Development Time:** 3 days

**Inputs:**
- Supply voltage (V)
- LED forward voltage (V)
- LED forward current (mA)
- Number of LEDs
- Connection type (series/parallel)

**Outputs:**
- Required resistance (Ω)
- Nearest standard resistor value
- Power dissipation (W)
- Recommended resistor wattage (1/4W, 1/2W, 1W)

**Formulas:**
```
# Series connection
resistance = (supply_voltage - (led_voltage × num_leds)) / led_current

# Parallel connection
resistance = (supply_voltage - led_voltage) / (led_current × num_leds)

power = (supply_voltage - led_voltage) × led_current
```

**API Endpoint:** `POST /api/v1/calculators/led-resistor`

**SEO Keywords:** LED resistor calculator, LED current limiting resistor, Arduino LED

---

### 1.4 Wire Gauge Calculator
**Complexity:** MEDIUM
**Development Time:** 3 days

**Inputs:**
- Wire gauge (AWG or SWG)
- Wire standard (AWG/SWG)
- Wire material (copper, aluminum, etc.)
- Length (feet/meters) - optional

**Outputs:**
- Diameter (mm, inches, mils)
- Cross-sectional area (mm², circular mils)
- Resistance per unit length (Ω/km, Ω/1000ft)
- Total resistance (if length provided)
- Current carrying capacity (ampacity)

**Data Required:**
- AWG/SWG lookup tables
- Material resistivity values
- Ampacity tables (NEC standards)

**API Endpoint:** `POST /api/v1/calculators/wire-gauge`

**SEO Keywords:** wire gauge calculator, AWG calculator, wire size chart

---

### 1.5 Metal Weight Calculator
**Complexity:** MEDIUM-HIGH
**Development Time:** 4 days

**Inputs:**
- Shape (bar, plate, tube, angle, channel, I-beam)
- Material (steel, aluminum, brass, copper, stainless steel, etc.)
- Dimensions (varies by shape):
  - Bar: diameter/side length, length
  - Plate: length, width, thickness
  - Tube: outer diameter, wall thickness, length
  - Angle: leg sizes, thickness, length
  - etc.
- Quantity

**Outputs:**
- Weight per unit (kg, lbs)
- Total weight (kg, lbs, tons)
- Volume (cubic inches, cubic cm)
- Estimated cost (if price per kg/lb provided)

**Data Required:**
- Material density table
- Shape volume formulas

**API Endpoint:** `POST /api/v1/calculators/metal-weight`

**SEO Keywords:** metal weight calculator, steel weight calculator, aluminum weight

---

### 1.6 Welding Calculator
**Complexity:** HIGH
**Development Time:** 5 days

**Inputs:**
- Joint type (butt, fillet, corner, lap, edge)
- Weld type (groove, fillet)
- Material (steel type, aluminum, etc.)
- Base metal thickness (mm/inches)
- Weld dimensions:
  - Fillet: leg size
  - Groove: throat thickness, weld width
- Weld length (mm/inches)
- Applied load (N, lbs) - optional
- Factor of safety - optional

**Outputs:**
- Weld throat thickness
- Effective weld area (mm², in²)
- Allowable shear stress (MPa, psi)
- Maximum allowable load (N, lbs)
- Pass/fail status (if load provided)
- Electrode size recommendation
- Estimated weld time
- Filler metal required (lbs, kg)

**Formulas:**
```
# Fillet weld throat thickness
throat = leg_size × 0.707

# Effective area
area = throat × length

# Shear stress
shear_stress = load / area

# Compare to allowable stress for material
```

**API Endpoint:** `POST /api/v1/calculators/welding`

**SEO Keywords:** welding calculator, weld strength calculator, fillet weld size

---

### 1.7 K-Factor Calculator (Sheet Metal)
**Complexity:** MEDIUM
**Development Time:** 3 days

**Inputs:**
- Material type (mild steel, stainless, aluminum, etc.)
- Material thickness (mm/inches)
- Bend angle (degrees)
- Inside bend radius (mm/inches)
- Bend method (air bending, bottoming, coining) - optional

**Outputs:**
- K-Factor (ratio)
- Bend allowance (BA)
- Bend deduction (BD)
- Outside setback (OSSB)
- Flat pattern length

**Formulas:**
```
# K-factor typically ranges 0.3-0.5 depending on material and method
k_factor = distance_neutral_axis / material_thickness

# Bend allowance
BA = (π/180) × bend_angle × (inside_radius + (k_factor × thickness))

# Bend deduction
BD = 2 × (inside_radius + thickness) × tan(bend_angle/2) - BA

# Flat length
flat_length = leg1 + leg2 + BA
```

**Data Required:**
- K-factor lookup table by material and bend method
- Material properties

**API Endpoint:** `POST /api/v1/calculators/k-factor`

**SEO Keywords:** k-factor calculator, sheet metal bend allowance, flat pattern calculator

---

## Phase 2: Specialized Tools (MEDIUM Priority)

**Target Launch:** 4 weeks after Phase 1
**Calculators:** 11 specialized tools
**Expected Traffic:** Medium-High - niche but targeted

### Quick List:
1. Lumber Weight Calculator
2. Wire Size Calculator (current capacity)
3. PCB Impedance Calculator
4. PCB Trace Width Calculator
5. Concrete Cylinder Calculator
6. Concrete Column Calculator
7. Cement Calculator
8. Steel Plate Weight Calculator
9. Material Removal Rate Calculator
10. Spindle Speed Calculator
11. Fabric Calculator

**Details:** To be expanded in separate planning document

---

## Phase 3: Niche Tools (LOW Priority)

**Target Launch:** 3 weeks after Phase 2
**Calculators:** 8 niche tools
**Expected Traffic:** Medium - long-tail keywords

### Quick List:
1. Wire Resistance Calculator
2. PCB Trace Resistance Calculator
3. Hole Volume Calculator
4. Stone Weight Calculator
5. Gravel Calculator
6. Rivet Size Calculator
7. Cross-stitch Calculator
8. Quilt Backing Calculator

**Details:** To be expanded based on Phase 1/2 learnings

---

## Technical Architecture

### Frontend Components

**Unified Calculator Component Structure:**
```javascript
// app/javascript/controllers/calculator_base_controller.js
// Shared functionality for all calculators

export default class extends Controller {
  static targets = ["input", "output", "error"]

  connect() {
    this.loadState()
    this.setupAutoSave()
  }

  calculate() {
    // Implemented by child controllers
  }

  validate() {
    // Input validation
  }

  saveState() {
    // localStorage persistence
  }

  loadState() {
    // Restore from localStorage
  }

  exportPDF() {
    // PDF generation
  }

  exportCSV() {
    // CSV generation
  }
}
```

**Individual Calculator Controllers:**
```javascript
// app/javascript/controllers/calculators/board_foot_controller.js
import CalculatorBase from "../calculator_base_controller"

export default class extends CalculatorBase {
  calculate() {
    const length = parseFloat(this.inputTargets.find(i => i.name === 'length').value)
    const width = parseFloat(this.inputTargets.find(i => i.name === 'width').value)
    const thickness = parseFloat(this.inputTargets.find(i => i.name === 'thickness').value)
    const quantity = parseFloat(this.inputTargets.find(i => i.name === 'quantity').value) || 1

    if (this.validate([length, width, thickness])) {
      const boardFeet = (length * width * thickness * quantity) / 12
      this.displayResult({ boardFeet })
      this.saveState()
    }
  }
}
```

### Backend API Structure

**Base Calculator Service:**
```ruby
# app/services/calculators/base_calculator.rb
module Calculators
  class BaseCalculator
    include ActiveModel::Model
    include ActiveModel::Validations

    def calculate
      raise NotImplementedError
    end

    def to_json
      {
        inputs: inputs_hash,
        outputs: outputs_hash,
        metadata: metadata_hash
      }
    end

    private

    def inputs_hash
      # Return input values
    end

    def outputs_hash
      # Return calculated results
    end

    def metadata_hash
      {
        calculator_name: self.class.name.demodulize.underscore,
        calculation_time: Time.current,
        version: "1.0"
      }
    end
  end
end
```

**Individual Calculator Service:**
```ruby
# app/services/calculators/board_foot_calculator.rb
module Calculators
  class BoardFootCalculator < BaseCalculator
    attr_accessor :length, :width, :thickness, :quantity

    validates :length, :width, :thickness, numericality: { greater_than: 0 }
    validates :quantity, numericality: { greater_than: 0 }, allow_nil: true

    def initialize(attributes = {})
      @quantity = 1
      super
    end

    def calculate
      return unless valid?

      @board_feet = (length * width * thickness) / 12.0
      @total_board_feet = @board_feet * (quantity || 1)
      @cubic_feet = @total_board_feet / 12.0
      @cubic_meters = @cubic_feet * 0.0283168

      self
    end

    def outputs_hash
      {
        board_feet_per_piece: @board_feet&.round(3),
        total_board_feet: @total_board_feet&.round(3),
        cubic_feet: @cubic_feet&.round(4),
        cubic_meters: @cubic_meters&.round(4)
      }
    end
  end
end
```

**API Controller:**
```ruby
# app/controllers/api/v1/calculators_controller.rb
module Api
  module V1
    class CalculatorsController < ApiController
      # Public endpoint - no authentication required
      skip_before_action :authenticate_api_token!, only: [:calculate]

      def calculate
        calculator_class = "Calculators::#{params[:calculator_type].camelize}Calculator".constantize
        calculator = calculator_class.new(calculator_params)

        if calculator.calculate
          render json: calculator.to_json, status: :ok
        else
          render json: { errors: calculator.errors.full_messages }, status: :unprocessable_entity
        end
      rescue NameError
        render json: { error: "Calculator not found" }, status: :not_found
      end

      private

      def calculator_params
        # Permit all calculator-specific params
        params.require(:calculator).permit!
      end
    end
  end
end
```

### API Routes

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    # Public calculator endpoints
    post 'calculators/:calculator_type', to: 'calculators#calculate'

    # Or individual routes for each calculator
    post 'calculators/board-foot', to: 'calculators#board_foot'
    post 'calculators/lumber', to: 'calculators#lumber'
    post 'calculators/led-resistor', to: 'calculators#led_resistor'
    # ... etc
  end
end
```

### Database Models (if needed for history/analytics)

```ruby
# app/models/calculator_usage.rb
class CalculatorUsage < ApplicationRecord
  belongs_to :user, optional: true

  # Fields:
  # - calculator_type (string)
  # - inputs (jsonb)
  # - outputs (jsonb)
  # - ip_address (string)
  # - user_agent (string)
  # - created_at (timestamp)

  validates :calculator_type, presence: true
end
```

---

## Documentation Structure

### Web Documentation (Public Pages)

**Route Structure:**
```
/calculators                           # Calculator hub page
/calculators/board-foot               # Individual calculator page
/calculators/board-foot/guide         # How-to guide
/calculators/board-foot/api-docs      # API documentation
```

**Page Components:**
1. **Calculator Interface** - Interactive calculator form
2. **Description** - What it calculates and why it's useful
3. **Formula Explanation** - Educational content
4. **Examples** - Common use cases with sample calculations
5. **API Documentation** - Request/response examples
6. **Related Calculators** - Cross-links to similar tools
7. **CTA** - Sign up for saved calculations, history, etc.

### Markdown API Documentation

**File Structure:**
```
docs/api/
├── calculators/
│   ├── README.md                    # Overview of all calculators
│   ├── board-foot.md                # Board foot API docs
│   ├── lumber.md                    # Lumber API docs
│   ├── led-resistor.md              # LED resistor API docs
│   └── ...
└── examples/
    ├── curl-examples.md             # cURL examples
    ├── python-examples.md           # Python SDK examples
    └── javascript-examples.md       # JavaScript examples
```

**Sample API Doc Format:**
````markdown
# Board Foot Calculator API

## Endpoint

```
POST /api/v1/calculators/board-foot
```

## Authentication

Not required (public endpoint)

## Request Body

```json
{
  "calculator": {
    "length": 8,
    "width": 6,
    "thickness": 1,
    "quantity": 10
  }
}
```

## Response

```json
{
  "inputs": {
    "length": 8,
    "width": 6,
    "thickness": 1,
    "quantity": 10
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
    "version": "1.0"
  }
}
```

## Examples

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
const response = await fetch('https://calcumake.com/api/v1/calculators/board-foot', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    calculator: {
      length: 8,
      width: 6,
      thickness: 1,
      quantity: 10
    }
  })
});
const result = await response.json();
console.log(result.outputs.total_board_feet); // 40.0
```

### Python (requests)
```python
import requests

response = requests.post(
    'https://calcumake.com/api/v1/calculators/board-foot',
    json={
        'calculator': {
            'length': 8,
            'width': 6,
            'thickness': 1,
            'quantity': 10
        }
    }
)
result = response.json()
print(result['outputs']['total_board_feet'])  # 40.0
```
````

---

## SEO Strategy

### Content Marketing Plan

**For Each Calculator:**
1. **Landing Page** - Optimized for primary keyword
2. **How-to Guide** - Long-form educational content
3. **Use Case Articles** - Real-world application examples
4. **Comparison Articles** - vs manual calculation methods
5. **Video Tutorials** - YouTube embeds on calculator pages

**Example Article Series for Board Foot Calculator:**
- "How to Calculate Board Feet: Complete Guide for Woodworkers"
- "Board Feet vs Linear Feet: Understanding Lumber Measurements"
- "How to Estimate Lumber Costs for Woodworking Projects"
- "Common Lumber Dimensions and Board Foot Conversions"

### Structured Data (Schema.org)

```json
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
  },
  "description": "Free online board foot calculator for woodworkers. Calculate lumber volume in board feet instantly.",
  "featureList": [
    "Calculate board feet from dimensions",
    "Support for multiple pieces",
    "Metric and imperial units",
    "Export results to PDF",
    "Free API access"
  ]
}
```

---

## Analytics & Metrics

### Key Metrics to Track

**Usage Metrics:**
- Calculations per day (by calculator type)
- Unique users per calculator
- API calls per endpoint
- Average calculation time
- Error rate

**Conversion Metrics:**
- Calculator page → Sign up conversion rate
- Calculator usage → Free trial conversion rate
- API documentation views → API usage conversion rate

**SEO Metrics:**
- Organic traffic per calculator page
- Keyword rankings
- Backlinks acquired
- Time on page
- Bounce rate

### Implementation

```ruby
# app/models/calculator_analytics.rb
class CalculatorAnalytics
  def self.track_calculation(calculator_type, user_id: nil, ip_address: nil)
    CalculatorUsage.create!(
      calculator_type: calculator_type,
      user_id: user_id,
      ip_address: ip_address,
      user_agent: request.user_agent
    )

    # Also send to analytics service (Google Analytics, Mixpanel, etc.)
    Analytics.track('Calculator Used', {
      calculator_type: calculator_type,
      user_id: user_id,
      timestamp: Time.current
    })
  end
end
```

---

## Testing Strategy

### Unit Tests (Calculator Services)

```ruby
# test/services/calculators/board_foot_calculator_test.rb
require "test_helper"

class Calculators::BoardFootCalculatorTest < ActiveSupport::TestCase
  test "calculates board feet correctly" do
    calc = Calculators::BoardFootCalculator.new(
      length: 8,
      width: 6,
      thickness: 1,
      quantity: 1
    )

    calc.calculate

    assert_equal 4.0, calc.outputs_hash[:board_feet_per_piece]
    assert_equal 4.0, calc.outputs_hash[:total_board_feet]
  end

  test "validates positive numbers" do
    calc = Calculators::BoardFootCalculator.new(
      length: -8,
      width: 6,
      thickness: 1
    )

    refute calc.valid?
    assert_includes calc.errors[:length], "must be greater than 0"
  end

  test "handles multiple quantities" do
    calc = Calculators::BoardFootCalculator.new(
      length: 8,
      width: 6,
      thickness: 1,
      quantity: 10
    )

    calc.calculate

    assert_equal 40.0, calc.outputs_hash[:total_board_feet]
  end
end
```

### API Tests

```ruby
# test/controllers/api/v1/calculators_controller_test.rb
require "test_helper"

class Api::V1::CalculatorsControllerTest < ActionDispatch::IntegrationTest
  test "board foot calculation returns correct result" do
    post api_v1_calculators_path(calculator_type: 'board_foot'),
      params: {
        calculator: {
          length: 8,
          width: 6,
          thickness: 1,
          quantity: 10
        }
      },
      as: :json

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 40.0, json['outputs']['total_board_feet']
  end

  test "returns error for invalid calculator type" do
    post api_v1_calculators_path(calculator_type: 'nonexistent'),
      params: { calculator: {} },
      as: :json

    assert_response :not_found
  end

  test "validates required parameters" do
    post api_v1_calculators_path(calculator_type: 'board_foot'),
      params: { calculator: { length: -5 } },
      as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_includes json['errors'].join, 'greater than 0'
  end
end
```

### System Tests (JavaScript Calculator UI)

```ruby
# test/system/calculators/board_foot_test.rb
require "application_system_test_case"

class Calculators::BoardFootTest < ApplicationSystemTestCase
  test "calculates board feet in real time" do
    visit calculators_board_foot_path

    fill_in "Length (feet)", with: "8"
    fill_in "Width (inches)", with: "6"
    fill_in "Thickness (inches)", with: "1"
    fill_in "Quantity", with: "10"

    # Should calculate automatically (no submit button)
    assert_selector ".result-value", text: "40.0"
    assert_selector ".unit", text: "board feet"
  end

  test "exports to PDF" do
    visit calculators_board_foot_path

    fill_in "Length (feet)", with: "8"
    fill_in "Width (inches)", with: "6"
    fill_in "Thickness (inches)", with: "1"

    click_button "Export PDF"

    # Verify PDF download (implementation depends on test setup)
    assert_selector ".toast", text: "PDF downloaded successfully"
  end

  test "saves state to localStorage" do
    visit calculators_board_foot_path

    fill_in "Length (feet)", with: "8"
    fill_in "Width (inches)", with: "6"

    # Refresh page
    visit calculators_board_foot_path

    # Should restore previous values
    assert_field "Length (feet)", with: "8"
    assert_field "Width (inches)", with: "6"
  end
end
```

---

## Development Workflow

### 1. Planning Phase (1 week)
- [ ] Finalize calculator specifications
- [ ] Design mockups for all calculators
- [ ] Create data tables (material properties, lookup tables)
- [ ] Write comprehensive test cases

### 2. Foundation Phase (1 week)
- [ ] Build base calculator service class
- [ ] Build base calculator Stimulus controller
- [ ] Create API controller structure
- [ ] Set up calculator routes
- [ ] Create calculator index page
- [ ] Set up analytics tracking

### 3. Phase 1 Implementation (3 weeks)
**Week 1:** Board Foot, Lumber, LED Resistor
**Week 2:** Wire Gauge, Metal Weight
**Week 3:** Welding, K-Factor

For each calculator:
- [ ] Write service class with tests (TDD)
- [ ] Create API endpoint with tests
- [ ] Build frontend UI with Stimulus controller
- [ ] Write system tests
- [ ] Create web documentation page
- [ ] Write API markdown documentation
- [ ] Add to sitemap
- [ ] Deploy and test in production

### 4. Documentation Phase (1 week)
- [ ] Write API overview documentation
- [ ] Create code examples for all calculators
- [ ] Record video tutorials
- [ ] Write SEO-optimized guide articles
- [ ] Set up structured data markup

### 5. Launch Phase
- [ ] Announce on social media
- [ ] Submit to calculator directories
- [ ] Reach out to maker communities
- [ ] Monitor analytics and gather feedback

---

## Success Criteria

### Phase 1 Completion Criteria
- ✅ All 7 calculators functional and tested
- ✅ API endpoints documented and working
- ✅ Web pages live with SEO optimization
- ✅ Analytics tracking implemented
- ✅ Zero critical bugs
- ✅ Page load time < 2 seconds
- ✅ Mobile responsive on all devices
- ✅ Accessibility (WCAG 2.1 AA compliant)

### Traffic Goals (3 months post-launch)
- 5,000+ monthly calculator page views
- 500+ API calls per month
- 10+ referring domains (backlinks)
- Top 10 Google ranking for 3+ primary keywords
- 5% conversion rate (calculator → signup)

---

## Risk Mitigation

### Technical Risks
**Risk:** Complex calculations may have edge cases
**Mitigation:** Comprehensive unit testing, validation against known good values

**Risk:** API abuse (excessive calls)
**Mitigation:** Rate limiting, API key requirement for high-volume use

**Risk:** Calculator UI performance on mobile
**Mitigation:** Lightweight JavaScript, lazy loading, performance testing

### Business Risks
**Risk:** Low user adoption
**Mitigation:** SEO-optimized content, community outreach, social media promotion

**Risk:** Competitors copying calculators
**Mitigation:** Continuous improvement, build brand reputation, add unique features

**Risk:** Maintenance burden
**Mitigation:** Well-tested code, comprehensive documentation, modular architecture

---

## Next Steps

1. **Review and approve this plan** - Stakeholder sign-off
2. **Create detailed specifications** - For each Phase 1 calculator
3. **Design mockups** - UI/UX design for calculator interfaces
4. **Gather reference data** - Lookup tables, material properties, formulas
5. **Set up development environment** - Testing frameworks, libraries
6. **Begin Phase 1 implementation** - Start with Board Foot Calculator

---

## Resources

- [OmniCalculator.com Research](MAKER_CALCULATORS_RESEARCH.md)
- [CalcuMake Advanced Calculator](https://calcumake.com/3d-print-pricing-calculator) - Reference implementation
- [Existing API Documentation](../app/controllers/api/v1/) - API patterns to follow
- [Testing Guide](TESTING_GUIDE.md) - Testing best practices
