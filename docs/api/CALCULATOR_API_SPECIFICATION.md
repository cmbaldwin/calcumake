# Calculator API Specification

**Version:** 1.0
**Date:** 2026-01-16
**Base URL:** `https://calcumake.com/api/v1`

## Overview

The CalcuMake Calculator API provides programmatic access to 26+ maker-oriented calculators covering woodworking, electronics, metalworking, welding, and more. All calculator endpoints are **public** and do not require authentication.

### Key Features

- ✅ **No authentication required** - Open access for all calculators
- ✅ **JSON:API compliant** - Consistent request/response format
- ✅ **Rate limiting** - Fair use policy (1000 requests/hour per IP)
- ✅ **Input validation** - Comprehensive error messages
- ✅ **Unit flexibility** - Support for metric and imperial units
- ✅ **CORS enabled** - Use from any domain
- ✅ **Fast response times** - < 100ms average
- ✅ **No usage tracking** - Privacy-focused (optional analytics opt-in)

---

## API Design Principles

### 1. Consistent Request Format

All calculators follow the same request structure:

```json
POST /api/v1/calculators/{calculator-type}

{
  "calculator": {
    "input_param_1": value,
    "input_param_2": value,
    ...
  }
}
```

### 2. Consistent Response Format

All successful responses return:

```json
{
  "inputs": { ... },      // Echo of input values (validated/normalized)
  "outputs": { ... },     // Calculated results
  "metadata": {           // Calculation metadata
    "calculator_name": "board_foot_calculator",
    "calculation_time": "2026-01-16T12:34:56Z",
    "version": "1.0",
    "units": "imperial"   // or "metric"
  }
}
```

### 3. Comprehensive Error Responses

All errors return:

```json
{
  "error": "Error message",
  "details": {
    "field_name": ["Error 1", "Error 2"]
  },
  "status": 422
}
```

---

## Authentication

**Not required for calculator endpoints.** All calculators are publicly accessible.

Optional: Users with CalcuMake accounts can include an API token to:
- Track calculation history
- Save favorite calculations
- Remove rate limits
- Access advanced features

```bash
# Optional authentication
curl -X POST https://calcumake.com/api/v1/calculators/board-foot \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ ... }'
```

---

## Rate Limiting

**Public Access (No Token):**
- 1,000 requests per hour per IP address
- 10 requests per second burst rate

**Authenticated Access (With Token):**
- 10,000 requests per hour
- 50 requests per second burst rate

**Rate Limit Headers:**
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 995
X-RateLimit-Reset: 1642348800
```

---

## Common Request Parameters

### Unit System

All calculators support both metric and imperial units via the `units` parameter:

```json
{
  "calculator": {
    "units": "imperial",  // or "metric"
    ...
  }
}
```

If not specified, defaults to `imperial` (for backwards compatibility with US users).

### Rounding Precision

Control decimal places in outputs:

```json
{
  "calculator": {
    "precision": 3,  // Number of decimal places (default: 2-4 depending on calculator)
    ...
  }
}
```

---

## Calculator Endpoints

### Woodworking Calculators

#### 1. Board Foot Calculator

Calculate lumber volume in board feet.

**Endpoint:** `POST /api/v1/calculators/board-foot`

**Request:**
```json
{
  "calculator": {
    "length": 8,         // feet (imperial) or meters (metric)
    "width": 6,          // inches (imperial) or cm (metric)
    "thickness": 1,      // inches (imperial) or cm (metric)
    "quantity": 10,      // optional, default: 1
    "units": "imperial"  // optional, default: imperial
  }
}
```

**Response:**
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

---

#### 2. Lumber Calculator

Calculate lumber volume, length, and cost.

**Endpoint:** `POST /api/v1/calculators/lumber`

**Request:**
```json
{
  "calculator": {
    "length": 8,            // feet or meters
    "width": 6,             // inches or cm
    "thickness": 1,         // inches or cm
    "quantity": 10,
    "price_per_unit": 5.50, // optional, price per board foot or cubic meter
    "wood_type": "oak",     // optional, for weight calculation
    "units": "imperial"
  }
}
```

**Response:**
```json
{
  "inputs": { ... },
  "outputs": {
    "board_feet": 40.0,
    "cubic_feet": 3.333,
    "cubic_meters": 0.0944,
    "total_length_feet": 80.0,
    "total_length_meters": 24.384,
    "total_cost": 220.00,
    "weight_lbs": 150.0,
    "weight_kg": 68.04
  },
  "metadata": { ... }
}
```

---

### Electronics Calculators

#### 3. LED Resistor Calculator

Calculate current limiting resistor for LEDs.

**Endpoint:** `POST /api/v1/calculators/led-resistor`

**Request:**
```json
{
  "calculator": {
    "supply_voltage": 12,        // V
    "led_voltage": 2.1,          // V (forward voltage)
    "led_current": 20,           // mA (forward current)
    "num_leds": 3,
    "connection": "series"       // "series" or "parallel"
  }
}
```

**Response:**
```json
{
  "inputs": { ... },
  "outputs": {
    "resistance_ohms": 295.0,
    "nearest_standard_resistor": 300,  // E12 series
    "power_dissipation_watts": 0.118,
    "recommended_wattage": 0.25,        // 1/4W resistor
    "voltage_drop": 5.9,                // V across resistor
    "actual_led_current": 19.67         // mA with standard resistor
  },
  "metadata": { ... }
}
```

---

#### 4. Wire Gauge Calculator

Calculate wire properties from AWG/SWG gauge.

**Endpoint:** `POST /api/v1/calculators/wire-gauge`

**Request:**
```json
{
  "calculator": {
    "gauge": 12,                  // AWG or SWG number
    "standard": "awg",            // "awg" or "swg"
    "material": "copper",         // "copper", "aluminum", etc.
    "length": 100,                // optional, feet or meters
    "units": "imperial"
  }
}
```

**Response:**
```json
{
  "inputs": { ... },
  "outputs": {
    "diameter_mm": 2.053,
    "diameter_inches": 0.0808,
    "diameter_mils": 80.81,
    "area_mm2": 3.309,
    "area_circular_mils": 6530.0,
    "resistance_per_1000ft": 1.588,     // Ω/1000ft
    "resistance_per_km": 5.211,         // Ω/km
    "total_resistance": 0.159,          // Ω (if length provided)
    "ampacity": 25,                     // Amperes (NEC rating)
    "max_voltage_drop_1pct": 2.5        // V (at rated ampacity)
  },
  "metadata": { ... }
}
```

---

### Metalworking Calculators

#### 5. Metal Weight Calculator

Calculate weight of metal shapes.

**Endpoint:** `POST /api/v1/calculators/metal-weight`

**Request:**
```json
{
  "calculator": {
    "shape": "plate",             // "bar", "plate", "tube", "angle", "channel", "i_beam"
    "material": "steel_mild",     // Material code
    "dimensions": {
      "length": 120,              // inches or cm
      "width": 48,                // inches or cm (for plate)
      "thickness": 0.25           // inches or cm
    },
    "quantity": 5,
    "price_per_lb": 0.75,         // optional
    "units": "imperial"
  }
}
```

**Response:**
```json
{
  "inputs": { ... },
  "outputs": {
    "volume_cubic_inches": 1440.0,
    "volume_cubic_cm": 23597.4,
    "weight_per_piece_lbs": 204.0,
    "weight_per_piece_kg": 92.53,
    "total_weight_lbs": 1020.0,
    "total_weight_kg": 462.66,
    "total_cost": 765.00,
    "material_density_lb_in3": 0.284,
    "material_density_g_cm3": 7.85
  },
  "metadata": { ... }
}
```

**Supported Shapes:**
- `bar` - Round or square bar
- `plate` - Flat plate/sheet
- `tube` - Round or square tube
- `angle` - L-shaped angle iron
- `channel` - C-channel
- `i_beam` - I-beam / H-beam

**Supported Materials:**
- Steel: `steel_mild`, `steel_stainless_304`, `steel_stainless_316`
- Aluminum: `aluminum_6061`, `aluminum_7075`
- Copper: `copper_pure`, `copper_brass`, `copper_bronze`
- Other: `titanium`, `nickel`

---

#### 6. Welding Calculator

Calculate weld strength and specifications.

**Endpoint:** `POST /api/v1/calculators/welding`

**Request:**
```json
{
  "calculator": {
    "joint_type": "fillet",        // "fillet", "butt", "corner", "lap", "edge"
    "material": "steel_mild",
    "base_thickness": 0.25,        // inches or mm
    "weld_size": 0.1875,           // inches or mm (leg size for fillet)
    "weld_length": 12,             // inches or cm
    "applied_load": 5000,          // optional, lbs or N
    "safety_factor": 1.5,          // optional, default: 1.5
    "units": "imperial"
  }
}
```

**Response:**
```json
{
  "inputs": { ... },
  "outputs": {
    "throat_thickness": 0.1326,    // inches (leg_size * 0.707)
    "effective_area_in2": 1.591,   // in² (throat * length)
    "effective_area_mm2": 1026.5,
    "allowable_shear_psi": 18000,  // Material-dependent
    "max_load_capacity_lbs": 28638,
    "actual_shear_stress_psi": 3143,
    "safety_margin": 5.73,         // Ratio (capacity / applied load)
    "pass_fail": "PASS",           // Based on applied load vs capacity
    "electrode_size": "E7018-3/32",
    "estimated_weld_time_min": 2.5,
    "filler_metal_lbs": 0.15
  },
  "metadata": { ... }
}
```

---

#### 7. K-Factor Calculator (Sheet Metal)

Calculate bend allowance for sheet metal.

**Endpoint:** `POST /api/v1/calculators/k-factor`

**Request:**
```json
{
  "calculator": {
    "material": "steel_mild",
    "thickness": 0.125,            // inches or mm
    "bend_angle": 90,              // degrees
    "inside_radius": 0.125,        // inches or mm
    "bend_method": "air_bending",  // "air_bending", "bottoming", "coining"
    "leg1_length": 4,              // optional, inches or cm
    "leg2_length": 4,              // optional, inches or cm
    "units": "imperial"
  }
}
```

**Response:**
```json
{
  "inputs": { ... },
  "outputs": {
    "k_factor": 0.446,             // Ratio (0.3-0.5 typically)
    "bend_allowance": 0.284,       // inches or mm
    "bend_deduction": 0.069,       // inches or mm
    "outside_setback": 0.177,      // inches or mm
    "flat_length": 8.284,          // inches or cm (if leg lengths provided)
    "neutral_axis_distance": 0.056 // inches or mm (from inside surface)
  },
  "metadata": { ... }
}
```

---

## Error Handling

### Validation Errors

**Status Code:** `422 Unprocessable Entity`

```json
{
  "error": "Validation failed",
  "details": {
    "length": ["must be greater than 0"],
    "width": ["must be greater than 0"],
    "material": ["is not included in the list"]
  },
  "status": 422
}
```

### Calculator Not Found

**Status Code:** `404 Not Found`

```json
{
  "error": "Calculator not found",
  "available_calculators": [
    "board-foot",
    "lumber",
    "led-resistor",
    "wire-gauge",
    "metal-weight",
    "welding",
    "k-factor"
  ],
  "status": 404
}
```

### Rate Limit Exceeded

**Status Code:** `429 Too Many Requests`

```json
{
  "error": "Rate limit exceeded",
  "limit": 1000,
  "retry_after": 3600,
  "message": "You have exceeded the rate limit. Please try again in 1 hour."
}
```

### Server Error

**Status Code:** `500 Internal Server Error`

```json
{
  "error": "Internal server error",
  "message": "An unexpected error occurred. Please try again later.",
  "request_id": "abc123"
}
```

---

## CORS Support

All calculator endpoints support **Cross-Origin Resource Sharing (CORS)** for browser-based requests:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: POST, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
```

---

## Versioning

The API uses URL-based versioning: `/api/v1/...`

**Current Version:** v1
**Stability:** Stable - backwards compatible changes only

Future versions (v2, v3, etc.) will be introduced if breaking changes are necessary. v1 will remain available indefinitely.

---

## SDK & Libraries

### Official SDKs (Planned)

- **JavaScript/TypeScript** - npm package: `@calcumake/calculators`
- **Python** - PyPI package: `calcumake-calculators`
- **Ruby** - Gem: `calcumake-calculators`

### Community SDKs

Contributions welcome! Submit your SDK to be listed here.

---

## Usage Examples

### Example 1: Board Foot Calculation

**cURL:**
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

**JavaScript (Fetch):**
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
console.log(`Total: ${result.outputs.total_board_feet} board feet`);
```

**Python (requests):**
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
print(f"Total: {result['outputs']['total_board_feet']} board feet")
```

---

### Example 2: LED Resistor with Error Handling

**JavaScript:**
```javascript
async function calculateLEDResistor(supplyVoltage, ledVoltage, ledCurrent) {
  try {
    const response = await fetch('https://calcumake.com/api/v1/calculators/led-resistor', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        calculator: {
          supply_voltage: supplyVoltage,
          led_voltage: ledVoltage,
          led_current: ledCurrent,
          num_leds: 1,
          connection: 'series'
        }
      })
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error);
    }

    const result = await response.json();
    return {
      resistor: result.outputs.nearest_standard_resistor,
      wattage: result.outputs.recommended_wattage,
      power: result.outputs.power_dissipation_watts
    };

  } catch (error) {
    console.error('Calculation failed:', error.message);
    return null;
  }
}

// Usage
const led = await calculateLEDResistor(12, 2.1, 20);
console.log(`Use ${led.resistor}Ω ${led.wattage}W resistor`);
```

---

### Example 3: Metal Weight for Inventory System

**Python:**
```python
import requests

def calculate_inventory_weight(parts):
    """Calculate total weight for multiple metal parts"""

    total_weight_kg = 0
    total_cost = 0

    for part in parts:
        response = requests.post(
            'https://calcumake.com/api/v1/calculators/metal-weight',
            json={
                'calculator': {
                    'shape': part['shape'],
                    'material': part['material'],
                    'dimensions': part['dimensions'],
                    'quantity': part['quantity'],
                    'price_per_lb': part.get('price_per_lb', 0),
                    'units': 'imperial'
                }
            }
        )

        if response.status_code == 200:
            result = response.json()
            total_weight_kg += result['outputs']['total_weight_kg']
            total_cost += result['outputs'].get('total_cost', 0)
        else:
            print(f"Error calculating {part['name']}: {response.json()}")

    return {
        'total_weight_kg': round(total_weight_kg, 2),
        'total_weight_lbs': round(total_weight_kg * 2.20462, 2),
        'total_cost': round(total_cost, 2)
    }

# Usage
inventory = [
    {
        'name': 'Steel Plates',
        'shape': 'plate',
        'material': 'steel_mild',
        'dimensions': {'length': 120, 'width': 48, 'thickness': 0.25},
        'quantity': 10,
        'price_per_lb': 0.75
    },
    {
        'name': 'Aluminum Bars',
        'shape': 'bar',
        'material': 'aluminum_6061',
        'dimensions': {'diameter': 1, 'length': 72},
        'quantity': 50,
        'price_per_lb': 2.50
    }
]

result = calculate_inventory_weight(inventory)
print(f"Total inventory: {result['total_weight_lbs']} lbs (${result['total_cost']})")
```

---

## Best Practices

### 1. Cache Results

Calculator results are deterministic - identical inputs always produce identical outputs. Cache results client-side to reduce API calls:

```javascript
const cacheKey = JSON.stringify(calculatorInputs);
const cached = localStorage.getItem(cacheKey);

if (cached) {
  return JSON.parse(cached);
} else {
  const result = await callCalculatorAPI(inputs);
  localStorage.setItem(cacheKey, JSON.stringify(result));
  return result;
}
```

### 2. Validate Inputs Client-Side

Reduce API calls by validating inputs before submission:

```javascript
function validateBoardFootInputs(inputs) {
  const errors = {};

  if (inputs.length <= 0) errors.length = 'must be greater than 0';
  if (inputs.width <= 0) errors.width = 'must be greater than 0';
  if (inputs.thickness <= 0) errors.thickness = 'must be greater than 0';

  return Object.keys(errors).length === 0 ? null : errors;
}
```

### 3. Handle Errors Gracefully

Always handle both network errors and API errors:

```javascript
try {
  const response = await fetch(url, options);

  if (!response.ok) {
    const error = await response.json();
    // Handle specific error types
    if (response.status === 429) {
      showRateLimitError(error.retry_after);
    } else if (response.status === 422) {
      showValidationErrors(error.details);
    } else {
      showGenericError(error.message);
    }
    return null;
  }

  return await response.json();

} catch (networkError) {
  showNetworkError();
  return null;
}
```

### 4. Batch Calculations (Future Feature)

For calculating multiple related values, use batch endpoints (coming soon):

```javascript
// Future API (v1.1)
POST /api/v1/calculators/batch

{
  "calculations": [
    {
      "calculator_type": "board_foot",
      "inputs": { ... }
    },
    {
      "calculator_type": "lumber_weight",
      "inputs": { ... }
    }
  ]
}
```

---

## Support

### Documentation
- **API Docs:** https://calcumake.com/api/docs
- **Calculator Guides:** https://calcumake.com/calculators
- **Code Examples:** https://github.com/calcumake/api-examples

### Community
- **Discord:** https://discord.gg/calcumake
- **GitHub Issues:** https://github.com/calcumake/api-feedback

### Contact
- **Email:** api@calcumake.com
- **Status Page:** https://status.calcumake.com

---

## Changelog

### v1.0 (2026-01-16)
- Initial release
- 7 calculators: Board Foot, Lumber, LED Resistor, Wire Gauge, Metal Weight, Welding, K-Factor
- Public access (no authentication required)
- Rate limiting: 1000 req/hour
- CORS support
- Comprehensive error handling

### Future Versions

**v1.1 (Planned)**
- Batch calculation endpoint
- Webhook support for async calculations
- Enhanced material database

**v1.2 (Planned)**
- 11 additional calculators (Phase 2)
- GraphQL endpoint
- Real-time calculation streaming
