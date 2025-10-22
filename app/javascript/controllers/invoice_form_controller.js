import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="invoice-form"
export default class extends Controller {
  static targets = ["lineItems", "subtotal", "total"]
  static values = {
    currency: String,
    defaultCurrency: String
  }

  connect() {
    this.lineItemIndex = this.lineItemsTarget.querySelectorAll('.invoice-line-item-fields').length
    this.attachLineItemListeners()
  }

  addLineItem(event) {
    event.preventDefault()

    const template = `
      <div class="invoice-line-item-fields border rounded p-3 mb-3">
        <div class="row g-2">
          <input type="hidden" name="invoice[invoice_line_items_attributes][${this.lineItemIndex}][order_position]" value="${this.lineItemIndex}">
          
          <div class="col-md-6">
            <label class="form-label">${this.getTranslation('description')}</label>
            <input type="text" name="invoice[invoice_line_items_attributes][${this.lineItemIndex}][description]" class="form-control" required>
          </div>
          
          <div class="col-md-2">
            <label class="form-label">${this.getTranslation('quantity')}</label>
            <input type="number" name="invoice[invoice_line_items_attributes][${this.lineItemIndex}][quantity]" class="form-control line-item-quantity" step="0.01" value="1" required data-action="input->invoice-form#calculateLineTotal">
          </div>
          
          <div class="col-md-2">
            <label class="form-label">${this.getTranslation('unit_price')}</label>
            <input type="number" name="invoice[invoice_line_items_attributes][${this.lineItemIndex}][unit_price]" class="form-control line-item-price" step="0.01" value="0" required data-action="input->invoice-form#calculateLineTotal">
          </div>
          
          <div class="col-md-2">
            <label class="form-label">${this.getTranslation('total')}</label>
            <div class="readonly-field-container">
              <input type="text" class="form-control line-item-total computed-field" readonly
                     value="Auto-calculated" placeholder="Auto-calculated">
            </div>
          </div>
          
          <div class="col-12">
            <select name="invoice[invoice_line_items_attributes][${this.lineItemIndex}][line_item_type]" class="form-select">
              <option value="custom">Custom</option>
              <option value="filament">Filament</option>
              <option value="electricity">Electricity</option>
              <option value="labor">Labor</option>
              <option value="machine">Machine</option>
              <option value="other">Other</option>
            </select>
          </div>
          
          <div class="col-12">
            <button type="button" class="btn btn-sm btn-danger" data-action="click->invoice-form#removeLineItem">
              <i class="bi bi-trash"></i> ${this.getTranslation('remove')}
            </button>
          </div>
        </div>
      </div>
    `

    this.lineItemsTarget.insertAdjacentHTML('beforeend', template)
    this.lineItemIndex++
    this.attachLineItemListeners()
  }

  removeLineItem(event) {
    event.preventDefault()
    const container = event.target.closest('.invoice-line-item-fields')
    const destroyInput = container.querySelector('input[name*="[_destroy]"]')

    if (destroyInput) {
      destroyInput.value = '1'
      container.style.display = 'none'
    } else {
      container.remove()
    }

    this.updateTotals()
  }

  calculateLineTotal(event) {
    const container = event.target.closest('.invoice-line-item-fields')
    const quantity = parseFloat(container.querySelector('.line-item-quantity').value) || 0
    const price = parseFloat(container.querySelector('.line-item-price').value) || 0
    const total = quantity * price
    container.querySelector('.line-item-total').value = total.toFixed(2)

    this.updateTotals()
  }

  updateTotals() {
    // Calculate subtotal from all visible line items
    let subtotal = 0
    this.lineItemsTarget.querySelectorAll('.invoice-line-item-fields').forEach(container => {
      if (container.style.display !== 'none') {
        const quantity = parseFloat(container.querySelector('.line-item-quantity')?.value) || 0
        const price = parseFloat(container.querySelector('.line-item-price')?.value) || 0
        subtotal += quantity * price
      }
    })

    // Update the display (if targets exist)
    if (this.hasSubtotalTarget) {
      this.subtotalTarget.textContent = this.formatCurrency(subtotal)
    }
    if (this.hasTotalTarget) {
      this.totalTarget.textContent = this.formatCurrency(subtotal)
    }
  }

  attachLineItemListeners() {
    // Add listeners to existing line items that might not have them
    this.lineItemsTarget.querySelectorAll('.line-item-quantity, .line-item-price').forEach(input => {
      if (!input.dataset.action) {
        input.dataset.action = 'input->invoice-form#calculateLineTotal'
      }
    })

    this.lineItemsTarget.querySelectorAll('.remove-line-item').forEach(button => {
      if (!button.dataset.action) {
        button.dataset.action = 'click->invoice-form#removeLineItem'
      }
    })
  }

  formatCurrency(amount) {
    // Simple currency formatting - could be enhanced
    return amount.toFixed(2)
  }

  getTranslation(key) {
    // Fallback translations - these should match your i18n
    const translations = {
      description: 'Description',
      quantity: 'Quantity',
      unit_price: 'Unit Price',
      total: 'Total',
      remove: 'Remove'
    }
    return translations[key] || key
  }
}
