import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["content", "form"]
  static values = {
    autoOpen: { type: Boolean, default: false }
  }

  connect() {
    // Initialize Bootstrap modal
    this.modal = new bootstrap.Modal(this.element, {
      backdrop: true,
      keyboard: true,
      focus: true
    })

    // Auto-open if the value is set (useful for turbo-stream responses)
    if (this.autoOpenValue) {
      this.open()
    }

    // Listen for Bootstrap's hidden event to clean up
    this.element.addEventListener('hidden.bs.modal', this.handleHidden.bind(this))
  }

  disconnect() {
    // Clean up when controller is disconnected
    if (this.modal) {
      this.element.removeEventListener('hidden.bs.modal', this.handleHidden.bind(this))
      this.modal.dispose()
    }
  }

  // Open the modal
  open(event) {
    // Prevent default link behavior if called from a link
    if (event) {
      event.preventDefault()
    }

    this.modal.show()
  }

  // Close the modal
  close(event) {
    if (event) {
      event.preventDefault()
    }
    this.modal.hide()
  }

  // Handle Bootstrap's hidden event
  handleHidden() {
    // Reset modal content when fully hidden
    // This prevents stale content from appearing on next open
    if (this.hasContentTarget) {
      // We don't clear the content immediately as it might be needed
      // Turbo will replace it when a new modal is opened
    }
  }

  // Handle Turbo form submission
  handleSubmit(event) {
    const { success, fetchResponse } = event.detail

    // Only handle successful submissions (2xx status codes)
    if (success) {
      // Check if the response is a redirect (meaning form was valid)
      // or a re-render (meaning there were validation errors)
      if (fetchResponse) {
        const contentType = fetchResponse.response.headers.get("Content-Type")

        // If it's a turbo-stream response, let it handle the modal state
        // Otherwise, check if it's a successful HTML response (redirect)
        if (contentType && contentType.includes("text/html")) {
          // This means we got redirected after successful save
          // The turbo-stream will handle closing the modal
        }
      }
    }
  }

  // Handle frame load events
  frameLoaded(event) {
    // When a frame is loaded, check if we should open the modal
    // This is triggered when loading content into the modal frame
    if (!this.modal._isShown) {
      this.open()
    }
  }

  // Handle form errors
  // This method can be called from the form to indicate errors
  showErrors() {
    // Keep modal open when there are errors
    // The form will be re-rendered with error messages
  }
}
