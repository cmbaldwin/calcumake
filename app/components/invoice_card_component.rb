# frozen_string_literal: true

class InvoiceCardComponent < ViewComponent::Base
  def initialize(invoice:, html_options: {})
    @invoice = invoice
    @html_options = html_options
  end

  private

  attr_reader :invoice, :html_options

  def card_classes
    classes = ["card", "mb-3"]
    classes.concat(Array(html_options[:class])) if html_options[:class]
    classes.join(" ")
  end

  def invoice_number_link
    helpers.link_to(
      invoice.invoice_number,
      helpers.print_pricing_invoice_path(invoice.print_pricing, invoice),
      class: "h5 mb-1 text-decoration-none",
      data: { turbo_frame: "_top" }
    )
  end

  def formatted_invoice_date
    I18n.l(invoice.invoice_date, format: :short)
  end

  def status_badge_variant
    case invoice.status
    when "paid" then :success
    when "sent" then :info
    when "cancelled" then :danger
    else :secondary
    end
  end

  def status_text
    I18n.t("invoices.status.#{invoice.status}")
  end

  def formatted_due_date
    invoice.due_date ? I18n.l(invoice.due_date, format: :short) : nil
  end

  def due_date_label
    if invoice.due_date
      "#{I18n.t('invoices.fields.due_date')}: #{formatted_due_date}"
    else
      "#{I18n.t('invoices.fields.due_date')}: -"
    end
  end

  def overdue?
    invoice.overdue?
  end

  def formatted_total
    "#{currency_symbol}#{format_currency(invoice.total, invoice.currency)}"
  end

  def currency_symbol
    helpers.currency_symbol(invoice.currency)
  end

  def format_currency(amount, currency)
    helpers.number_to_currency(amount, unit: "", precision: 2)
  end

  def view_button_attrs
    {
      class: "btn btn-sm btn-outline-secondary",
      data: { turbo_frame: "_top" }
    }
  end

  def edit_button_attrs
    {
      class: "btn btn-sm btn-outline-primary",
      data: { turbo_frame: "_top" }
    }
  end
end
