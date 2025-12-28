import { Controller } from "@hotwired/stimulus"

// Manages printer selection in the onboarding wizard
export default class extends Controller {
  static targets = ["printerModel", "printerProfileId", "submit"]

  connect() {
    // Listen for profile selector events
    this.element.addEventListener("printer-profile-select:selected", this.handleProfileSelected.bind(this))
    this.element.addEventListener("printer-profile-select:cleared", this.handleProfileCleared.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("printer-profile-select:selected", this.handleProfileSelected.bind(this))
    this.element.removeEventListener("printer-profile-select:cleared", this.handleProfileCleared.bind(this))
  }

  selectPrinter(event) {
    const card = event.currentTarget
    const model = card.dataset.printerModel

    // Remove selected state from all cards
    this.element.querySelectorAll('.printer-quick-select').forEach(c => {
      c.classList.remove('selected')
    })

    // Add selected state to clicked card
    card.classList.add('selected')

    // Set the hidden field value for printer model
    this.printerModelTarget.value = model

    // Clear the profile ID since we're using a preset
    if (this.hasPrinterProfileIdTarget) {
      this.printerProfileIdTarget.value = ""
    }

    // Enable submit button
    this.submitTarget.disabled = false
  }

  handleProfileSelected(event) {
    const { profile } = event.detail

    // Remove selected state from all quick select cards
    this.element.querySelectorAll('.printer-quick-select').forEach(c => {
      c.classList.remove('selected')
    })

    // Clear the printer model since we're using a profile
    this.printerModelTarget.value = ""

    // Set the profile ID
    if (this.hasPrinterProfileIdTarget) {
      this.printerProfileIdTarget.value = profile.id
    }

    // Enable submit button
    this.submitTarget.disabled = false
  }

  handleProfileCleared(event) {
    // Clear the profile ID
    if (this.hasPrinterProfileIdTarget) {
      this.printerProfileIdTarget.value = ""
    }

    // Disable submit if no printer model is selected either
    if (!this.printerModelTarget.value) {
      this.submitTarget.disabled = true
    }
  }
}
