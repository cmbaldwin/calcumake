import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["content", "form"]
  static values = {
    autoOpen: { type: Boolean, default: false }
  }

  connect() {
    console.log('Modal controller connected')
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
    console.log('Opening modal', event)
    // Prevent default link behavior if called from a link
    if (event) {
      event.preventDefault()
    }

    // Check if modal is already shown
    if (!this.element.classList.contains('show')) {
      this.modal.show()
      console.log('Modal.show() called')
    } else {
      console.log('Modal already shown, skipping')
    }
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
    console.log('Form submitted', event.detail)
    const { success } = event.detail

    // Close modal on successful submission
    if (success) {
      console.log('Form successful, closing modal')
      this.close()
    } else {
      console.log('Form had errors, keeping modal open')
    }
  }

  // Close method without event parameter for internal use
  close() {
    this.modal.hide()
  }

  // Handle frame load events
  frameLoaded(event) {
    console.log('Frame loaded event:', event.target)
    // When a frame is loaded, check if we should open the modal
    // This is triggered when loading content into the modal frame
    // Check if the turbo frame that loaded is the modal_content frame
    const frame = event.target
    console.log('Frame ID:', frame?.id)
    if (frame && frame.id === 'modal_content') {
      console.log('Modal content frame loaded, opening modal')
      // Only open if modal is not already shown
      // Use Bootstrap 5's _isShown property or check element classes
      const isShown = this.element.classList.contains('show')
      if (!isShown) {
        this.open()
      }
    }
  }

  // Handle form errors
  // This method can be called from the form to indicate errors
  showErrors() {
    // Keep modal open when there are errors
    // The form will be re-rendered with error messages
  }
}
