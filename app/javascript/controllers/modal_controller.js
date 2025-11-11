import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  connect() {
    // Initialize Bootstrap modal
    this.modal = new bootstrap.Modal(this.element)
  }

  disconnect() {
    // Clean up when controller is disconnected
    if (this.modal) {
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
  close() {
    this.modal.hide()
  }

  // Handle form submission
  handleSubmit(event) {
    // If the response is successful (2xx status), close the modal
    if (event.detail.success) {
      // Check if the response contains errors by looking at the frame content
      // We'll close on success, but if there are validation errors, the form will re-render
      const frame = this.element.querySelector('turbo-frame')

      // Small delay to allow Turbo to update the frame
      setTimeout(() => {
        // If no error messages are present, close the modal
        const errorMessages = frame?.querySelector('.alert-danger, .invalid-feedback')
        if (!errorMessages) {
          this.close()
        }
      }, 100)
    }
  }

  // Close modal when clicking backdrop
  clickOutside(event) {
    if (event.target === this.element) {
      this.close()
    }
  }

  // Close modal on ESC key
  closeWithKeyboard(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
