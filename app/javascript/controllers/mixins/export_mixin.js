// Export Mixin - PDF and CSV export functionality
import { jsPDF } from "jspdf"

export const ExportMixin = {
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
  },

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
}
