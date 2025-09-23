import { Controller } from "@hotwired/stimulus"
import "jspdf"

// Connects to data-controller="pdf-generator"
export default class extends Controller {
  static values = { filename: String }

  connect() {
    console.log("PDF Generator controller connected")
  }

  async generatePDF() {
    try {
      // Create new PDF document
      const pdf = new window.jsPDF({
        orientation: 'portrait',
        unit: 'mm',
        format: 'a4'
      })

      // Get the invoice content
      const invoiceContent = this.element.querySelector('.invoice-content')

      if (!invoiceContent) {
        console.error("Invoice content not found")
        return
      }

      // Store original styles
      const originalStyles = {
        backgroundColor: invoiceContent.style.backgroundColor,
        padding: invoiceContent.style.padding
      }

      // Temporarily set white background for better PDF appearance
      invoiceContent.style.backgroundColor = '#ffffff'
      invoiceContent.style.padding = '20px'

      // Use html2canvas to capture the content as an image
      const canvas = await this.htmlToCanvas(invoiceContent)

      if (canvas) {
        // Calculate dimensions to fit A4 page
        const imgWidth = 210 // A4 width in mm
        const pageHeight = 295 // A4 height in mm
        const imgHeight = (canvas.height * imgWidth) / canvas.width
        let heightLeft = imgHeight

        let position = 0

        // Add the image to PDF
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
        const filename = this.filenameValue || 'invoice'
        const timestamp = new Date().toISOString().slice(0, 10)
        const finalFilename = `${filename}-${timestamp}.pdf`

        // Save the PDF
        pdf.save(finalFilename)

        console.log(`PDF generated successfully: ${finalFilename}`)
      }

      // Restore original styles
      invoiceContent.style.backgroundColor = originalStyles.backgroundColor
      invoiceContent.style.padding = originalStyles.padding

    } catch (error) {
      console.error("Error generating PDF:", error)
      alert("Error generating PDF. Please try again or use the browser's print function.")
    }
  }

  // Helper method to convert HTML to canvas using html2canvas
  async htmlToCanvas(element) {
    try {
      // Dynamically import html2canvas
      const html2canvas = await import('html2canvas')

      return await html2canvas.default(element, {
        scale: 2, // Higher scale for better quality
        useCORS: true,
        allowTaint: true,
        backgroundColor: '#ffffff',
        logging: false,
        width: element.scrollWidth,
        height: element.scrollHeight,
        onclone: (clonedDoc) => {
          // Ensure all text is visible in the cloned document
          const clonedElement = clonedDoc.querySelector('.invoice-content')
          if (clonedElement) {
            clonedElement.style.transform = 'none'
            clonedElement.style.animation = 'none'
          }
        }
      })
    } catch (error) {
      console.error("Error with html2canvas:", error)
      throw error
    }
  }
}