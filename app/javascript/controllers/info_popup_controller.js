import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="info-popup"
export default class extends Controller {
  static values = {
    content: String,
    position: { type: String, default: "top" }
  }

  connect() {
    // Check if info popups are globally enabled
    if (!this.isEnabled()) {
      this.element.style.display = "none"
      return
    }

    // Initialize Bootstrap tooltip
    this.tooltip = new bootstrap.Tooltip(this.element, {
      placement: this.positionValue,
      title: this.contentValue,
      trigger: "hover focus",
      html: false,
      container: "body"
    })

    // Listen for global toggle events
    document.addEventListener("info-popups:toggled", this.handleToggle.bind(this))
  }

  disconnect() {
    // Clean up tooltip and event listener
    if (this.tooltip) {
      this.tooltip.dispose()
    }
    document.removeEventListener("info-popups:toggled", this.handleToggle.bind(this))
  }

  // Check if info popups are enabled (from localStorage or user preference)
  isEnabled() {
    // First check localStorage for immediate client-side state
    const localState = localStorage.getItem("info_popups_enabled")
    if (localState !== null) {
      return localState === "true"
    }

    // Fall back to checking the DOM for server-rendered state
    const toggleElement = document.querySelector("[data-info-popups-enabled]")
    if (toggleElement) {
      return toggleElement.dataset.infoPopupsEnabled === "true"
    }

    // Default to enabled if no preference found
    return true
  }

  // Handle global toggle events
  handleToggle(event) {
    const enabled = event.detail.enabled

    if (enabled) {
      this.element.style.display = ""
      if (!this.tooltip) {
        this.tooltip = new bootstrap.Tooltip(this.element, {
          placement: this.positionValue,
          title: this.contentValue,
          trigger: "hover focus",
          html: false,
          container: "body"
        })
      }
    } else {
      if (this.tooltip) {
        this.tooltip.hide()
        this.tooltip.dispose()
        this.tooltip = null
      }
      this.element.style.display = "none"
    }
  }
}
