import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="demo-calculator"
export default class extends Controller {
  static targets = [
    "printTime", "filamentWeight", "filamentPrice", "laborRate",
    "filamentCost", "electricityCost", "laborCost", "totalCost", "results"
  ]

  static values = {
    energyCost: Number // Cost per kWh
  }

  connect() {
    // Initialize timer references
    this._animationTimeout = null
    this._calculateDebounce = null

    // Calculate initial values
    this.calculateImmediate()
  }

  disconnect() {
    // Clean up timers
    if (this._animationTimeout) {
      clearTimeout(this._animationTimeout)
      this._animationTimeout = null
    }
    if (this._calculateDebounce) {
      clearTimeout(this._calculateDebounce)
      this._calculateDebounce = null
    }
  }

  // Debounced calculate - called from input events
  calculate() {
    if (this._calculateDebounce) {
      clearTimeout(this._calculateDebounce)
    }
    this._calculateDebounce = setTimeout(() => {
      this.calculateImmediate()
    }, 50)
  }

  calculateImmediate() {
    // Guard against disconnected state
    if (!this.element || !this.element.isConnected) return

    const printTime = parseFloat(this.printTimeTarget?.value) || 0
    const filamentWeight = parseFloat(this.filamentWeightTarget?.value) || 0
    const filamentPrice = parseFloat(this.filamentPriceTarget?.value) || 0
    const laborRate = parseFloat(this.laborRateTarget?.value) || 0

    // Calculate costs
    const filamentCost = this.calculateFilamentCost(filamentWeight, filamentPrice)
    const electricityCost = this.calculateElectricityCost(printTime)
    const laborCost = this.calculateLaborCost(printTime, laborRate)
    const totalCost = filamentCost + electricityCost + laborCost

    // Update display
    if (this.hasFilamentCostTarget) {
      this.filamentCostTarget.textContent = this.formatCurrency(filamentCost)
    }
    if (this.hasElectricityCostTarget) {
      this.electricityCostTarget.textContent = this.formatCurrency(electricityCost)
    }
    if (this.hasLaborCostTarget) {
      this.laborCostTarget.textContent = this.formatCurrency(laborCost)
    }
    if (this.hasTotalCostTarget) {
      this.totalCostTarget.textContent = this.formatCurrency(totalCost)
    }

    // Add animation effect (with cleanup)
    if (this.hasResultsTarget) {
      if (this._animationTimeout) {
        clearTimeout(this._animationTimeout)
      }
      this.resultsTarget.style.transform = "scale(1.02)"
      this._animationTimeout = setTimeout(() => {
        if (this.hasResultsTarget) {
          this.resultsTarget.style.transform = "scale(1)"
        }
      }, 150)
    }
  }

  calculateFilamentCost(weightGrams, pricePerKg) {
    const weightKg = weightGrams / 1000
    return weightKg * pricePerKg
  }

  calculateElectricityCost(hours) {
    const powerKw = 0.2 // 200W sample printer
    return hours * powerKw * this.energyCostValue
  }

  calculateLaborCost(printHours, hourlyRate) {
    // Assume 30 minutes prep/post-processing per print
    const laborHours = 0.5
    return laborHours * hourlyRate
  }

  formatCurrency(amount) {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(amount)
  }
}