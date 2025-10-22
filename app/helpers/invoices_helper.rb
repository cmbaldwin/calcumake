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

  # Returns a complete status badge with translated text
  def invoice_status_badge(invoice, size: "fs-6")
    content_tag(:span,
      t("invoices.status.#{invoice.status}"),
      class: "badge #{invoice_status_class(invoice)} #{size}"
    )
  end

  # Returns just the status class (for inline use)
  def invoice_status_class(invoice)
    case invoice.status
    when "paid" then "bg-success"
    when "sent" then "bg-info"
    when "cancelled" then "bg-danger"
    else "bg-secondary"
    end
  end

  # Returns formatted currency amount with symbol
  def formatted_currency_amount(amount, currency)
    number_to_currency(amount, unit: currency_symbol(currency))
  end

  # Returns formatted invoice total with currency
  def formatted_invoice_total(invoice)
    formatted_currency_amount(invoice.total, invoice.currency)
  end

  # Returns a human-readable invoice date range
  def invoice_date_range(invoice)
    date_str = l(invoice.invoice_date, format: :short)
    if invoice.due_date
      date_str += " - #{l(invoice.due_date, format: :short)}"
    end
    date_str
  end

  # Returns formatted invoice number preview
  def invoice_number_preview(number)
    "INV-#{number.to_s.rjust(6, '0')}"
  end

  # Returns status options for select field
  def invoice_status_options(current_status = nil)
    options_for_select([
      [ t("invoices.status.draft"), "draft" ],
      [ t("invoices.status.sent"), "sent" ],
      [ t("invoices.status.paid"), "paid" ],
      [ t("invoices.status.cancelled"), "cancelled" ]
    ], current_status)
  end

  # Returns invoice action button classes based on status
  def invoice_action_button_class(invoice, action)
    case action
    when :mark_as_sent
      invoice.status != "draft" ? "btn btn-info disabled" : "btn btn-info"
    when :mark_as_paid
      invoice.status == "draft" ? "btn btn-success disabled" : "btn btn-success"
    else
      "btn btn-outline-secondary"
    end
  end

  # Checks if invoice line items should be editable
  def invoice_line_items_editable?(invoice)
    invoice.new_record? || invoice.status == "draft"
  end
end
