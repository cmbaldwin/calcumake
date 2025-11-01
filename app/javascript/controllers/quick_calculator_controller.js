import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="quick-calculator"
export default class extends Controller {
  static targets = [
    "printTime", "filamentWeight", "totalCost", "results"
  ]

  static values = {
    energyCost: Number, // Cost per kWh from user settings
    userCurrency: String, // User's default currency
    userLocale: String, // User's locale for formatting
    filamentPricePerKg: Number, // Default filament price per kg
    laborRatePerHour: Number // Default labor rate per hour
  }

  connect() {
    // Calculate initial values
    this.calculate()
  }

  calculate() {
    const printTime = parseFloat(this.printTimeTarget.value) || 0
    const filamentWeight = parseFloat(this.filamentWeightTarget.value) || 0

    // Quick calculation with average values
    const filamentCost = this.calculateFilamentCost(filamentWeight)
    const electricityCost = this.calculateElectricityCost(printTime)
    const laborCost = this.calculateLaborCost(printTime)
    const totalCost = filamentCost + electricityCost + laborCost

    // Update display with user's currency
    this.totalCostTarget.textContent = this.formatCurrency(totalCost)

    // Add subtle animation
    this.resultsTarget.style.transform = "scale(1.01)"
    setTimeout(() => {
      this.resultsTarget.style.transform = "scale(1)"
    }, 100)

    // Store values for potential use in create action
    this.lastCalculation = {
      printTime,
      filamentWeight,
      totalCost
    }
  }

  calculateFilamentCost(weightGrams) {
    // Use user's default or fallback to 25.0
    const filamentPrice = this.filamentPricePerKgValue || 25.0
    const weightKg = weightGrams / 1000
    return weightKg * filamentPrice
  }

  calculateElectricityCost(hours) {
    // Average printer power: 200W
    const averagePowerKw = 0.2
    return hours * averagePowerKw * this.energyCostValue
  }

  calculateLaborCost(printHours) {
    // Simplified: 15 minutes prep/post per hour of printing
    const laborRatio = 0.25
    const laborRate = this.laborRatePerHourValue || 20.0
    return printHours * laborRatio * laborRate
  }

  createFromEstimate() {
    // Navigate to new print pricing form with pre-filled values
    const url = new URL('/print_pricings/new', window.location.origin)

    if (this.lastCalculation) {
      // Add query parameters for pre-filling the form
      url.searchParams.set('print_time_hours', this.lastCalculation.printTime)
      url.searchParams.set('filament_weight', this.lastCalculation.filamentWeight)
    }

    // Navigate to the form
    window.location.href = url.toString()
  }

  formatCurrency(amount) {
    const locale = this.userLocaleValue || 'en-US'
    const currency = this.userCurrencyValue || 'USD'

    return new Intl.NumberFormat(locale, {
      style: 'currency',
      currency: currency,
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(amount)
  }

  disconnect() {
    // Clean up any event listeners if needed
  }
}