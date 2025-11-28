import { Controller } from "@hotwired/stimulus"
import { CalculatorMixin } from "./mixins/calculator_mixin"
import { StorageMixin } from "./mixins/storage_mixin"
import { ExportMixin } from "./mixins/export_mixin"

// Advanced 3D Print Pricing Calculator
// Uses mixins for separation of concerns:
// - CalculatorMixin: Cost calculations
// - StorageMixin: LocalStorage persistence
// - ExportMixin: PDF and CSV exports
export default class extends Controller {
  static targets = [
    "jobName",
    "platesContainer",
    "plateTemplate",
    "totalFilamentCost",
    "totalElectricityCost",
    "totalLaborCost",
    "totalMachineCost",
    "totalOtherCosts",
    "grandTotal",
    "perUnitPrice",
    "perUnitSection",
    "resultsSection",
    "addPlateButton",
    "exportContent",
    "units",
    "failureRate",
    "shippingCost",
    "otherCost"
  ]

  static values = {
    energyCost: { type: Number, default: 0.12 },
    currency: { type: String, default: "USD" },
    locale: { type: String, default: "en-US" },
    maxPlates: { type: Number, default: 10 }
  }

  connect() {
    console.log("Advanced calculator connected")

    // Mix in shared functionality
    Object.assign(this.constructor.prototype, CalculatorMixin)
    Object.assign(this.constructor.prototype, StorageMixin)
    Object.assign(this.constructor.prototype, ExportMixin)

    // Load saved data
    this.loadFromStorage()

    // Initialize with first plate if none exist
    if (this.getPlates().length === 0) {
      this.addPlate()
    }

    // Calculate and auto-save
    this.calculate()
    this.setupAutoSave()
  }

  disconnect() {
    if (this.autoSaveInterval) {
      clearInterval(this.autoSaveInterval)
    }
  }

  // ==========================================
  // Plate Management
  // ==========================================

  addPlate(event = null) {
    if (event) event.preventDefault()

    const plates = this.getPlates()
    if (plates.length >= this.maxPlatesValue) {
      alert(`Maximum ${this.maxPlatesValue} plates allowed`)
      return
    }

    const template = this.plateTemplateTarget
    const clone = template.content.cloneNode(true)

    // Set unique index for this plate
    const plateIndex = plates.length
    const plateDiv = clone.querySelector('[data-plate-index]')
    plateDiv.setAttribute('data-plate-index', plateIndex)

    // Update all IDs and names with unique index
    this.updatePlateIndices(plateDiv, plateIndex)

    // Add to container
    this.platesContainerTarget.appendChild(clone)

    // Update button state
    this.updateAddPlateButton()

    // Add first filament to new plate
    this.addFilamentToPlate(plateDiv)

    // Recalculate
    this.calculate()
  }

  removePlate(event) {
    event.preventDefault()
    const plateDiv = event.target.closest('[data-plate-index]')

    // Don't allow removing the last plate
    const plates = this.getPlates()
    if (plates.length <= 1) {
      alert("At least one plate is required")
      return
    }

    plateDiv.remove()
    this.updateAddPlateButton()
    this.calculate()
  }

  updatePlateIndices(plateDiv, index) {
    // Update data attribute
    plateDiv.setAttribute('data-plate-index', index)

    // Update all input names and IDs within this plate
    const inputs = plateDiv.querySelectorAll('input, select, textarea')
    inputs.forEach(input => {
      if (input.name) {
        input.name = input.name.replace(/\[plates\]\[\d+\]/, `[plates][${index}]`)
      }
      if (input.id) {
        input.id = input.id.replace(/_plates_\d+_/, `_plates_${index}_`)
      }
    })
  }

  updateAddPlateButton() {
    if (this.hasAddPlateButtonTarget) {
      const plates = this.getPlates()
      this.addPlateButtonTarget.disabled = plates.length >= this.maxPlatesValue
    }
  }

  // ==========================================
  // Filament Management
  // ==========================================

  addFilament(event) {
    if (event) event.preventDefault()
    const plateDiv = event.target.closest('[data-plate-index]')
    this.addFilamentToPlate(plateDiv)
  }

  addFilamentToPlate(plateDiv) {
    const filamentsContainer = plateDiv.querySelector('[data-filaments-container]')
    const filaments = filamentsContainer.querySelectorAll('[data-filament-index]')

    if (filaments.length >= 16) {
      alert("Maximum 16 filaments per plate allowed")
      return
    }

    const template = plateDiv.querySelector('[data-filament-template]')
    const clone = template.content.cloneNode(true)

    const filamentIndex = filaments.length
    const filamentDiv = clone.querySelector('[data-filament-index]')
    filamentDiv.setAttribute('data-filament-index', filamentIndex)

    filamentsContainer.appendChild(clone)
    this.calculate()
  }

  removeFilament(event) {
    event.preventDefault()
    const filamentDiv = event.target.closest('[data-filament-index]')
    const plateDiv = event.target.closest('[data-plate-index]')
    const filamentsContainer = plateDiv.querySelector('[data-filaments-container]')
    const filaments = filamentsContainer.querySelectorAll('[data-filament-index]')

    // Don't allow removing the last filament
    if (filaments.length <= 1) {
      alert("At least one filament per plate is required")
      return
    }

    filamentDiv.remove()
    this.calculate()
  }

  // ==========================================
  // Data Access Methods
  // ==========================================

  getPlates() {
    return Array.from(this.platesContainerTarget.querySelectorAll('[data-plate-index]'))
  }

  getPlateData(plateDiv) {
    const printTime = parseFloat(plateDiv.querySelector('[name*="print_time"]')?.value || 0)
    const prepTime = parseFloat(plateDiv.querySelector('[name*="prep_time"]')?.value || 0)
    const postTime = parseFloat(plateDiv.querySelector('[name*="post_time"]')?.value || 0)
    const powerConsumption = parseFloat(plateDiv.querySelector('[name*="power_consumption"]')?.value || 200)
    const machineCost = parseFloat(plateDiv.querySelector('[name*="machine_cost"]')?.value || 500)
    const payoffYears = parseFloat(plateDiv.querySelector('[name*="payoff_years"]')?.value || 3)
    const prepRate = parseFloat(plateDiv.querySelector('[name*="prep_rate"]')?.value || 20)
    const postRate = parseFloat(plateDiv.querySelector('[name*="post_rate"]')?.value || 20)

    // Get filaments for this plate
    const filamentsContainer = plateDiv.querySelector('[data-filaments-container]')
    const filamentDivs = filamentsContainer.querySelectorAll('[data-filament-index]')
    const filaments = Array.from(filamentDivs).map(filDiv => ({
      weight: parseFloat(filDiv.querySelector('[name*="filament_weight"]')?.value || 0),
      pricePerKg: parseFloat(filDiv.querySelector('[name*="filament_price"]')?.value || 25)
    }))

    return {
      printTime,
      prepTime,
      postTime,
      powerConsumption,
      machineCost,
      payoffYears,
      prepRate,
      postRate,
      filaments
    }
  }

  // ==========================================
  // Utility Methods
  // ==========================================

  formatCurrency(amount) {
    return new Intl.NumberFormat(this.localeValue, {
      style: 'currency',
      currency: this.currencyValue,
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(amount)
  }
}

// Note: Calculation, storage, and export methods are provided by mixins
// - calculate(), calculateFilamentCost(), etc. → CalculatorMixin
// - saveToStorage(), loadFromStorage(), etc. → StorageMixin
// - exportToPDF(), exportToCSV(), showToast() → ExportMixin
