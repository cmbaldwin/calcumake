import { Controller } from "@hotwired/stimulus"

// Reusable search controller for typehead searching
// Connects to data-controller="search"
export default class extends Controller {
  static targets = ["input", "form"]
  static values = {
    url: String,
    debounceDelay: { type: Number, default: 300 }
  }

  connect() {
    this.timeout = null
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  // Handle input changes with debouncing
  search() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    this.timeout = setTimeout(() => {
      this.performSearch()
    }, this.debounceDelayValue)
  }

  // Perform the actual search by submitting the form
  performSearch() {
    if (this.hasFormTarget) {
      this.formTarget.requestSubmit()
    }
  }

  // Clear search
  clear() {
    this.inputTarget.value = ""
    this.performSearch()
  }
}