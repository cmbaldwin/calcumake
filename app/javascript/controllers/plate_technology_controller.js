import { Controller } from "@hotwired/stimulus"

/**
 * Plate Technology Controller
 *
 * Manages switching between FDM (filament) and Resin material technologies
 * for individual plates in the print pricing form.
 *
 * When a printer is selected, the technology is locked to match the printer.
 */
export default class extends Controller {
  static targets = ["hiddenField", "toggleButton", "fdmFields", "resinFields", "toggleContainer"]
  static values = {
    current: { type: String, default: "fdm" },
    locked: { type: Boolean, default: false }
  }

  connect() {
    this.updateVisibility()
    this.checkInitialLockState()

    // Listen for printer technology lock/unlock events
    this.boundOnLocked = this.onTechnologyLocked.bind(this)
    this.boundOnUnlocked = this.onTechnologyUnlocked.bind(this)
    document.addEventListener("printer-technology-locked", this.boundOnLocked)
    document.addEventListener("printer-technology-unlocked", this.boundOnUnlocked)
  }

  disconnect() {
    document.removeEventListener("printer-technology-locked", this.boundOnLocked)
    document.removeEventListener("printer-technology-unlocked", this.boundOnUnlocked)
  }

  checkInitialLockState() {
    // Check if a printer is already selected when plate is added
    const printerSelect = document.querySelector("[data-printer-technology-sync-target='select']")
    if (printerSelect && printerSelect.value) {
      const selectedOption = printerSelect.selectedOptions[0]
      if (selectedOption && selectedOption.dataset.technology) {
        this.setTechnologyAndLock(selectedOption.dataset.technology)
      }
    }
  }

  onTechnologyLocked(event) {
    this.setTechnologyAndLock(event.detail.technology)
  }

  onTechnologyUnlocked() {
    this.unlock()
  }

  setTechnology(event) {
    event.preventDefault()

    // Don't allow changes if locked
    if (this.lockedValue) {
      return
    }

    const technology = event.currentTarget.dataset.technology
    this.applyTechnology(technology)
  }

  setTechnologyAndLock(technology) {
    this.applyTechnology(technology)
    this.lockedValue = true
    this.updateLockedState()
  }

  unlock() {
    this.lockedValue = false
    this.updateLockedState()
  }

  applyTechnology(technology) {
    this.currentValue = technology

    // Update hidden field
    if (this.hasHiddenFieldTarget) {
      this.hiddenFieldTarget.value = technology
    }

    // Update toggle button states
    this.toggleButtonTargets.forEach(btn => {
      const btnTech = btn.dataset.technology
      if (btnTech === technology) {
        btn.classList.add("active", "btn-primary")
        btn.classList.remove("btn-outline-secondary")
      } else {
        btn.classList.remove("active", "btn-primary")
        btn.classList.add("btn-outline-secondary")
      }
    })

    this.updateVisibility()
  }

  updateLockedState() {
    this.toggleButtonTargets.forEach(btn => {
      if (this.lockedValue) {
        btn.classList.add("disabled")
        btn.setAttribute("aria-disabled", "true")
        btn.style.pointerEvents = "none"
        btn.style.opacity = "0.7"
      } else {
        btn.classList.remove("disabled")
        btn.removeAttribute("aria-disabled")
        btn.style.pointerEvents = ""
        btn.style.opacity = ""
      }
    })
  }

  updateVisibility() {
    const technology = this.currentValue

    if (this.hasFdmFieldsTarget) {
      this.fdmFieldsTarget.style.display = technology === "fdm" ? "block" : "none"
    }

    if (this.hasResinFieldsTarget) {
      this.resinFieldsTarget.style.display = technology === "resin" ? "block" : "none"
    }
  }
}
