import { Controller } from "@hotwired/stimulus"

/**
 * Technology Toggle Controller
 *
 * Manages switching between FDM (filament) and Resin material technologies
 * in the print pricing form. Automatically syncs with printer selection.
 */
export default class extends Controller {
  static targets = ["printerSelect", "technologyToggle", "fdmFields", "resinFields"]
  static values = {
    printerTechnologies: Object // Map of printer_id -> material_technology
  }

  connect() {
    // Initialize visibility based on current technology
    this.updateFieldsVisibility()

    // Listen for printer selection changes
    if (this.hasPrinterSelectTarget) {
      this.printerSelectTarget.addEventListener("change", this.handlePrinterChange.bind(this))
    }
  }

  // Called when technology toggle is clicked
  toggle(event) {
    const technology = event.currentTarget.dataset.technology
    this.setTechnology(technology)
  }

  // Called when printer selection changes
  handlePrinterChange(event) {
    const printerId = event.target.value
    if (printerId && this.printerTechnologiesValue[printerId]) {
      const technology = this.printerTechnologiesValue[printerId]
      this.setTechnology(technology)
    }
  }

  setTechnology(technology) {
    // Update hidden field
    if (this.hasTechnologyToggleTarget) {
      const hiddenField = this.element.querySelector('input[name*="[material_technology]"]')
      if (hiddenField) {
        hiddenField.value = technology
      }

      // Update toggle button states
      this.technologyToggleTargets.forEach(btn => {
        const btnTech = btn.dataset.technology
        if (btnTech === technology) {
          btn.classList.add("active", "btn-primary")
          btn.classList.remove("btn-outline-secondary")
        } else {
          btn.classList.remove("active", "btn-primary")
          btn.classList.add("btn-outline-secondary")
        }
      })
    }

    this.updateFieldsVisibility()
  }

  updateFieldsVisibility() {
    const technology = this.getCurrentTechnology()

    if (this.hasFdmFieldsTarget) {
      this.fdmFieldsTarget.style.display = technology === "fdm" ? "block" : "none"
    }

    if (this.hasResinFieldsTarget) {
      this.resinFieldsTarget.style.display = technology === "resin" ? "block" : "none"
    }
  }

  getCurrentTechnology() {
    const hiddenField = this.element.querySelector('input[name*="[material_technology]"]')
    return hiddenField?.value || "fdm"
  }
}
