import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    // Initialize Bootstrap collapse on the target element
    this.collapse = new bootstrap.Collapse(this.contentTarget, {
      toggle: false
    })
  }

  toggle(event) {
    event.preventDefault()
    this.collapse.toggle()
  }

  disconnect() {
    if (this.collapse) {
      this.collapse.dispose()
    }
  }
}
