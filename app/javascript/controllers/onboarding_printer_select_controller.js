import { Controller } from "@hotwired/stimulus"

// Manages printer selection in the onboarding wizard
export default class extends Controller {
  static targets = ["printerModel", "submit"]

  selectPrinter(event) {
    const card = event.currentTarget
    const model = card.dataset.printerModel

    // Remove selected state from all cards
    this.element.querySelectorAll('.printer-quick-select').forEach(c => {
      c.classList.remove('selected')
    })

    // Add selected state to clicked card
    card.classList.add('selected')

    // Set the hidden field value
    this.printerModelTarget.value = model

    // Enable submit button
    this.submitTarget.disabled = false
  }
}
