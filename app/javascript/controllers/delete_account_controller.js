import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["unlockCheckbox", "confirmCheckbox", "deleteButton"]

  connect() {
    this.updateButtonState()
  }

  updateButtonState() {
    // Both checkboxes must be checked to enable the delete button
    const unlockChecked = this.unlockCheckboxTarget.checked
    const confirmChecked = this.confirmCheckboxTarget.checked

    this.deleteButtonTarget.disabled = !(unlockChecked && confirmChecked)
  }

  confirmDelete(event) {
    const confirmMessage = this.deleteButtonTarget.dataset.confirmMessage || "Are you sure you want to delete your account? This action cannot be undone."

    if (!confirm(confirmMessage)) {
      event.preventDefault()
      event.stopPropagation()
      return false
    }
  }
}
