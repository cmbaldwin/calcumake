// PDF Mixin - Reusable PDF generation functionality
// Following Better Stimulus pattern: https://betterstimulus.com/architecture/mixins

export const usePDF = controller => {
  Object.assign(controller, {
    /**
     * Generates a PDF from an HTML element using html2canvas and jsPDF
     * @param {HTMLElement} element - The DOM element to convert to PDF
     * @param {Object} options - Configuration options
     * @param {string} options.filename - The name for the downloaded PDF file
     * @param {string} options.orientation - PDF orientation ('portrait' or 'landscape'), defaults to 'portrait'
     * @param {boolean} options.multiPage - Whether to handle multi-page content, defaults to true
     * @returns {Promise<void>}
     */
    async createPDF(element, options = {}) {
      const {
        filename = 'document.pdf',
        orientation = 'portrait',
        multiPage = true
      } = options

      try {
        // Lazy load dependencies
        const { jsPDF } = await import('jspdf')
        const html2canvas = await import('html2canvas')

        // Create PDF document
        const pdf = new jsPDF({
          orientation: orientation,
          unit: 'mm',
          format: 'a4'
        })

        // Store original styles
        const originalStyles = {
          backgroundColor: element.style.backgroundColor,
          padding: element.style.padding
        }

        // Temporarily set white background for better PDF appearance
        element.style.backgroundColor = '#ffffff'
        element.style.padding = '20px'

        // Convert HTML to canvas with optimized settings
        const canvas = await html2canvas.default(element, {
          scale: 2, // Higher scale for better quality
          useCORS: true,
          allowTaint: false,
          backgroundColor: '#ffffff',
          logging: false,
          width: element.scrollWidth,
          height: element.scrollHeight,
          imageTimeout: 0,
          onclone: (clonedDoc) => {
            // Ensure all text is visible in the cloned document
            const clonedElement = clonedDoc.querySelector(':scope')
            if (clonedElement) {
              clonedElement.style.transform = 'none'
              clonedElement.style.animation = 'none'
            }
            // Convert any relative URLs to absolute URLs
            const images = clonedDoc.querySelectorAll('img')
            images.forEach(img => {
              if (img.src && !img.src.startsWith('data:')) {
                const absoluteUrl = new URL(img.src, window.location.origin).href
                img.setAttribute('crossorigin', 'anonymous')
                img.src = absoluteUrl
              }
            })
          }
        })

        // Restore original styles
        element.style.backgroundColor = originalStyles.backgroundColor
        element.style.padding = originalStyles.padding

        // Calculate dimensions to fit A4 page
        const imgWidth = 210 // A4 width in mm
        const pageHeight = 295 // A4 height in mm
        const imgHeight = (canvas.height * imgWidth) / canvas.width
        let heightLeft = imgHeight
        let position = 0

        // Convert canvas to PNG (better quality for invoices/documents)
        const imgData = canvas.toDataURL('image/png')

        // Add the first page
        pdf.addImage(imgData, 'PNG', 0, position, imgWidth, imgHeight)
        heightLeft -= pageHeight

        // Add additional pages if needed and multiPage is enabled
        if (multiPage) {
          while (heightLeft >= 0) {
            position = heightLeft - imgHeight
            pdf.addPage()
            pdf.addImage(imgData, 'PNG', 0, position, imgWidth, imgHeight)
            heightLeft -= pageHeight
          }
        }

        // Save the PDF
        pdf.save(filename)

        return true
      } catch (error) {
        console.error("Error generating PDF:", error)
        throw error
      }
    },

    /**
     * Generates a PDF from HTML content with JPEG compression for smaller file size
     * Use this for user-generated content where file size matters more than perfect quality
     * @param {HTMLElement} element - The DOM element to convert to PDF
     * @param {Object} options - Configuration options
     * @param {string} options.filename - The name for the downloaded PDF file
     * @param {string} options.orientation - PDF orientation ('portrait' or 'landscape'), defaults to 'portrait'
     * @param {number} options.quality - JPEG quality (0-1), defaults to 0.92
     * @param {number} options.scale - Canvas scale factor, defaults to 2
     * @param {boolean} options.multiPage - Whether to handle multi-page content, defaults to true
     * @returns {Promise<void>}
     */
    async createCompressedPDF(element, options = {}) {
      const {
        filename = 'document.pdf',
        orientation = 'portrait',
        quality = 0.92,
        scale = 2,
        multiPage = true
      } = options

      try {
        // Lazy load dependencies
        const { jsPDF } = await import('jspdf')
        const html2canvas = await import('html2canvas')

        // Create PDF document
        const pdf = new jsPDF({
          orientation: orientation,
          unit: 'mm',
          format: 'a4'
        })

        // Convert HTML to canvas with configurable scale
        const canvas = await html2canvas.default(element, {
          scale: scale,
          useCORS: true,
          backgroundColor: '#ffffff',
          logging: false
        })

        // Calculate dimensions to fit A4 page
        const imgWidth = 210 // A4 width in mm
        const pageHeight = 295 // A4 height in mm
        const imgHeight = (canvas.height * imgWidth) / canvas.width
        let heightLeft = imgHeight
        let position = 0

        // Convert canvas to JPEG with compression for smaller file size
        const imgData = canvas.toDataURL('image/jpeg', quality)

        // Add the first page
        pdf.addImage(imgData, 'JPEG', 0, position, imgWidth, imgHeight)
        heightLeft -= pageHeight

        // Add additional pages if needed and multiPage is enabled
        if (multiPage) {
          while (heightLeft >= 0) {
            position = heightLeft - imgHeight
            pdf.addPage()
            pdf.addImage(imgData, 'JPEG', 0, position, imgWidth, imgHeight)
            heightLeft -= pageHeight
          }
        }

        // Save the PDF
        pdf.save(filename)

        return true
      } catch (error) {
        console.error("Error generating compressed PDF:", error)
        throw error
      }
    }
  })
}
