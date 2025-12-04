import { Controller } from "@hotwired/stimulus"
import { usePDF } from "controllers/mixins/pdf_mixin"

// Connects to data-controller="pdf-generator"
export default class extends Controller {
  static values = { filename: String }

  connect() {
    // Apply PDF mixin
    usePDF(this)
    console.log("PDF Generator controller connected")
  }

  async generatePDF() {
    try {
      // Get the invoice content
      const invoiceContent = this.element.querySelector('.invoice-content')

      if (!invoiceContent) {
        console.error("Invoice content not found")
        return
      }

      // Generate filename
      const filename = this.filenameValue || 'invoice'
      const timestamp = new Date().toISOString().slice(0, 10)
      const finalFilename = `${filename}-${timestamp}.pdf`

      // Use the mixin's createPDF method to generate PDF with high quality (PNG)
      await this.createPDF(invoiceContent, {
        filename: finalFilename,
        orientation: 'portrait',
        multiPage: true
      })

      console.log(`PDF generated successfully: ${finalFilename}`)

    } catch (error) {
      console.error("Error generating PDF:", error)
      alert("Error generating PDF. Please try again or use the browser's print function.")
    }
  }
}