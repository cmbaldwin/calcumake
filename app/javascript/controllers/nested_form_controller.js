import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template"]
  static values = {
    maxItems: { type: Number, default: 10 }
  }

  connect() {
    this.updateRemoveButtons()
  }

  add(event) {
    event.preventDefault()

    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.containerTarget.insertAdjacentHTML('beforeend', content)
    this.updateRemoveButtons()
  }

  remove(event) {
    event.preventDefault()

    const item = event.target.closest('.nested-form-item')

    // If this is a persisted record, mark it for deletion
    const destroyInput = item.querySelector('input[name*="_destroy"]')
    if (destroyInput) {
      destroyInput.value = '1'
      item.style.display = 'none'
    } else {
      // If it's a new record, just remove it from the DOM
      item.remove()
    }

    this.updateRemoveButtons()
  }

  updateRemoveButtons() {
    const visibleItems = this.containerTarget.querySelectorAll('.nested-form-item:not([style*="display: none"])')
    const removeButtons = this.containerTarget.querySelectorAll('[data-action*="nested-form#remove"]')

    // Show/hide remove buttons based on count (must have at least 1 plate)
    removeButtons.forEach((button, index) => {
      button.style.display = visibleItems.length <= 1 ? 'none' : 'inline-block'
    })

    // Check if we've reached max items
    const addButton = this.element.querySelector('[data-action*="nested-form#add"]')
    if (addButton) {
      addButton.disabled = visibleItems.length >= this.maxItemsValue
    }
  }
}
