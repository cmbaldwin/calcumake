import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static outlets = ["dynamic-list"]
  static targets = ["resinSelect"]
  static values = {
    maxItems: { type: Number, default: 16 },
    minItems: { type: Number, default: 1 },
    itemName: { type: String, default: "resin" },
    addButtonText: { type: String, default: "Add Resin" },
    currencySymbol: { type: String, default: "$" }
  }

  connect() {
    // Don't update resin selects until outlet connects
  }

  dynamicListOutletConnected(dynamicListController) {
    // Configure the dynamic list with our values
    dynamicListController.maxItemsValue = this.maxItemsValue
    dynamicListController.minItemsValue = this.minItemsValue
    dynamicListController.itemNameValue = "resin-item" // Use our custom selector
    dynamicListController.addButtonTextValue = this.addButtonTextValue

    // Store bound functions for proper cleanup
    this.boundHandleItemAdded = this.handleItemAdded.bind(this)
    this.boundHandleItemRemoved = this.handleItemRemoved.bind(this)

    // Listen for dynamic list events
    this.element.addEventListener('dynamic-list:item-added', this.boundHandleItemAdded)
    this.element.addEventListener('dynamic-list:item-removed', this.boundHandleItemRemoved)

    // Now that outlet is connected, update resin selects
    this.updateResinSelects()
  }

  disconnect() {
    // Clean up event listeners
    if (this.boundHandleItemAdded) {
      this.element.removeEventListener('dynamic-list:item-added', this.boundHandleItemAdded)
    }
    if (this.boundHandleItemRemoved) {
      this.element.removeEventListener('dynamic-list:item-removed', this.boundHandleItemRemoved)
    }
  }

  handleItemAdded(event) {
    this.updateResinSelects()
  }

  handleItemRemoved(event) {
    this.updateResinSelects()
  }

  add(event) {
    const outlet = this.findOutletForEvent(event)
    if (outlet) {
      outlet.add(event)
    }
  }

  remove(event) {
    const outlet = this.findOutletForEvent(event)
    if (outlet) {
      outlet.remove(event)
    }
  }

  get containerTarget() {
    return this.dynamicListOutlets.length > 0 ? this.dynamicListOutlets[0].containerTarget : null
  }

  // Find the correct dynamic-list outlet for this event
  findOutletForEvent(event) {
    const button = event.target.closest('[data-action*="resin-list#"]')
    if (!button) return this.dynamicListOutlets[0]

    const resinListContainer = button.closest('[data-controller~="resin-list"]')
    if (!resinListContainer) return this.dynamicListOutlets[0]

    const dynamicListElement = resinListContainer.querySelector('[data-controller~="dynamic-list"]')
    if (!dynamicListElement) return this.dynamicListOutlets[0]

    return this.dynamicListOutlets.find(outlet => outlet.element === dynamicListElement) || this.dynamicListOutlets[0]
  }

  // Handle resin selection change
  resinChanged(event) {
    const select = event.target
    const resinId = select.value

    if (resinId) {
      this.populateResinData(select, resinId)
    }

    this.updateResinSelects()
  }

  // Populate resin data when a resin is selected
  populateResinData(select, resinId) {
    const selectedOption = select.querySelector(`option[value="${resinId}"]`)
    if (!selectedOption) return

    const item = select.closest(this.itemSelector)
    if (!item) return

    const resinData = {
      name: selectedOption.textContent,
      costPerMl: selectedOption.dataset.costPerMl,
      resinType: selectedOption.dataset.resinType
    }

    const nameDisplay = item.querySelector('[data-resin-name]')
    if (nameDisplay) {
      nameDisplay.textContent = resinData.name
    }

    const costDisplay = item.querySelector('[data-resin-cost]')
    if (costDisplay && resinData.costPerMl) {
      costDisplay.textContent = `${this.currencySymbolValue}${parseFloat(resinData.costPerMl).toFixed(3)}/mL`
    }

    // Trigger volume calculation if volume field exists
    const volumeField = item.querySelector('input[name*="resin_volume_ml"]')
    if (volumeField && volumeField.value) {
      this.calculateCost(item)
    }
  }

  // Calculate total cost for a resin item
  calculateCost(item) {
    const select = item.querySelector('select[name*="resin_id"]')
    const volumeField = item.querySelector('input[name*="resin_volume_ml"]')
    const markupField = item.querySelector('input[name*="markup_percentage"]')
    const costDisplay = item.querySelector('[data-total-cost]')

    if (!select || !volumeField || !costDisplay) return

    const selectedOption = select.querySelector(`option[value="${select.value}"]`)
    const costPerMl = selectedOption?.dataset.costPerMl
    const volume = parseFloat(volumeField.value)
    const markup = parseFloat(markupField?.value) || 0

    if (costPerMl && volume && volume > 0) {
      const baseCost = parseFloat(costPerMl) * volume
      const totalCost = (baseCost * (1 + markup / 100)).toFixed(2)
      costDisplay.textContent = `${this.currencySymbolValue}${totalCost}`
    } else {
      costDisplay.textContent = `${this.currencySymbolValue}0.00`
    }
  }

  // Handle volume field changes
  volumeChanged(event) {
    const item = event.target.closest(this.itemSelector)
    if (item) {
      this.calculateCost(item)
    }
  }

  // Update resin select dropdowns to prevent duplicate selections within this plate
  updateResinSelects() {
    this.dynamicListOutlets.forEach(outlet => {
      const container = outlet.containerTarget
      if (!container) return

      const selects = container.querySelectorAll('select[name*="resin_id"]')
      const selectedResins = new Set()

      // Collect all selected resin IDs within this plate
      selects.forEach(select => {
        const item = select.closest(this.itemSelector)
        if (item && !item.style.display.includes('none') && !item.classList.contains('marked-for-destruction')) {
          if (select.value) {
            selectedResins.add(select.value)
          }
        }
      })

      // Update each select to disable already selected options within this plate
      selects.forEach(currentSelect => {
        const currentItem = currentSelect.closest(this.itemSelector)
        if (!currentItem || currentItem.style.display.includes('none') || currentItem.classList.contains('marked-for-destruction')) {
          return
        }

        const currentValue = currentSelect.value
        const options = currentSelect.querySelectorAll('option')

        options.forEach(option => {
          if (option.value === '') return

          if (selectedResins.has(option.value) && option.value !== currentValue) {
            option.disabled = true
            option.textContent = option.textContent.replace(' (already selected)', '') + ' (already selected)'
          } else {
            option.disabled = false
            option.textContent = option.textContent.replace(' (already selected)', '')
          }
        })
      })
    })
  }

  get itemSelector() {
    return '[data-resin-item]'
  }
}
