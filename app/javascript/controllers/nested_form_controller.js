import { Controller } from "@hotwired/stimulus"

// Backward-compatible nested form controller that uses dynamic-list as an outlet
export default class extends Controller {
  static outlets = ["dynamic-list"]

  static values = {
    maxItems: { type: Number, default: 10 },
    minItems: { type: Number, default: 1 },
    itemName: { type: String, default: "plate" },
    addButtonText: { type: String, default: "Add Plate" }
  }

  connect() {
    // Don't update buttons until outlet connects
  }

  dynamicListOutletConnected(dynamicListController) {
    // Configure the dynamic list with our values
    dynamicListController.maxItemsValue = this.maxItemsValue
    dynamicListController.minItemsValue = this.minItemsValue
    dynamicListController.itemNameValue = this.itemNameValue
    dynamicListController.addButtonTextValue = this.addButtonTextValue

    // Now that outlet is connected, update remove buttons
    this.updateRemoveButtons()
  }

  // Backward compatibility method - delegates to dynamic-list outlet
  updateRemoveButtons() {
    this.dynamicListOutlets.forEach(outlet => outlet.updateControls())
  }

  // Delegate add method to dynamic-list outlet
  add(event) {
    if (this.dynamicListOutlets.length > 0) {
      this.dynamicListOutlets[0].add(event)
    }
  }

  // Delegate remove method to dynamic-list outlet
  remove(event) {
    if (this.dynamicListOutlets.length > 0) {
      this.dynamicListOutlets[0].remove(event)
    }
  }
}
