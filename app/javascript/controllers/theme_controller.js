import { Controller } from "@hotwired/stimulus"

// Manages dark/light/auto theme and font-size preferences.
// Applied to <html> element. Persists choices in localStorage.
export default class extends Controller {
  static targets = ["themeIcon"]

  connect() {
    this.applyTheme()
    this.applyFontSize()
    this.updateIcon()

    // Listen for OS theme changes when in auto mode
    this.mediaQuery = window.matchMedia("(prefers-color-scheme: dark)")
    this.mediaQueryHandler = () => this.updateIcon()
    this.mediaQuery.addEventListener("change", this.mediaQueryHandler)
  }

  disconnect() {
    if (this.mediaQuery) {
      this.mediaQuery.removeEventListener("change", this.mediaQueryHandler)
    }
  }

  // Actions
  setTheme(event) {
    event.preventDefault()
    const theme = event.currentTarget.dataset.theme
    if (!["light", "dark", "auto"].includes(theme)) return

    localStorage.setItem("calcumake-theme", theme)
    document.documentElement.setAttribute("data-theme", theme)
    this.updateIcon()
    this.updateActiveStates("theme", theme)
  }

  setFontSize(event) {
    event.preventDefault()
    const size = event.currentTarget.dataset.fontSize
    if (!["small", "medium", "large"].includes(size)) return

    localStorage.setItem("calcumake-font-size", size)
    document.documentElement.setAttribute("data-font-size", size)
    this.updateActiveStates("font-size", size)
  }

  // Private

  applyTheme() {
    const theme = localStorage.getItem("calcumake-theme") || "auto"
    document.documentElement.setAttribute("data-theme", theme)
    this.updateActiveStates("theme", theme)
  }

  applyFontSize() {
    const size = localStorage.getItem("calcumake-font-size") || "small"
    document.documentElement.setAttribute("data-font-size", size)
    this.updateActiveStates("font-size", size)
  }

  updateIcon() {
    if (!this.hasThemeIconTarget) return

    const theme = localStorage.getItem("calcumake-theme") || "auto"
    const icons = { light: "bi-sun", dark: "bi-moon-stars", auto: "bi-circle-half" }
    this.themeIconTarget.className = `bi ${icons[theme] || icons.auto}`
  }

  updateActiveStates(type, value) {
    const selector = type === "theme" ? "[data-theme]" : "[data-font-size]"
    const attr = type === "theme" ? "data-theme" : "data-font-size"

    this.element.querySelectorAll(`.theme-toggle ${selector}`).forEach(el => {
      el.classList.toggle("active", el.getAttribute(attr) === value)
    })
  }
}
