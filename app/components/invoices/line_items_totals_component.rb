# frozen_string_literal: true

module Invoices
  # LineItemsTotalsComponent displays invoice subtotal and total
  #
  # Usage:
  #   <%= render Invoices::LineItemsTotalsComponent.new(
  #     invoice: @invoice,
  #     currency: @invoice.currency
  #   ) %>
  #
  # Parameters:
  #   invoice: Invoice model with subtotal and total methods
  #   currency: Currency code for formatting (e.g., "USD", "JPY")
  #   wrapper_class: Optional CSS class for wrapper div (default: "mt-4 pt-3 border-top")
  #   table_class: Optional CSS class for table (default: "table")
  #
  class LineItemsTotalsComponent < ViewComponent::Base
    def initialize(
      invoice:,
      currency:,
      wrapper_class: "mt-4 pt-3 border-top",
      table_class: "table"
    )
      @invoice = invoice
      @currency = currency
      @wrapper_class = wrapper_class
      @table_class = table_class
    end

    def subtotal
      helpers.formatted_currency_amount(@invoice.subtotal, @currency)
    end

    def total
      helpers.formatted_currency_amount(@invoice.total, @currency)
    end
  end
end
