import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="invoice-form"
export default class extends Controller {
  static targets = ["lineItems", "subtotal", "total"]
  static values = {
    currency: String,
    defaultCurrency: String
  }

  // Currencies with zero decimal places
  get zeroDecimalCurrencies() {
    return ['JPY', 'KRW', 'VND', 'CLP', 'TWD']
  }

  get currentCurrency() {
    return this.currencyValue || this.defaultCurrencyValue || 'USD'
  }

  get currencyDecimals() {
    return this.zeroDecimalCurrencies.includes(this.currentCurrency) ? 0 : 2
  }

  get priceStep() {
    return this.currencyDecimals === 0 ? 1 : 0.01
  }

  connect() {
    this.lineItemIndex = this.lineItemsTarget.querySelectorAll('.invoice-line-item-fields').length
    this.attachLineItemListeners()
    // Calculate all line totals on load
    this.updateAllLineTotals()
    // Add blur listeners to round values
    this.attachRoundingListeners()
  }

  addLineItem(event) {
    event.preventDefault()

    const template = `
      <div class="invoice-line-item-fields border rounded p-2 mb-2">
        <div class="row g-2 align-items-end">
          <input type="hidden" name="invoice[invoice_line_items_attributes][${this.lineItemIndex}][order_position]" value="${this.lineItemIndex}">

          <div class="col-md-5">
            <label class="form-label small mb-1">${this.getTranslation('description')}</label>
            <input type="text" name="invoice[invoice_line_items_attributes][${this.lineItemIndex}][description]" class="form-control form-control-sm" required>
          </div>

          <div class="col-6 col-md-2">
            <label class="form-label small mb-1">${this.getTranslation('quantity')}</label>
            <input type="number" name="invoice[invoice_line_items_attributes][${this.lineItemIndex}][quantity]" class="form-control form-control-sm line-item-quantity" step="1" min="1" value="1" required data-action="input->invoice-form#calculateLineTotal">
          </div>

          <div class="col-6 col-md-2">
            <label class="form-label small mb-1">${this.getTranslation('unit_price')}</label>
            <input type="number" name="invoice[invoice_line_items_attributes][${this.lineItemIndex}][unit_price]" class="form-control form-control-sm line-item-price" step="${this.priceStep}" value="0" required data-action="input->invoice-form#calculateLineTotal">
          </div>

          <div class="col-8 col-md-2">
            <label class="form-label small mb-1">${this.getTranslation('total')}</label>
            <input type="text" class="form-control form-control-sm line-item-total bg-light" readonly value="${this.currencyDecimals === 0 ? '0' : '0.00'}">
          </div>

          <div class="col-4 col-md-1 text-end">
            <label class="form-label small mb-1 d-block">&nbsp;</label>
            <button type="button" class="btn btn-sm btn-outline-danger" data-action="click->invoice-form#removeLineItem" title="${this.getTranslation('remove')}">
              <i class="bi bi-trash"></i>
            </button>
          </div>

          <div class="col-12">
            <select name="invoice[invoice_line_items_attributes][${this.lineItemIndex}][line_item_type]" class="form-select form-select-sm">
              <option value="custom">Custom</option>
              <option value="filament">Filament</option>
              <option value="electricity">Electricity</option>
              <option value="labor">Labor</option>
              <option value="machine">Machine</option>
              <option value="other">Other</option>
            </select>
          </div>
        </div>
      </div>
    `

    this.lineItemsTarget.insertAdjacentHTML('beforeend', template)
    this.lineItemIndex++
    this.attachLineItemListeners()
    this.attachRoundingListeners()
    this.updateAllLineTotals()
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
    this.updateLineTotal(container)
  }

  roundValue(event) {
    const input = event.target
    if (input.value) {
      const value = parseFloat(input.value)
      if (!isNaN(value)) {
        input.value = value.toFixed(this.currencyDecimals)
      }
    }
  }

  updateLineTotal(container) {
    const quantity = parseFloat(container.querySelector('.line-item-quantity')?.value) || 0
    const price = parseFloat(container.querySelector('.line-item-price')?.value) || 0
    const total = quantity * price
    const totalField = container.querySelector('.line-item-total')
    if (totalField) {
      totalField.value = total.toFixed(this.currencyDecimals)
    }

    this.updateTotals()
  }

  updateAllLineTotals() {
    this.lineItemsTarget.querySelectorAll('.invoice-line-item-fields').forEach(container => {
      if (container.style.display !== 'none') {
        this.updateLineTotal(container)
      }
    })
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

  attachRoundingListeners() {
    // Add blur listeners to round values when user finishes editing
    this.lineItemsTarget.querySelectorAll('.line-item-price').forEach(input => {
      input.addEventListener('blur', (e) => this.roundValue(e))
      // Also update the step attribute to match currency
      input.step = this.priceStep
    })
  }

  formatCurrency(amount) {
    return amount.toFixed(this.currencyDecimals)
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
