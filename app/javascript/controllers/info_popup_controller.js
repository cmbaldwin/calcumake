import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="info-popup"
// Progressive enhancement: CSS tooltips work by default, Bootstrap enhances on desktop
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

    // Only initialize Bootstrap tooltips on desktop for better UX
    // Mobile devices use CSS-only tooltips or tap events
    if (this.shouldUseBootstrapTooltip()) {
      this.initializeTooltip()
    }

    // Listen for global toggle events
    document.addEventListener("info-popups:toggled", this.handleToggle.bind(this))
  }

  // Lazy initialization of Bootstrap tooltip or popover
  // Mobile: Popover with click/focus trigger (tap-to-show)
  // Desktop: Tooltip with hover trigger
  initializeTooltip() {
    if (this.tooltip) return // Already initialized

    const isMobile = this.isMobile()

    if (isMobile) {
      // Mobile: Use Popover with focus trigger for tap-to-show behavior
      this.tooltip = new bootstrap.Popover(this.element, {
        placement: this.positionValue,
        content: this.contentValue,
        trigger: "focus", // Tap icon to show, tap away to hide
        html: false,
        container: "body"
      })
    } else {
      // Desktop: Use Tooltip with hover
      this.tooltip = new bootstrap.Tooltip(this.element, {
        placement: this.positionValue,
        title: this.contentValue,
        trigger: "hover focus",
        html: false,
        container: "body",
        delay: { show: 200, hide: 0 } // Slight delay to prevent accidental triggers
      })
    }
  }

  // Determine if we should use Bootstrap tooltips/popovers
  shouldUseBootstrapTooltip() {
    // Use Popover on mobile (tap-to-show)
    // Use Tooltip on desktop (hover)

    // Still skip if user prefers reduced motion
    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    if (prefersReducedMotion) return false

    // Use Bootstrap on all devices now (mobile gets popovers)
    return true
  }

  // Helper to detect mobile devices
  isMobile() {
    return window.innerWidth < 768
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
      // Only initialize Bootstrap tooltip if conditions are met
      if (this.shouldUseBootstrapTooltip()) {
        this.initializeTooltip()
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

