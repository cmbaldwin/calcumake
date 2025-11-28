import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="info-toggle"
// Manages the global info popups enabled/disabled state
export default class extends Controller {
  static values = {
    enabled: Boolean,
    updateUrl: String
  }

  connect() {
    // Sync with localStorage on initial load
    const localState = localStorage.getItem("info_popups_enabled")
    if (localState !== null) {
      this.enabledValue = localState === "true"
      this.updateToggleUI()
    }
  }

  // Toggle the info popups on/off
  toggle(event) {
    event.preventDefault()

    // Toggle the state
    this.enabledValue = !this.enabledValue

    // Save to localStorage immediately for instant UI response
    localStorage.setItem("info_popups_enabled", this.enabledValue.toString())

    // Update the toggle UI
    this.updateToggleUI()

    // Dispatch custom event to notify all info popup controllers
    const toggleEvent = new CustomEvent("info-popups:toggled", {
      detail: { enabled: this.enabledValue },
      bubbles: true
    })
    document.dispatchEvent(toggleEvent)

    // Send update to server to persist user preference
    if (this.hasUpdateUrlValue) {
      this.updateServerPreference()
    }
  }

  // Update the visual state of the toggle button
  updateToggleUI() {
    const icon = this.element.querySelector("i")
    const text = this.element.querySelector(".toggle-text")

    if (this.enabledValue) {
      // Enabled state
      icon?.classList.remove("bi-eye-slash")
      icon?.classList.add("bi-eye")
      this.element.classList.remove("text-muted")
      this.element.classList.add("text-primary")
      this.element.title = this.element.dataset.disableTitle || "Disable help tooltips"
      if (text) {
        text.textContent = this.element.dataset.enabledText || "Help: On"
      }
    } else {
      // Disabled state
      icon?.classList.remove("bi-eye")
      icon?.classList.add("bi-eye-slash")
      this.element.classList.remove("text-primary")
      this.element.classList.add("text-muted")
      this.element.title = this.element.dataset.enableTitle || "Enable help tooltips"
      if (text) {
        text.textContent = this.element.dataset.disabledText || "Help: Off"
      }
    }
  }

  // Send the preference to the server via fetch
  async updateServerPreference() {
    try {
      const csrfToken = document.querySelector("[name='csrf-token']")?.content

      const response = await fetch(this.updateUrlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify({
          user: {
            info_popups_enabled: this.enabledValue
          }
        })
      })

      if (!response.ok) {
        console.error("Failed to update info popups preference on server")
      }
    } catch (error) {
      console.error("Error updating info popups preference:", error)
    }
  }

  // Called when the enabled value changes
  enabledValueChanged() {
    this.updateToggleUI()
  }
}
