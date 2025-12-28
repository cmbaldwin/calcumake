import { Controller } from "@hotwired/stimulus"

// Manages currency selection with dynamic symbol display and electricity cost suggestions
export default class extends Controller {
  static targets = ["currencySelect", "energyInput", "currencySymbol", "suggestion"]

  // Regional electricity cost suggestions (cost per kWh in local currency)
  // Updated January 2025 based on current regional rates
  electricityCosts = {
    "USD": { symbol: "$", cost: 0.18, region: "United States" },
    "EUR": { symbol: "€", cost: 0.28, region: "Europe" },
    "GBP": { symbol: "£", cost: 0.26, region: "United Kingdom" },
    "JPY": { symbol: "¥", cost: 38, region: "Japan" },
    "CAD": { symbol: "C$", cost: 0.16, region: "Canada" },
    "AUD": { symbol: "A$", cost: 0.32, region: "Australia" },
    "CNY": { symbol: "¥", cost: 0.60, region: "China" },
    "INR": { symbol: "₹", cost: 8.50, region: "India" },
    "ARS": { symbol: "$", cost: 120.00, region: "Argentina" },
    "SAR": { symbol: "﷼", cost: 0.18, region: "Saudi Arabia" }
  }

  connect() {
    // Show initial currency info
    this.updateCurrencyDisplay()
  }

  updateCurrencyDisplay() {
    const currency = this.currencySelectTarget.value
    const info = this.electricityCosts[currency]

    if (!info) return

    // Update currency symbol display
    if (this.hasCurrencySymbolTarget) {
      this.currencySymbolTarget.textContent = info.symbol
    }

    // Update suggestion with regional cost
    if (this.hasSuggestionTarget) {
      this.suggestionTarget.innerHTML = `
        <div class="alert alert-info mt-2" role="alert">
          <i class="bi bi-lightbulb"></i>
          <strong>Suggestion:</strong>
          Average electricity cost in ${info.region} is approximately
          <strong>${info.symbol}${info.cost}/kWh</strong>
        </div>
      `
    }

    // Always populate with regional default when currency changes
    if (this.hasEnergyInputTarget) {
      this.energyInputTarget.value = info.cost
    }
  }
}
