import { Controller } from "@hotwired/stimulus"
import { useCalculator } from "controllers/mixins/calculator_mixin"
import { useStorage } from "controllers/mixins/storage_mixin"
import { useExport } from "controllers/mixins/export_mixin"

// Advanced 3D Print Pricing Calculator
// Uses mixins for separation of concerns:
// - useCalculator: Cost calculations
// - useStorage: LocalStorage persistence
// - useExport: PDF and CSV exports
// Pattern: https://betterstimulus.com/architecture/mixins
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
    "otherCost",
    "materialCostLabel",
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
    // Apply mixins following Better Stimulus pattern
    useCalculator(this)
    useStorage(this)
    useExport(this)

    // Load printer profiles
    this.loadPrinterProfiles()

    // Load saved data
    this.loadFromStorage()

    // Calculate initial values
    this.calculate()

    // Setup auto-save
    this.setupAutoSave()
  }

  disconnect() {
    if (this.autoSaveInterval) {
      clearInterval(this.autoSaveInterval)
    }
    if (this._animationTimeout) {
      clearTimeout(this._animationTimeout)
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
    if (!this.hasPlatesContainerTarget) return []
    return Array.from(this.platesContainerTarget.querySelectorAll('[data-plate-index]'))
  }

  getPlateData(plateDiv) {
    if (!plateDiv) return null

    // Only print time is per-plate now
    const printTime = parseFloat(plateDiv.querySelector('[name*="print_time"]')?.value || 0)

    // Detect which technology is active based on visible fields
    const fdmFields = plateDiv.querySelector('.fdm-fields')
    const resinFields = plateDiv.querySelector('.resin-fields')
    const isFdm = fdmFields && !fdmFields.classList.contains('d-none')
    const isResin = resinFields && !resinFields.classList.contains('d-none')

    // Get filaments for FDM plates
    let filaments = []
    if (isFdm) {
      const filamentsContainer = plateDiv.querySelector('[data-filaments-container]')
      if (filamentsContainer) {
        const filamentDivs = filamentsContainer.querySelectorAll('[data-filament-index]')
        filaments = Array.from(filamentDivs).map(filDiv => ({
          weight: parseFloat(filDiv.querySelector('[name*="filament_weight"]')?.value || 0),
          pricePerKg: parseFloat(filDiv.querySelector('[name*="filament_price"]')?.value || 25)
        }))
      }
    }

    // Get resin data for Resin plates
    let resinData = null
    if (isResin) {
      resinData = {
        volume: parseFloat(plateDiv.querySelector('[name*="resin_volume"]')?.value || 0),
        pricePerLiter: parseFloat(plateDiv.querySelector('[name*="resin_price_per_liter"]')?.value || 0)
      }
    }

    return {
      printTime,
      technology: isFdm ? 'fdm' : 'resin',
      filaments,
      resin: resinData
    }
  }

  // Get global machine/labor settings (shared across all plates)
  getGlobalSettings() {
    return {
      powerConsumption: parseFloat(this.hasPowerConsumptionTarget ? this.powerConsumptionTarget.value : 200),
      machineCost: parseFloat(this.hasMachineCostTarget ? this.machineCostTarget.value : 500),
      payoffYears: parseFloat(this.hasPayoffYearsTarget ? this.payoffYearsTarget.value : 3),
      prepTime: parseFloat(this.hasPrepTimeTarget ? this.prepTimeTarget.value : 15), // minutes
      postTime: parseFloat(this.hasPostTimeTarget ? this.postTimeTarget.value : 15), // minutes
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

  // ==========================================
  // Printer Profile Methods
  // ==========================================

  async loadPrinterProfiles() {
    try {
      const response = await fetch('/printer_profiles.json')
      const profiles = await response.json()
      this.printerProfiles = profiles

      // Initial load with FDM profiles (default technology)
      this.updatePrinterProfileSelector('fdm')
    } catch (error) {
      console.error('Failed to load printer profiles:', error)
    }
  }

  switchPrintTechnology(event) {
    const technology = event.target.value
    this.updatePrinterProfileSelector(technology)
    this.updatePlateFieldsForTechnology(technology)
  }

  updatePrinterProfileSelector(technology) {
    const selector = this.element.querySelector('[data-printer-profile-selector]')
    if (!selector || !this.printerProfiles || !technology) return

    // Clear existing options except the first one
    selector.innerHTML = '<option value="">-- Select a Common Printer --</option>'

    // Filter profiles by technology
    const filteredProfiles = this.printerProfiles.filter(p => p.technology === technology)

    // Group by category
    const groupedProfiles = this.groupProfilesByCategory(filteredProfiles)

    Object.entries(groupedProfiles).forEach(([category, printers]) => {
      const optgroup = document.createElement('optgroup')
      optgroup.label = category

      printers.forEach(printer => {
        const option = document.createElement('option')
        option.value = JSON.stringify({
          power_consumption: printer.power_consumption,
          cost: printer.cost,
          technology: printer.technology
        })
        option.textContent = `${printer.manufacturer} ${printer.model} (${printer.power_consumption}W, $${printer.cost})`
        optgroup.appendChild(option)
      })

      selector.appendChild(optgroup)
    })
  }

  updatePlateFieldsForTechnology(technology) {
    // Get all plates
    const plates = this.getPlates()

    plates.forEach(plate => {
      const fdmFields = plate.querySelector('.fdm-fields')
      const resinFields = plate.querySelector('.resin-fields')

      if (technology === 'fdm') {
        // Show FDM (filament) fields
        if (fdmFields) fdmFields.classList.remove('d-none')
        if (resinFields) resinFields.classList.add('d-none')
      } else if (technology === 'resin') {
        // Show Resin fields
        if (fdmFields) fdmFields.classList.add('d-none')
        if (resinFields) resinFields.classList.remove('d-none')
      }
    })

    // Update the material cost label in the results section
    if (this.hasMaterialCostLabelTarget) {
      this.materialCostLabelTarget.textContent = technology === 'resin' ? 'Resin Cost' : 'Filament Cost'
    }
  }

  groupProfilesByCategory(profiles) {
    return profiles.reduce((groups, printer) => {
      const category = printer.category || 'Other'
      if (!groups[category]) {
        groups[category] = []
      }
      groups[category].push(printer)
      return groups
    }, {})
  }

  loadPrinterProfile(event) {
    const selector = event.target
    const value = selector.value

    if (!value) return

    try {
      const profile = JSON.parse(value)

      // Update machine settings with profile values
      if (this.hasPowerConsumptionTarget) {
        this.powerConsumptionTarget.value = profile.power_consumption
      }

      if (this.hasMachineCostTarget) {
        this.machineCostTarget.value = profile.cost
      }

      // Auto-update technology toggle based on printer
      if (profile.technology) {
        const techToggle = this.element.querySelector(`input[name="print_technology"][value="${profile.technology}"]`)
        if (techToggle) {
          techToggle.checked = true
          // Update plate fields for the new technology
          this.updatePlateFieldsForTechnology(profile.technology)
        }
      }

      // Recalculate with new values
      this.calculate()

      // Show confirmation message
      const notification = document.createElement('div')
      notification.className = 'alert alert-success alert-dismissible fade show position-fixed top-0 start-50 translate-middle-x mt-3'
      notification.style.zIndex = '9999'
      notification.innerHTML = `
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        <i class="bi bi-check-circle me-2"></i>
        Printer profile loaded successfully!
      `
      document.body.appendChild(notification)

      setTimeout(() => {
        notification.remove()
      }, 3000)

    } catch (error) {
      console.error('Failed to load printer profile:', error)
    }
  }
}
