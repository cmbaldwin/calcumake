# Testing Guide

## Overview

CalcuMake uses a **hybrid testing approach** optimized for speed:

- **Minitest** - Rails unit/integration tests (super fast: 1,068 tests in ~3.85s)
- **Jest** - JavaScript unit tests (very fast: ~2-5s for 50 tests)
- **Capybara** - System tests (slow: ~10-30s per test)

## Running Tests Locally

### All CI Checks (Recommended Before Push)

```bash
bin/ci
```

This runs the **exact same checks** as GitHub Actions CI:
- ✅ Brakeman security scan
- ✅ Importmap audit
- ✅ Rubocop linting
- ✅ Jest JavaScript tests
- ✅ Rails Minitest tests
- ✅ Capybara system tests

**Total time**: ~15-30 seconds (depending on system tests)

### Individual Test Suites

```bash
# Rails tests only (fastest: ~3.85s)
bin/rails test

# JavaScript tests only (very fast: ~2-5s)
npm test

# System tests only (slow: ~20-60s)
bin/rails test:system

# Watch mode for JS tests (auto-rerun on save)
npm run test:watch

# Coverage report for JS
npm run test:coverage
```

### Security & Linting

```bash
# Security scan
bin/brakeman

# JavaScript audit
bin/importmap audit

# Code style
bin/rubocop

# Auto-fix style issues
bin/rubocop -a
```

## Speed Comparison

| Test Type | Count | Time | Tests/Second | Use Case |
|-----------|-------|------|--------------|----------|
| **Minitest** | 1,068 | 3.85s | 277 | Unit/integration tests |
| **Jest** | ~50 | 2-5s | 10-25 | JavaScript logic tests |
| **System** | ~10 | 100-300s | 0.03-0.1 | Full user flows |

**Total**: ~6-9s for all unit tests, ~2-5 minutes with system tests

## Test Organization

```
test/
├── components/              # ViewComponent tests (Minitest)
│   ├── cards/
│   └── shared/
├── controllers/             # Controller tests (Minitest)
├── helpers/                 # Helper tests (Minitest)
├── javascript/              # JavaScript tests (Jest)
│   └── controllers/
│       └── mixins/
├── models/                  # Model tests (Minitest)
└── system/                  # System tests (Capybara)
```

## Jest Configuration

### What's Covered

Jest tests focus on **pure logic** in Stimulus mixins:

- **calculator_mixin.js** - Cost calculation formulas
  - `calculateFilamentCost()` - Weight → cost conversion
  - `calculateElectricityCost()` - kWh → cost
  - `calculateLaborCost()` - Time → cost
  - `calculateMachineCost()` - Depreciation calculation

- **storage_mixin.js** - localStorage operations
  - `saveToStorage()` - Data serialization
  - `loadFromStorage()` - Data restoration
  - `clearStorage()` - Reset functionality
  - `setupAutoSave()` - Auto-save intervals

- **export_mixin.js** - PDF/CSV generation (TBD)

### Running Jest Tests

```bash
# All tests
npm test

# Watch mode (auto-rerun on save)
npm run test:watch

# Coverage report
npm run test:coverage
```

### Example Test Structure

```javascript
import { CalculatorMixin } from 'controllers/mixins/calculator_mixin.js'

describe('CalculatorMixin', () => {
  test('calculateFilamentCost sums multiple filaments', () => {
    const mockController = Object.assign({}, CalculatorMixin)
    const plateData = {
      filaments: [
        { weight: 100, pricePerKg: 25 },
        { weight: 50, pricePerKg: 30 }
      ]
    }

    const cost = mockController.calculateFilamentCost(plateData)

    expect(cost).toBeCloseTo(4.0)
  })
})
```

## GitHub Actions CI

CI runs automatically on:
- ✅ Every push to `main`
- ✅ Every pull request

### Workflow Jobs

1. **scan_ruby** - Brakeman security scan
2. **scan_js** - Importmap audit
3. **lint** - Rubocop style check
4. **test_js** - Jest JavaScript tests
5. **test** - Rails Minitest + System tests

All jobs run in **parallel** for faster CI.

### Before Pushing

**Always run** before `git push`:

```bash
bin/ci
```

This ensures your code will pass CI checks.

### If CI Fails

1. Check the GitHub Actions tab
2. Click failed job to see logs
3. Run same command locally:
   ```bash
   # Security scan failed
   bin/brakeman

   # Lint failed
   bin/rubocop -a

   # Tests failed
   bin/rails test
   npm test
   ```
4. Fix issues, commit, push again

## Best Practices

### When to Use Each Test Type

**Minitest** - Use for:
- ✅ Model validations and methods
- ✅ Controller actions and responses
- ✅ ViewComponent rendering
- ✅ Helper methods
- ❌ JavaScript logic (use Jest instead)

**Jest** - Use for:
- ✅ Pure JavaScript functions
- ✅ Stimulus mixin logic
- ✅ Calculation formulas
- ✅ Data transformations
- ❌ DOM manipulation (use System tests)

**System Tests** - Use for:
- ✅ Complete user workflows
- ✅ JavaScript + Rails integration
- ✅ Critical business flows
- ❌ Simple CRUD operations (too slow)

### Writing Fast Tests

**DO:**
- ✅ Keep setup minimal
- ✅ Use fixtures for test data
- ✅ Mock external services
- ✅ Test pure functions in Jest
- ✅ Use `assert_in_delta` for floats

**DON'T:**
- ❌ Boot browser for simple tests
- ❌ Test implementation details
- ❌ Make real API calls
- ❌ Test framework behavior
- ❌ Use `sleep` (use proper waits)

### Test Coverage Goals

- **Models**: 100% (critical business logic)
- **Controllers**: 80%+ (happy path + errors)
- **ViewComponents**: 100% (public API)
- **JavaScript**: 80%+ (calculation logic)
- **System**: 50%+ (critical user flows)

## Debugging Tests

### Failed Minitest

```bash
# Run single test file
bin/rails test test/models/print_pricing_test.rb

# Run single test
bin/rails test test/models/print_pricing_test.rb:42

# Verbose output
bin/rails test --verbose
```

### Failed Jest Test

```bash
# Run single test file
npm test -- calculator_mixin.test.js

# Run tests matching pattern
npm test -- --testNamePattern="calculateFilamentCost"

# Debug mode
node --inspect-brk node_modules/.bin/jest --runInBand
```

### Failed System Test

```bash
# Run single system test
bin/rails test:system test/system/pricing_calculator_test.rb

# Keep browser open on failure (add to test)
driven_by :selenium, using: :chrome, screen_size: [1400, 1400]

# Check screenshots
ls tmp/screenshots/
```

## Common Issues

### "Jest not found"

```bash
npm install
```

### "Database not found"

```bash
bin/rails db:test:prepare
```

### "Chrome driver error"

```bash
# Update chromedriver
gem update selenium-webdriver
```

### "localStorage is not defined"

```javascript
// Add to test file
/**
 * @jest-environment jsdom
 */
```

## Performance Optimization

### Speed Up Minitest

Already optimized with:
- Parallel test workers
- Fixtures (not factories)
- Minimal database transactions

### Speed Up Jest

Already optimized with:
- No Rails boot
- Pure function tests
- Fast file watching

### Speed Up System Tests

Tips:
- Use headless Chrome
- Minimize browser tests
- Test critical flows only
- Prefer Minitest for simple checks

## Summary

**Before every push:**
```bash
bin/ci
```

**During development:**
```bash
# Fast feedback loop
bin/rails test  # 3.85s
npm test        # 2-5s

# Full confidence
bin/ci          # 15-30s
```

**Total test suite**: 1,068+ tests in ~6-9 seconds (unit tests only), ~2-5 minutes (with system tests).
