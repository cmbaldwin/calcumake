import { Controller } from "@hotwired/stimulus"

/**
 * Printer Technology Sync Controller
 *
 * Synchronizes the printer's material technology with plate technology toggles.
 * When a printer is selected, all plates are locked to that printer's technology.
 */
export default class extends Controller {
  static targets = ["select"]

  connect() {
    // Check initial state - if a printer is already selected, lock technologies
    this.syncTechnology()
  }

  printerChanged() {
    this.syncTechnology()
  }

  syncTechnology() {
    const selectedOption = this.selectTarget.selectedOptions[0]

    if (!selectedOption || !selectedOption.value) {
      // No printer selected - unlock all plate technologies
      this.unlockAllPlateTechnologies()
      return
    }

    const technology = selectedOption.dataset.technology
    if (technology) {
      // Printer selected - set and lock all plate technologies
      this.setAndLockAllPlateTechnologies(technology)
    }
  }

  setAndLockAllPlateTechnologies(technology) {
    // Find all plate technology controllers and set their technology
    document.querySelectorAll("[data-controller*='plate-technology']").forEach(element => {
      const plateController = this.application.getControllerForElementAndIdentifier(element, "plate-technology")
      if (plateController) {
        plateController.setTechnologyAndLock(technology)
      }
    })

    // Dispatch event for any new plates that get added
    document.dispatchEvent(new CustomEvent("printer-technology-locked", {
      detail: { technology }
    }))
  }

  unlockAllPlateTechnologies() {
    document.querySelectorAll("[data-controller*='plate-technology']").forEach(element => {
      const plateController = this.application.getControllerForElementAndIdentifier(element, "plate-technology")
      if (plateController) {
        plateController.unlock()
      }
    })

    // Dispatch event to unlock
    document.dispatchEvent(new CustomEvent("printer-technology-unlocked"))
  }
}
