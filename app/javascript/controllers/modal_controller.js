import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["content"]

  connect() {
    console.log('Modal controller connected')
    // Initialize Bootstrap modal
    this.modal = new bootstrap.Modal(this.element, {
      backdrop: true,
      keyboard: true,
      focus: true
    })

    // Store bound functions for proper cleanup
    this.boundHandleHidden = this.handleHidden.bind(this)
    this.boundHandleOpenModal = this.handleOpenModal.bind(this)

    // Listen for Bootstrap's hidden event to clean up
    this.element.addEventListener('hidden.bs.modal', this.boundHandleHidden)

    // Listen for custom open-modal event from anywhere in the document
    document.addEventListener('open-modal', this.boundHandleOpenModal)
  }

  disconnect() {
    // Clean up when controller is disconnected
    if (this.modal) {
      this.element.removeEventListener('hidden.bs.modal', this.boundHandleHidden)
      document.removeEventListener('open-modal', this.boundHandleOpenModal)
      this.modal.dispose()
    }
  }

  // Handle custom open-modal event from anywhere
  handleOpenModal(event) {
    console.log('Received open-modal event', event)
    this.openWithLoading()
  }

  // Open the modal and show loading spinner
  openWithLoading(event) {
    console.log('Opening modal with loading spinner')

    // Prevent default if called from a click event
    if (event && event.preventDefault) {
      event.preventDefault()
    }

    // Show loading spinner in modal content
    const modalContent = this.element.querySelector('#modal_content')
    if (modalContent) {
      modalContent.innerHTML = `
        <div class="modal-header">
          <h5 class="modal-title">Loading...</h5>
        </div>
        <div class="modal-body text-center py-5">
          <div class="spinner-border text-primary" role="status">
            <span class="visually-hidden">Loading...</span>
          </div>
          <p class="mt-3 text-muted">Loading form...</p>
        </div>
      `
    }

    // Open the modal immediately
    this.modal.show()
    console.log('Modal opened with loading state')
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
    // Clear modal content when fully hidden to prevent stale content
    const modalContent = this.element.querySelector('#modal_content')
    if (modalContent) {
      modalContent.innerHTML = ''
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
}
