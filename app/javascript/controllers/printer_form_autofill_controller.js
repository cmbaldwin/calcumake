import { Controller } from "@hotwired/stimulus"

// Auto-populates printer form fields from selected profile
// Connects to data-controller="printer-form-autofill"
export default class extends Controller {
  static targets = ["name", "manufacturer", "technology", "powerConsumption", "cost"]

  // Populate form fields from profile data
  populate(event) {
    const { profile } = event.detail

    // Set name to display name (user can edit)
    if (this.hasNameTarget && profile.display_name) {
      this.nameTarget.value = profile.display_name
    }

    // Set manufacturer (try to match existing option)
    if (this.hasManufacturerTarget && profile.manufacturer) {
      const manufacturerSelect = this.manufacturerTarget
      const option = Array.from(manufacturerSelect.options).find(
        opt => opt.value.toLowerCase() === profile.manufacturer.toLowerCase()
      )
      if (option) {
        manufacturerSelect.value = option.value
      }
    }

    // Set technology
    if (this.hasTechnologyTarget && profile.technology) {
      this.technologyTarget.value = profile.technology
      // Dispatch change event to trigger any dependent controllers
      this.technologyTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }

    // Set power consumption
    if (this.hasPowerConsumptionTarget && profile.power_consumption_avg_watts) {
      this.powerConsumptionTarget.value = profile.power_consumption_avg_watts
    }

    // Set cost (USD from profile, user can adjust)
    if (this.hasCostTarget && profile.cost_usd) {
      this.costTarget.value = profile.cost_usd
    }

    // Highlight filled fields briefly
    this.highlightFields()
  }

  // Clear populated fields
  clear() {
    // Only clear fields that would be auto-filled
    // Leave other user-entered data intact
  }

  // Visual feedback for auto-filled fields
  highlightFields() {
    const targets = [
      this.hasNameTarget && this.nameTarget,
      this.hasManufacturerTarget && this.manufacturerTarget,
      this.hasTechnologyTarget && this.technologyTarget,
      this.hasPowerConsumptionTarget && this.powerConsumptionTarget,
      this.hasCostTarget && this.costTarget
    ].filter(Boolean)

    targets.forEach(target => {
      target.classList.add("autofill-highlight")
      setTimeout(() => {
        target.classList.remove("autofill-highlight")
      }, 1500)
    })
  }
}
