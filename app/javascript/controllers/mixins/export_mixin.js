// Export Mixin - PDF and CSV export functionality
// Following Better Stimulus pattern: https://betterstimulus.com/architecture/mixins

import { usePDF } from 'controllers/mixins/pdf_mixin'

export const useExport = controller => {
  // Apply PDF mixin first
  usePDF(controller)

  Object.assign(controller, {
    updateExportTemplate() {
      // Update job name in export template
      const jobName = this.hasJobNameTarget ? this.jobNameTarget.value : 'Untitled'
      const exportJobName = this.exportContentTarget.querySelector('[data-export-job-name]')
      if (exportJobName) exportJobName.textContent = jobName

      // Detect current technology and update material label (only if element exists)
      let currentTech = 'fdm'
      if (this.element) {
        const techInput = this.element.querySelector('input[name="print_technology"]:checked')
        currentTech = techInput?.value || 'fdm'
      }
      const materialLabel = currentTech === 'resin' ? 'Resin Cost' : 'Filament Cost'
      const exportMaterialLabel = this.exportContentTarget.querySelector('[data-export-material-label]')
      if (exportMaterialLabel) exportMaterialLabel.textContent = materialLabel

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
    },

    async exportToPDF(event) {
      event.preventDefault()

      try {
        const content = this.exportContentTarget

        // Populate export template with current values
        this.updateExportTemplate()

        // Temporarily show content if hidden
        const wasHidden = content.style.display === 'none' || content.classList.contains('d-none')
        if (wasHidden) {
          content.style.display = 'block'
          content.classList.remove('d-none')
        }

        // Generate filename
        const jobName = this.hasJobNameTarget ? this.jobNameTarget.value : 'calculation'
        const timestamp = new Date().toISOString().slice(0, 10)
        const filename = `${jobName.replace(/\s+/g, '_')}-${timestamp}.pdf`

        // Use the PDF mixin to generate compressed PDF
        await this.createCompressedPDF(content, {
          filename: filename,
          orientation: 'portrait',
          quality: 0.92,
          scale: 2,
          multiPage: true
        })

        if (wasHidden) {
          content.style.display = 'none'
          content.classList.add('d-none')
        }

        this.showToast("PDF exported successfully!")

      } catch (error) {
        console.error("Error exporting PDF:", error)
        alert("Error exporting PDF. Please try again.")
      }
    },

    exportToCSV(event) {
      event.preventDefault()

      try {
        const plates = this.getPlates()
        const globalSettings = this.getGlobalSettings()
        const rows = []

        // Detect current technology from the toggle (safely)
        let currentTech = 'fdm'
        if (this.element) {
          const techInput = this.element.querySelector('input[name="print_technology"]:checked')
          currentTech = techInput?.value || 'fdm'
        }
        const materialColumn = currentTech === 'resin' ? 'Resin Volume (mL)' : 'Filament Weight (g)'
        const costColumn = currentTech === 'resin' ? 'Resin Cost' : 'Filament Cost'

        // Header row with dynamic material columns
        rows.push([
          'Job Name',
          'Plate #',
          'Print Time (hrs)',
          materialColumn,
          costColumn,
          'Electricity Cost',
          'Labor Cost',
          'Machine Cost',
          'Total'
        ])

        const jobName = this.hasJobNameTarget ? this.jobNameTarget.value : 'Untitled'

        // Calculate totals
        let totalPrintTime = 0
        plates.forEach(plate => {
          const plateData = this.getPlateData(plate)
          totalPrintTime += plateData.printTime || 0
        })

        const totalElectricityCost = this.calculateElectricityCost(totalPrintTime, globalSettings)
        const totalLaborCost = this.calculateLaborCost(globalSettings)
        const totalMachineCost = this.calculateMachineCost(totalPrintTime, globalSettings)

        // Data rows - handle both FDM and Resin
        plates.forEach((plate, index) => {
          const plateData = this.getPlateData(plate)
          const materialCost = this.calculateFilamentCost(plateData)

          // Get material amount based on technology
          let materialAmount = 0
          if (plateData.technology === 'resin' && plateData.resin) {
            materialAmount = plateData.resin.volume || 0
          } else if (plateData.filaments && Array.isArray(plateData.filaments)) {
            materialAmount = plateData.filaments.reduce((sum, f) => sum + (f.weight || 0), 0)
          }

          const plateTotal = materialCost

          rows.push([
            jobName,
            `Plate ${index + 1}`,
            plateData.printTime,
            materialAmount,
            materialCost.toFixed(2),
            '', // Electricity cost shown in summary
            '', // Labor cost shown in summary
            '', // Machine cost shown in summary
            plateTotal.toFixed(2)
          ])
        })

        // Summary rows
        const grandTotal = this.hasGrandTotalTarget ?
          parseFloat(this.grandTotalTarget.textContent.replace(/[^0-9.-]+/g, '')) : 0

        rows.push([])
        rows.push(['', '', '', 'Electricity Cost', totalElectricityCost.toFixed(2), '', '', '', ''])
        rows.push(['', '', '', 'Labor Cost', totalLaborCost.toFixed(2), '', '', '', ''])
        rows.push(['', '', '', 'Machine Cost', totalMachineCost.toFixed(2), '', '', '', ''])
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
    },

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
  })
}
