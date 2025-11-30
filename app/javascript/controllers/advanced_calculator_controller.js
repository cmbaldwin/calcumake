import { Controller } from "@hotwired/stimulus"
import { jsPDF } from "jspdf"

// Advanced 3D Print Pricing Calculator
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
    // Calculate initial values
    this.calculate()
  }

  disconnect() {
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
  // Calculation Methods
  // ==========================================

  calculate() {
    const plates = this.getPlates()
    if (!plates || plates.length === 0) return

    // Get global settings (shared across all plates)
    const globalSettings = this.getGlobalSettings()

    let totalFilamentCost = 0
    let totalElectricityCost = 0
    let totalPrintTime = 0

    plates.forEach(plate => {
      const plateData = this.getPlateData(plate)
      if (!plateData) return // Skip invalid plate data

      // Filament costs (per plate)
      totalFilamentCost += this.calculateFilamentCost(plateData)

      // Accumulate print time for electricity and machine costs
      totalPrintTime += plateData.printTime || 0
    })

    // Calculate electricity cost using total print time and global power settings
    totalElectricityCost = this.calculateElectricityCost(totalPrintTime, globalSettings)

    // Calculate labor cost (once per job, not per plate)
    const totalLaborCost = this.calculateLaborCost(globalSettings)

    // Calculate machine cost using total print time
    const totalMachineCost = this.calculateMachineCost(totalPrintTime, globalSettings)

    // Other costs
    const failureRate = parseFloat(this.hasFailureRateTarget ? this.failureRateTarget.value : (this.element.querySelector('[name="failure_rate"]')?.value || 0))
    const shippingCost = parseFloat(this.hasShippingCostTarget ? this.shippingCostTarget.value : (this.element.querySelector('[name="shipping_cost"]')?.value || 0))
    const otherCost = parseFloat(this.hasOtherCostTarget ? this.otherCostTarget.value : (this.element.querySelector('[name="other_cost"]')?.value || 0))
    // Ensure units is at least 1
    const units = Math.max(1, parseInt(this.hasUnitsTarget ? this.unitsTarget.value : (this.element.querySelector('[name="units"]')?.value || 1)) || 1)

    const totalOtherCosts = shippingCost + otherCost

    // Calculate subtotal before failure rate
    const subtotal = totalFilamentCost + totalElectricityCost + totalLaborCost + totalMachineCost + totalOtherCosts

    // Apply failure rate
    const failureCost = subtotal * (failureRate / 100)

    // Grand total
    const grandTotal = subtotal + failureCost

    // Per unit price (always calculate, display only when units > 1)
    const perUnitPrice = grandTotal / units

    // Update display
    if (this.hasTotalFilamentCostTarget) {
      this.totalFilamentCostTarget.textContent = this.formatCurrency(totalFilamentCost)
    }
    if (this.hasTotalElectricityCostTarget) {
      this.totalElectricityCostTarget.textContent = this.formatCurrency(totalElectricityCost)
    }
    if (this.hasTotalLaborCostTarget) {
      this.totalLaborCostTarget.textContent = this.formatCurrency(totalLaborCost)
    }
    if (this.hasTotalMachineCostTarget) {
      this.totalMachineCostTarget.textContent = this.formatCurrency(totalMachineCost)
    }
    if (this.hasTotalOtherCostsTarget) {
      this.totalOtherCostsTarget.textContent = this.formatCurrency(totalOtherCosts + failureCost)
    }
    if (this.hasGrandTotalTarget) {
      this.grandTotalTarget.textContent = this.formatCurrency(grandTotal)
    }

    // Update per-unit price display
    if (this.hasPerUnitPriceTarget) {
      this.perUnitPriceTarget.textContent = this.formatCurrency(perUnitPrice)
    }
    if (this.hasPerUnitSectionTarget) {
      // Show per-unit section when units > 1
      this.perUnitSectionTarget.style.display = units > 1 ? 'flex' : 'none'
    }

    // Animate results (only if not already animating)
    if (this.hasResultsSectionTarget && !this.isAnimating) {
      this.isAnimating = true
      this.resultsSectionTarget.style.transform = "scale(1.01)"
      this._animationTimeout = setTimeout(() => {
        if (this.hasResultsSectionTarget) {
          this.resultsSectionTarget.style.transform = "scale(1)"
        }
        this.isAnimating = false
      }, 150)
    }
  }

  calculateFilamentCost(plateData) {
    if (!plateData?.filaments || !Array.isArray(plateData.filaments)) return 0
    return plateData.filaments.reduce((total, filament) => {
      const weightKg = (filament?.weight || 0) / 1000
      return total + (weightKg * (filament?.pricePerKg || 0))
    }, 0)
  }

  calculateElectricityCost(totalPrintTime, globalSettings) {
    if (!totalPrintTime || !globalSettings?.powerConsumption) return 0
    const powerKw = globalSettings.powerConsumption / 1000
    return totalPrintTime * powerKw * (this.energyCostValue || 0.12)
  }

  calculateLaborCost(globalSettings) {
    if (!globalSettings) return 0
    const prepCost = (globalSettings.prepTime && globalSettings.prepRate) ?
      (globalSettings.prepTime * globalSettings.prepRate) : 0
    const postCost = (globalSettings.postTime && globalSettings.postRate) ?
      (globalSettings.postTime * globalSettings.postRate) : 0
    return prepCost + postCost
  }

  calculateMachineCost(totalPrintTime, globalSettings) {
    if (!totalPrintTime || !globalSettings?.machineCost || !globalSettings?.payoffYears) return 0

    const totalHoursPerYear = 365 * 8 // Assuming 8 hours/day usage
    const totalHoursPayoff = totalHoursPerYear * globalSettings.payoffYears
    const costPerHour = globalSettings.machineCost / totalHoursPayoff
    return totalPrintTime * costPerHour
  }

  // ==========================================
  // Export Methods
  // ==========================================

  updateExportTemplate() {
    // Update job name in export template
    const jobName = this.hasJobNameTarget ? this.jobNameTarget.value : 'Untitled'
    const exportJobName = this.exportContentTarget.querySelector('[data-export-job-name]')
    if (exportJobName) exportJobName.textContent = jobName

    // Update cost values in export template
    const costs = {
      'filament-cost': this.hasTotalFilamentCostTarget ? this.totalFilamentCostTarget.textContent : '$0.00',
      'electricity-cost': this.hasTotalElectricityCostTarget ? this.totalElectricityCostTarget.textContent : '$0.00',
      'labor-cost': this.hasTotalLaborCostTarget ? this.totalLaborCostTarget.textContent : '$0.00',
      'machine-cost': this.hasTotalMachineCostTarget ? this.totalMachineCostTarget.textContent : '$0.00',
      'other-costs': this.hasTotalOtherCostsTarget ? this.totalOtherCostsTarget.textContent : '$0.00',
      'grand-total': this.hasGrandTotalTarget ? this.grandTotalTarget.textContent : '$0.00'
    }

    Object.entries(costs).forEach(([id, value]) => {
      const element = this.exportContentTarget.querySelector(`[data-export-${id}]`)
      if (element) element.textContent = value
    })
  }

  async exportToPDF(event) {
    event.preventDefault()

    try {
      const pdf = new jsPDF({
        orientation: 'portrait',
        unit: 'mm',
        format: 'a4'
      })

      const content = this.exportContentTarget

      // Populate export template with current values
      this.updateExportTemplate()

      // Temporarily show content if hidden
      const wasHidden = content.style.display === 'none' || content.classList.contains('d-none')
      if (wasHidden) {
        content.style.display = 'block'
        content.classList.remove('d-none')
      }

      // Use html2canvas to capture content
      const html2canvas = await import('html2canvas')
      const canvas = await html2canvas.default(content, {
        scale: 2,
        useCORS: true,
        backgroundColor: '#ffffff',
        logging: false
      })

      if (wasHidden) {
        content.style.display = 'none'
        content.classList.add('d-none')
      }

      // Calculate dimensions
      const imgWidth = 210 // A4 width in mm
      const pageHeight = 295 // A4 height in mm
      const imgHeight = (canvas.height * imgWidth) / canvas.width
      let heightLeft = imgHeight
      let position = 0

      // Add image to PDF
      pdf.addImage(canvas.toDataURL('image/png'), 'PNG', 0, position, imgWidth, imgHeight)
      heightLeft -= pageHeight

      // Add additional pages if needed
      while (heightLeft >= 0) {
        position = heightLeft - imgHeight
        pdf.addPage()
        pdf.addImage(canvas.toDataURL('image/png'), 'PNG', 0, position, imgWidth, imgHeight)
        heightLeft -= pageHeight
      }

      // Generate filename
      const jobName = this.hasJobNameTarget ? this.jobNameTarget.value : 'calculation'
      const timestamp = new Date().toISOString().slice(0, 10)
      const filename = `${jobName.replace(/\s+/g, '_')}-${timestamp}.pdf`

      pdf.save(filename)

      this.showToast("PDF exported successfully!")

    } catch (error) {
      console.error("Error exporting PDF:", error)
      alert("Error exporting PDF. Please try again.")
    }
  }

  exportToCSV(event) {
    event.preventDefault()

    try {
      const plates = this.getPlates()
      const rows = []

      // Header row
      rows.push([
        'Job Name',
        'Plate #',
        'Print Time (hrs)',
        'Filament Weight (g)',
        'Filament Cost',
        'Electricity Cost',
        'Labor Cost',
        'Machine Cost',
        'Total'
      ])

      const jobName = this.hasJobNameTarget ? this.jobNameTarget.value : 'Untitled'

      // Data rows
      plates.forEach((plate, index) => {
        const plateData = this.getPlateData(plate)
        const filamentCost = this.calculateFilamentCost(plateData)
        const electricityCost = this.calculateElectricityCost(plateData)
        const laborCost = this.calculateLaborCost(plateData)
        const machineCost = this.calculateMachineCost(plateData)
        const totalWeight = plateData.filaments.reduce((sum, f) => sum + f.weight, 0)
        const plateTotal = filamentCost + electricityCost + laborCost + machineCost

        rows.push([
          jobName,
          `Plate ${index + 1}`,
          plateData.printTime,
          totalWeight,
          filamentCost.toFixed(2),
          electricityCost.toFixed(2),
          laborCost.toFixed(2),
          machineCost.toFixed(2),
          plateTotal.toFixed(2)
        ])
      })

      // Summary row
      const grandTotal = this.hasGrandTotalTarget ?
        parseFloat(this.grandTotalTarget.textContent.replace(/[^0-9.-]+/g, '')) : 0

      rows.push([])
      rows.push(['Grand Total', '', '', '', '', '', '', '', grandTotal.toFixed(2)])

      // Convert to CSV
      const csv = rows.map(row =>
        row.map(cell => `"${cell}"`).join(',')
      ).join('\n')

      // Download
      const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
      const link = document.createElement('a')
      const url = URL.createObjectURL(blob)
      const timestamp = new Date().toISOString().slice(0, 10)
      const filename = `${jobName.replace(/\s+/g, '_')}-${timestamp}.csv`

      link.setAttribute('href', url)
      link.setAttribute('download', filename)
      link.style.visibility = 'hidden'
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)

      this.showToast("CSV exported successfully!")

    } catch (error) {
      console.error("Error exporting CSV:", error)
      alert("Error exporting CSV. Please try again.")
    }
  }

  showToast(message) {
    // Simple toast notification
    const toast = document.createElement('div')
    toast.className = 'toast-notification'
    toast.textContent = message
    toast.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      background: #28a745;
      color: white;
      padding: 1rem 1.5rem;
      border-radius: 0.5rem;
      box-shadow: 0 0.5rem 1rem rgba(0,0,0,0.15);
      z-index: 9999;
      font-weight: 500;
      animation: slideInRight 0.3s ease-out;
    `

    document.body.appendChild(toast)

    setTimeout(() => {
      toast.style.animation = 'slideOutRight 0.3s ease-in'
      setTimeout(() => toast.remove(), 300)
    }, 3000)
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
