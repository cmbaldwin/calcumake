import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["currencySelect", "spoolPrice", "prepCost", "postCost", "energyCost", "printerCost", "otherCosts"]
  static values = { 
    currencies: Object,
    currentCurrency: String
  }

  connect() {
    this.updatePlaceholders()
    this.updateCurrencySymbols()
  }

  currencyChanged() {
    const selectedCurrency = this.currencySelectTarget.value
    this.currentCurrencyValue = selectedCurrency
    this.updatePlaceholders()
    this.updateCurrencySymbols()
  }

  updatePlaceholders() {
    const currency = this.currentCurrencyValue || 'USD'
    const config = this.currenciesValue[currency] || this.currenciesValue['USD']
    
    if (this.hasSpoolPriceTarget) {
      this.spoolPriceTarget.placeholder = config.sample_values.spool_price
    }
    if (this.hasPrepCostTarget) {
      this.prepCostTarget.placeholder = config.sample_values.prep_cost
    }
    if (this.hasPostCostTarget) {
      this.postCostTarget.placeholder = config.sample_values.prep_cost
    }
    if (this.hasEnergyCostTarget) {
      this.energyCostTarget.placeholder = config.sample_values.energy_cost
    }
    if (this.hasPrinterCostTarget) {
      this.printerCostTarget.placeholder = config.sample_values.printer_cost
    }
    if (this.hasOtherCostsTarget) {
      this.otherCostsTarget.placeholder = config.decimals === 0 ? "0" : "0.00"
    }
  }

  updateCurrencySymbols() {
    const currency = this.currentCurrencyValue || 'USD'
    const config = this.currenciesValue[currency] || this.currenciesValue['USD']
    
    // Update all currency symbol spans
    document.querySelectorAll('[data-currency-symbol]').forEach(element => {
      element.textContent = config.symbol
    })
    
    // Update all currency displays in calculations
    document.querySelectorAll('.currency').forEach(element => {
      element.textContent = config.symbol
    })
  }
}