import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static outlets = ["dynamic-list"]
  static targets = ["filamentSelect"]
  static values = {
    maxItems: { type: Number, default: 16 },
    minItems: { type: Number, default: 1 },
    itemName: { type: String, default: "filament" },
    addButtonText: { type: String, default: "Add Filament" },
    currencySymbol: { type: String, default: "$" }
  }

  connect() {
    // Don't update filament selects until outlet connects
  }

  dynamicListOutletConnected(dynamicListController) {
    // Configure the dynamic list with our values
    dynamicListController.maxItemsValue = this.maxItemsValue
    dynamicListController.minItemsValue = this.minItemsValue
    dynamicListController.itemNameValue = "filament-item" // Use our custom selector
    dynamicListController.addButtonTextValue = this.addButtonTextValue

    // Store bound functions for proper cleanup
    this.boundHandleItemAdded = this.handleItemAdded.bind(this)
    this.boundHandleItemRemoved = this.handleItemRemoved.bind(this)

    // Listen for dynamic list events
    this.element.addEventListener('dynamic-list:item-added', this.boundHandleItemAdded)
    this.element.addEventListener('dynamic-list:item-removed', this.boundHandleItemRemoved)

    // Now that outlet is connected, update filament selects
    this.updateFilamentSelects()
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
    this.updateFilamentSelects()
  }

  handleItemRemoved(event) {
    this.updateFilamentSelects()
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
  // by traversing up from the event target to find the closest outlet element
  findOutletForEvent(event) {
    const button = event.target.closest('[data-action*="filament-list#"]')
    if (!button) return this.dynamicListOutlets[0]

    // Find the closest filament-list container
    const filamentListContainer = button.closest('[data-controller~="filament-list"]')
    if (!filamentListContainer) return this.dynamicListOutlets[0]

    // Find the dynamic-list element within this container
    const dynamicListElement = filamentListContainer.querySelector('[data-controller~="dynamic-list"]')
    if (!dynamicListElement) return this.dynamicListOutlets[0]

    // Find the matching outlet for this element
    return this.dynamicListOutlets.find(outlet => outlet.element === dynamicListElement) || this.dynamicListOutlets[0]
  }

  // Handle filament selection change
  filamentChanged(event) {
    const select = event.target
    const filamentId = select.value

    if (filamentId) {
      this.populateFilamentData(select, filamentId)
    }

    this.updateFilamentSelects()
  }

  // Populate filament data when a filament is selected
  populateFilamentData(select, filamentId) {
    // Find the filament data from the select options
    const selectedOption = select.querySelector(`option[value="${filamentId}"]`)
    if (!selectedOption) return

    const item = select.closest(this.itemSelector)
    if (!item) return

    // Get filament data from data attributes on the option
    const filamentData = {
      name: selectedOption.textContent,
      costPerGram: selectedOption.dataset.costPerGram,
      materialType: selectedOption.dataset.materialType,
      diameter: selectedOption.dataset.diameter
    }

    // Update any display elements with filament data
    const nameDisplay = item.querySelector('[data-filament-name]')
    if (nameDisplay) {
      nameDisplay.textContent = filamentData.name
    }

    const costDisplay = item.querySelector('[data-filament-cost]')
    if (costDisplay && filamentData.costPerGram) {
      costDisplay.textContent = `${this.currencySymbolValue}${filamentData.costPerGram}/g`
    }

    // Trigger weight calculation if weight field exists
    const weightField = item.querySelector('input[name*="filament_weight"]')
    if (weightField && weightField.value) {
      this.calculateCost(item)
    }
  }

  // Calculate total cost for a filament item
  calculateCost(item) {
    const select = item.querySelector('select[name*="filament_id"]')
    const weightField = item.querySelector('input[name*="filament_weight"]')
    const costDisplay = item.querySelector('[data-total-cost]')

    if (!select || !weightField || !costDisplay) return

    const selectedOption = select.querySelector(`option[value="${select.value}"]`)
    const costPerGram = selectedOption?.dataset.costPerGram
    const weight = parseFloat(weightField.value)

    if (costPerGram && weight && weight > 0) {
      const totalCost = (parseFloat(costPerGram) * weight).toFixed(2)
      costDisplay.textContent = `${this.currencySymbolValue}${totalCost}`
    } else {
      costDisplay.textContent = `${this.currencySymbolValue}0.00`
    }
  }

  // Handle weight field changes
  weightChanged(event) {
    const item = event.target.closest(this.itemSelector)
    if (item) {
      this.calculateCost(item)
    }
  }

  // Update filament select dropdowns to prevent duplicate selections within this plate
  updateFilamentSelects() {
    // Update selects for each dynamic-list outlet (each plate)
    this.dynamicListOutlets.forEach(outlet => {
      const container = outlet.containerTarget
      if (!container) return

      const selects = container.querySelectorAll('select[name*="filament_id"]')
      const selectedFilaments = new Set()

      // Collect all selected filament IDs within this plate
      selects.forEach(select => {
        const item = select.closest(this.itemSelector)
        if (item && !item.style.display.includes('none') && !item.classList.contains('marked-for-destruction')) {
          if (select.value) {
            selectedFilaments.add(select.value)
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
          if (option.value === '') return // Keep the empty option enabled

          if (selectedFilaments.has(option.value) && option.value !== currentValue) {
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

  // Override the item selector for filament items
  get itemSelector() {
    return '[data-filament-item]'
  }
}