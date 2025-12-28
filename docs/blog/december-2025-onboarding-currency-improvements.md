# January 2025 Update: Smarter Onboarding & Enhanced Multi-Currency Support

**Author:** CalcuMake Team
**Published:** December 28, 2025
**Featured:** Yes

---

## Excerpt

Get started faster with intelligent currency selection that shows your local currency symbol, auto-fills regional electricity costs, and converts all starter equipment to your currency. We've updated energy rates for 2025 and added comprehensive currency conversion testing.

---

We're excited to announce major improvements to CalcuMake's onboarding experience and currency handling that make it easier than ever to get started with accurate 3D print cost calculations in your local currency.

## What's New

### 🌍 Intelligent Currency Selection

When you select your currency during onboarding, CalcuMake now automatically:

- **Shows your currency symbol** (¥, €, £, $, etc.) next to relevant fields
- **Suggests regional electricity costs** based on current 2025 averages for your country
- **Auto-fills energy costs** to help you get started quickly with realistic defaults
- **Converts all starter equipment prices** to your local currency automatically

No more guessing about typical electricity rates in your region or manually converting printer and filament costs!

### ⚡ Updated Energy Cost Estimates (2025)

We've refreshed our regional electricity cost suggestions to reflect current global energy prices:

| Region         | Currency | Energy Cost | Change               |
| -------------- | -------- | ----------- | -------------------- |
| United States  | USD      | $0.18/kWh   | ↑ Updated            |
| Europe         | EUR      | €0.28/kWh   | ↑ Updated            |
| United Kingdom | GBP      | £0.26/kWh   | ↑ Updated            |
| Japan          | JPY      | ¥38/kWh     | ↑ Updated            |
| Canada         | CAD      | C$0.16/kWh  | ↑ Updated            |
| Australia      | AUD      | A$0.32/kWh  | ↑ Updated            |
| China          | CNY      | ¥0.60/kWh   | — Updated            |
| India          | INR      | ₹8.50/kWh   | ↑ Updated            |
| Argentina      | ARS      | $120/kWh    | ↑ Inflation adjusted |
| Saudi Arabia   | SAR      | ﷼0.18/kWh   | — Updated            |

These suggestions are based on residential electricity rates and help you get accurate cost calculations from day one.

### 🔄 Automatic Currency Conversion

Behind the scenes, we've completely rebuilt our currency conversion system:

- **Real-time exchange rates** from the European Central Bank via Frankfurter API
- **Smart caching** reduces API calls while keeping rates fresh (24-hour cache)
- **Automatic conversion** of all starter templates (printers, filaments, resins)
- **Fallback system** ensures you can always use the app even if currency APIs are unavailable

When you select Japanese Yen (¥) during onboarding, for example:

- A $799 Prusa i3 MK4 automatically shows as ¥124,612
- A $25 PLA filament spool shows as ¥3,900
- Electricity costs are pre-filled with Japan's average of ¥38/kWh

### 🎯 Better Default Values

We've updated all default pricing based on current 2025 market rates for each region:

- **Filament prices** reflect regional availability and shipping costs
- **Printer costs** account for import duties and local market conditions
- **Labor rates** vary by region to match local service pricing expectations

### 🧪 Fully Tested

This update includes:

- 6 new comprehensive currency conversion tests
- Full test coverage across all supported currencies
- Automated WebMock stubs for reliable testing
- All 1,525+ tests passing ✅

## How It Works

### Step 1: Choose Your Currency

During onboarding, simply select your preferred currency from our list of 10 supported options.

### Step 2: See Instant Suggestions

CalcuMake immediately displays:

- Your currency symbol next to the electricity cost field
- A helpful alert with your region's average electricity rate
- An auto-filled suggestion you can accept or customize

### Step 3: Get Accurate Costs

All starter printers and materials are automatically converted to your currency using current exchange rates. No calculator needed!

## Technical Highlights

For the developers and technical users out there, here's what we built:

### Smart Currency Service

```ruby
# Automatic conversion with fallback
CurrencyConverter.convert(799, from: 'USD', to: 'JPY')
# => 124612.04 (using live ECB rates)
```

### Dynamic UI with Stimulus

```javascript
// Real-time currency symbol updates
updateCurrencyDisplay() {
  const currency = this.currencySelectTarget.value
  this.currencySymbolTarget.textContent = info.symbol
  this.suggestionTarget.innerHTML = regionalCostAlert
}
```

### Comprehensive Testing

- WebMock stubs for all currency API calls
- Test coverage for JPY, EUR, GBP, CAD, and more
- Fallback rate testing for offline scenarios

## Why This Matters

**Accuracy from Day One**: Getting your initial settings right means more accurate quotes from your very first project.

**Regional Relevance**: Electricity costs vary wildly worldwide (from $0.12/kWh in some regions to $0.38/kWh in others). Using accurate local rates ensures your profit margins are realistic.

**Less Manual Work**: No more searching for "average electricity cost in [country]" or converting USD prices in your head.

**Professional Results**: When your costs reflect local market conditions, your quotes are more competitive and your pricing is more defensible to clients.

## Looking Ahead

This currency system lays the groundwork for future enhancements:

- Multi-currency invoicing for international clients
- Historical exchange rate tracking
- Currency-aware reporting and analytics
- Region-specific material vendor integrations

## Get Started Today

New to CalcuMake? [Sign up now](https://calcumake.com/users/sign_up) and experience the new onboarding flow.

Existing users can update their currency preferences and electricity costs in [Profile Settings](https://calcumake.com/profile/edit) at any time.

---

**Questions or feedback?** We'd love to hear how these improvements are working for you. Reach out to us at [GitHub Issues](https://github.com/anthropics/claude-code/issues) or through the in-app feedback form.

_CalcuMake is built by makers, for makers. Every update is designed to save you time and improve your pricing accuracy._
