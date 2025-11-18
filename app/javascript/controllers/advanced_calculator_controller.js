import { Controller } from "@hotwired/stimulus"
import { jsPDF } from "jspdf"

// Connects to data-controller="advanced-calculator"
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
    "resultsSection",
    "addPlateButton",
    "exportContent"
  ]

  static values = {
    energyCost: { type: Number, default: 0.12 },
    currency: { type: String, default: "USD" },
    locale: { type: String, default: "en-US" },
    maxPlates: { type: Number, default: 10 }
  }

  connect() {
    console.log("Advanced calculator connected")

    // Load from localStorage if available
    this.loadFromStorage()

    // If no plates exist, add first plate
    if (this.getPlates().length === 0) {
      this.addPlate()
    }

    // Calculate initial totals
    this.calculate()

    // Set up auto-save
    this.setupAutoSave()
  }

  disconnect() {
    if (this.autoSaveInterval) {
      clearInterval(this.autoSaveInterval)
    }
  }

  setupAutoSave() {
    // Auto-save to localStorage every 10 seconds
    this.autoSaveInterval = setInterval(() => {
      this.saveToStorage()
    }, 10000)
  }

  addPlate(event) {
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
    this.addFilament({ target: plateDiv.querySelector('[data-action*="addFilament"]') })

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

  addFilament(event) {
    event.preventDefault()
    const plateDiv = event.target.closest('[data-plate-index]')
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

  calculate() {
    const plates = this.getPlates()

    let totalFilamentCost = 0
    let totalElectricityCost = 0
    let totalLaborCost = 0
    let totalMachineCost = 0

    plates.forEach(plate => {
      const plateData = this.getPlateData(plate)

      // Filament costs
      totalFilamentCost += this.calculateFilamentCost(plateData)

      // Electricity cost
      totalElectricityCost += this.calculateElectricityCost(plateData)

      // Labor cost
      totalLaborCost += this.calculateLaborCost(plateData)

      // Machine cost (depreciation)
      totalMachineCost += this.calculateMachineCost(plateData)
    })

    // Other costs
    const failureRate = parseFloat(this.element.querySelector('[name="failure_rate"]')?.value || 0)
    const shippingCost = parseFloat(this.element.querySelector('[name="shipping_cost"]')?.value || 0)
    const otherCost = parseFloat(this.element.querySelector('[name="other_cost"]')?.value || 0)

    const totalOtherCosts = shippingCost + otherCost

    // Calculate subtotal before failure rate
    const subtotal = totalFilamentCost + totalElectricityCost + totalLaborCost + totalMachineCost + totalOtherCosts

    // Apply failure rate
    const failureCost = subtotal * (failureRate / 100)

    // Grand total
    const grandTotal = subtotal + failureCost

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

    // Animate results
    if (this.hasResultsSectionTarget) {
      this.resultsSectionTarget.style.transform = "scale(1.01)"
      setTimeout(() => {
        this.resultsSectionTarget.style.transform = "scale(1)"
      }, 150)
    }

    // Auto-save to storage
    this.saveToStorage()
  }

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

  calculateFilamentCost(plateData) {
    return plateData.filaments.reduce((total, filament) => {
      const weightKg = filament.weight / 1000
      return total + (weightKg * filament.pricePerKg)
    }, 0)
  }

  calculateElectricityCost(plateData) {
    const powerKw = plateData.powerConsumption / 1000
    return plateData.printTime * powerKw * this.energyCostValue
  }

  calculateLaborCost(plateData) {
    const prepCost = plateData.prepTime * plateData.prepRate
    const postCost = plateData.postTime * plateData.postRate
    return prepCost + postCost
  }

  calculateMachineCost(plateData) {
    // Calculate hourly machine cost based on payoff period
    const totalHoursPerYear = 365 * 8 // Assume 8 hours/day usage
    const totalHoursPayoff = totalHoursPerYear * plateData.payoffYears
    const costPerHour = plateData.machineCost / totalHoursPayoff
    return plateData.printTime * costPerHour
  }

  updateAddPlateButton() {
    if (this.hasAddPlateButtonTarget) {
      const plates = this.getPlates()
      this.addPlateButtonTarget.disabled = plates.length >= this.maxPlatesValue
    }
  }

  // Local Storage Methods
  saveToStorage() {
    const data = {
      jobName: this.hasJobNameTarget ? this.jobNameTarget.value : '',
      plates: this.getPlates().map(plate => this.getPlateDataForStorage(plate)),
      failureRate: parseFloat(this.element.querySelector('[name="failure_rate"]')?.value || 0),
      shippingCost: parseFloat(this.element.querySelector('[name="shipping_cost"]')?.value || 0),
      otherCost: parseFloat(this.element.querySelector('[name="other_cost"]')?.value || 0),
      timestamp: new Date().toISOString()
    }

    try {
      localStorage.setItem('calcumake_advanced_calculator', JSON.stringify(data))
    } catch (e) {
      console.error("Failed to save to localStorage:", e)
    }
  }

  loadFromStorage() {
    try {
      const saved = localStorage.getItem('calcumake_advanced_calculator')
      if (!saved) return

      const data = JSON.parse(saved)

      // Restore job name
      if (this.hasJobNameTarget && data.jobName) {
        this.jobNameTarget.value = data.jobName
      }

      // Restore other fields
      if (data.failureRate !== undefined) {
        const failureField = this.element.querySelector('[name="failure_rate"]')
        if (failureField) failureField.value = data.failureRate
      }
      if (data.shippingCost !== undefined) {
        const shippingField = this.element.querySelector('[name="shipping_cost"]')
        if (shippingField) shippingField.value = data.shippingCost
      }
      if (data.otherCost !== undefined) {
        const otherField = this.element.querySelector('[name="other_cost"]')
        if (otherField) otherField.value = data.otherCost
      }

      // Note: Plates will be restored after they're added in connect()
      // This is a simplified version - full implementation would restore all plate data

    } catch (e) {
      console.error("Failed to load from localStorage:", e)
    }
  }

  getPlateDataForStorage(plateDiv) {
    const plateData = this.getPlateData(plateDiv)
    return {
      ...plateData,
      filaments: plateData.filaments
    }
  }

  clearStorage() {
    if (confirm("Are you sure you want to clear all saved data?")) {
      localStorage.removeItem('calcumake_advanced_calculator')
      window.location.reload()
    }
  }

  // Export Methods
  async exportToPDF(event) {
    event.preventDefault()

    try {
      const pdf = new jsPDF({
        orientation: 'portrait',
        unit: 'mm',
        format: 'a4'
      })

      const content = this.exportContentTarget

      // Temporarily show content if hidden
      const wasHidden = content.style.display === 'none'
      if (wasHidden) {
        content.style.display = 'block'
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
      }

      // Calculate dimensions
      const imgWidth = 210 // A4 width
      const pageHeight = 295 // A4 height
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

  // Utility Methods
  formatCurrency(amount) {
    return new Intl.NumberFormat(this.localeValue, {
      style: 'currency',
      currency: this.currencyValue,
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(amount)
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
      border-radius: 0.375rem;
      box-shadow: 0 0.5rem 1rem rgba(0,0,0,0.15);
      z-index: 9999;
      animation: slideIn 0.3s ease-out;
    `

    document.body.appendChild(toast)

    setTimeout(() => {
      toast.style.animation = 'slideOut 0.3s ease-out'
      setTimeout(() => toast.remove(), 300)
    }, 3000)
  }
}
