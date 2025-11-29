import { Controller } from "@hotwired/stimulus"
import { CalculatorMixin } from "controllers/mixins/calculator_mixin"
import { ExportMixin } from "controllers/mixins/export_mixin"
import { StorageMixin } from "controllers/mixins/storage_mixin"

// Constants
const MAX_FILAMENTS_PER_PLATE = 16
const CALCULATION_DEBOUNCE_MS = 100
const ANIMATION_DURATION_MS = 150

// Apply mixins to a base class
const MixedController = class extends Controller { }
Object.assign(MixedController.prototype, CalculatorMixin, ExportMixin, StorageMixin)

/**
 * Advanced 3D Print Pricing Calculator Controller
 *
 * Multi-plate pricing calculator with real-time cost calculations and export functionality.
 * Uses mixin pattern for separation of concerns:
 * - CalculatorMixin: Filament, electricity, labor, and machine cost calculations
 * - ExportMixin: PDF and CSV export with html2canvas + jsPDF
 * - StorageMixin: LocalStorage persistence for auto-save functionality
 *
 * Features:
 * - Supports up to 10 plates per job
 * - Up to 16 filaments per plate
 * - Real-time cost breakdown
 * - Per-unit pricing calculations
 * - Debounced calculation (100ms)
 *
 * @extends {Controller}
 * @mixes CalculatorMixin
 * @mixes ExportMixin
 * @mixes StorageMixin
 */
export default class extends MixedController {
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
    "otherCost",
    // Global machine/labor settings
    "powerConsumption",
    "machineCost",
    "payoffYears",
    "prepTime",
    "postTime",
    "prepRate",
    "postRate"
  ]

  static values = {
    energyCost: { type: Number, default: 0.12 },
    currency: { type: String, default: "USD" },
    locale: { type: String, default: "en-US" },
    maxPlates: { type: Number, default: 10 }
  }

  connect() {
    // Prevent multiple rapid connections (development hot-reload issue)
    if (this._isConnecting) return
    this._isConnecting = true

    // Clear any existing timers from previous connection
    this.cleanup()

    // Initialize debounce timer reference
    this.calculateDebounceTimer = null

    // Initialize with first plate if none exist
    if (this.getPlates().length === 0) {
      this.addPlate()
    }

    // Calculate initial values
    this.calculateImmediate()

    // Mark connection complete
    this._isConnecting = false
  }

  disconnect() {
    this.cleanup()
    this._isConnecting = false
  }

  cleanup() {
    if (this.calculateDebounceTimer) {
      clearTimeout(this.calculateDebounceTimer)
      this.calculateDebounceTimer = null
    }
    // Clear any animation timeouts
    if (this._animationTimeout) {
      clearTimeout(this._animationTimeout)
      this._animationTimeout = null
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

    // Update the visible plate number (index + 1)
    const plateIndexSpan = plateDiv.querySelector('.plate-index')
    if (plateIndexSpan) {
      plateIndexSpan.textContent = plateIndex + 1
    }

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

    if (filaments.length >= MAX_FILAMENTS_PER_PLATE) {
      alert(`Maximum ${MAX_FILAMENTS_PER_PLATE} filaments per plate allowed`)
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
    if (!this.hasPlatesContainerTarget) return []
    return Array.from(this.platesContainerTarget.querySelectorAll('[data-plate-index]'))
  }

  getPlateData(plateDiv) {
    if (!plateDiv) return null

    // Only print time is per-plate now
    const printTime = parseFloat(plateDiv.querySelector('[name*="print_time"]')?.value || 0)

    // Get filaments for this plate
    const filamentsContainer = plateDiv.querySelector('[data-filaments-container]')
    if (!filamentsContainer) return null

    const filamentDivs = filamentsContainer.querySelectorAll('[data-filament-index]')
    const filaments = Array.from(filamentDivs).map(filDiv => ({
      weight: parseFloat(filDiv.querySelector('[name*="filament_weight"]')?.value || 0),
      pricePerKg: parseFloat(filDiv.querySelector('[name*="filament_price"]')?.value || 25)
    }))

    return {
      printTime,
      filaments
    }
  }

  // Get global machine/labor settings (shared across all plates)
  getGlobalSettings() {
    return {
      powerConsumption: parseFloat(this.hasPowerConsumptionTarget ? this.powerConsumptionTarget.value : 200),
      machineCost: parseFloat(this.hasMachineCostTarget ? this.machineCostTarget.value : 500),
      payoffYears: parseFloat(this.hasPayoffYearsTarget ? this.payoffYearsTarget.value : 3),
      prepTime: parseFloat(this.hasPrepTimeTarget ? this.prepTimeTarget.value : 0.25),
      postTime: parseFloat(this.hasPostTimeTarget ? this.postTimeTarget.value : 0.25),
      prepRate: parseFloat(this.hasPrepRateTarget ? this.prepRateTarget.value : 20),
      postRate: parseFloat(this.hasPostRateTarget ? this.postRateTarget.value : 20)
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

// Note: Mixin methods (calculate, saveToStorage, exportToPDF, etc.) are
// inherited from MixedController which has them applied at module load time
