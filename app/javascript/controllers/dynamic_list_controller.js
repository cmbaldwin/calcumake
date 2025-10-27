import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "addButton"]
  static values = {
    maxItems: { type: Number, default: 10 },
    minItems: { type: Number, default: 1 },
    itemName: { type: String, default: "item" },
    addButtonText: { type: String, default: "Add Item" },
    removeButtonText: { type: String, default: "Remove" }
  }

  connect() {
    this.updateControls()
    this.updateAddButtonText()
  }

  add(event) {
    event.preventDefault()

    if (this.atMaxItems()) {
      return
    }

    const timestamp = new Date().getTime()
    const content = this.templateTarget.innerHTML
      .replace(/NEW_RECORD/g, timestamp)
      .replace(/\[new_record\]/g, `[${timestamp}]`)
      .replace(/_new_record_/g, `_${timestamp}_`)

    this.containerTarget.insertAdjacentHTML('beforeend', content)
    this.updateControls()
    this.updateAddButtonText()

    // Dispatch custom event for other controllers to react
    this.dispatch("itemAdded", {
      detail: {
        itemCount: this.visibleItems().length,
        itemType: this.itemNameValue
      }
    })
  }

  remove(event) {
    event.preventDefault()

    if (this.atMinItems()) {
      return
    }

    const item = event.target.closest(this.itemSelector)
    if (!item) return

    // If this is a persisted record, mark it for deletion
    const destroyInput = item.querySelector('input[name*="_destroy"]')
    if (destroyInput) {
      destroyInput.value = '1'
      item.style.display = 'none'
      item.classList.add('marked-for-destruction')
    } else {
      // If it's a new record, just remove it from the DOM
      item.remove()
    }

    this.updateControls()
    this.updateAddButtonText()

    // Dispatch custom event
    this.dispatch("itemRemoved", {
      detail: {
        itemCount: this.visibleItems().length,
        itemType: this.itemNameValue
      }
    })
  }

  // Public method to get current item count
  getItemCount() {
    return this.visibleItems().length
  }

  // Public method to check if we can add more items
  canAddItems() {
    return !this.atMaxItems()
  }

  // Public method to check if we can remove items
  canRemoveItems() {
    return !this.atMinItems()
  }

  private

  get itemSelector() {
    return `[data-${this.itemNameValue}]`
  }

  visibleItems() {
    return this.containerTarget.querySelectorAll(`${this.itemSelector}:not([style*="display: none"]):not(.marked-for-destruction)`)
  }

  atMaxItems() {
    return this.visibleItems().length >= this.maxItemsValue
  }

  atMinItems() {
    return this.visibleItems().length <= this.minItemsValue
  }

  updateControls() {
    this.updateRemoveButtons()
    this.updateAddButton()
  }

  updateRemoveButtons() {
    const removeButtons = this.containerTarget.querySelectorAll('[data-action*="#remove"]')
    const visibleItems = this.visibleItems()
    const canRemove = this.canRemoveItems()

    removeButtons.forEach((button) => {
      const item = button.closest(this.itemSelector)
      // Only show remove button if we can remove items and the item is visible
      if (item && !item.style.display.includes('none') && !item.classList.contains('marked-for-destruction')) {
        // Hide delete button for the first item when we're at minimum count
        const isFirstItem = Array.from(visibleItems).indexOf(item) === 0
        const atMinimum = visibleItems.length <= this.minItemsValue

        if (isFirstItem && atMinimum) {
          button.style.display = 'none'
        } else {
          button.style.display = canRemove ? 'inline-block' : 'none'
        }
      }
    })
  }

  updateAddButton() {
    if (this.hasAddButtonTarget) {
      this.addButtonTarget.disabled = this.atMaxItems()
    }

    // Also update any standalone add buttons
    const addButtons = this.element.querySelectorAll('[data-action*="#add"]')
    addButtons.forEach(button => {
      button.disabled = this.atMaxItems()
    })
  }

  updateAddButtonText() {
    if (this.hasAddButtonTarget) {
      const count = this.visibleItems().length
      const remaining = this.maxItemsValue - count

      if (remaining > 0) {
        this.addButtonTarget.textContent = `${this.addButtonTextValue} (${remaining} remaining)`
      } else {
        this.addButtonTarget.textContent = `Maximum ${this.itemNameValue}s reached`
      }
    }
  }
}