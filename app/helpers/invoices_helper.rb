module InvoicesHelper
  # Returns the appropriate Bootstrap badge class for an invoice status
  def invoice_status_badge_class(invoice)
    base_class = "badge"
    status_class = case invoice.status
    when "paid"
                     "bg-success"
    when "sent"
                     "bg-info"
    when "cancelled"
                     "bg-danger"
    else
                     "bg-secondary"
    end
    "#{base_class} #{status_class}"
  end

  # Returns formatted invoice total with currency
  def formatted_invoice_total(invoice)
    "#{currency_symbol(invoice.currency)}#{format_currency(invoice.total, invoice.currency)}"
  end

  # Returns a human-readable invoice date range
  def invoice_date_range(invoice)
    date_str = l(invoice.invoice_date, format: :short)
    if invoice.due_date
      date_str += " - #{l(invoice.due_date, format: :short)}"
    end
    date_str
  end
end
