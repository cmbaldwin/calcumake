import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal-link"
// This controller dispatches a custom event to open the modal
// Usage: <a href="..." data-controller="modal-link" data-action="click->modal-link#open">
export default class extends Controller {
  open() {
    // Dispatch custom event that modal controller listens for
    document.dispatchEvent(new CustomEvent('open-modal', {
      detail: { trigger: this.element }
    }))
  }
}
