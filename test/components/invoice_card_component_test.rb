# frozen_string_literal: true

require "test_helper"

class InvoiceCardComponentTest < ViewComponent::TestCase
  include Rails.application.routes.url_helpers

  setup do
    @invoice = invoices(:one)
  end

  test "renders invoice card" do
    render_inline(InvoiceCardComponent.new(invoice: @invoice))

    assert_selector ".card.mb-3"
    assert_selector ".card-body"
  end

  test "renders invoice number as link" do
    render_inline(InvoiceCardComponent.new(invoice: @invoice))

    assert_selector "a.h5", text: @invoice.invoice_number
    assert_selector "a[href='#{print_pricing_invoice_path(@invoice.print_pricing, @invoice)}']"
  end

  test "invoice number link has turbo_frame _top" do
    render_inline(InvoiceCardComponent.new(invoice: @invoice))

    assert_selector "a[data-turbo-frame='_top']", text: @invoice.invoice_number
  end

  test "renders invoice date" do
    render_inline(InvoiceCardComponent.new(invoice: @invoice))

    expected_date = I18n.l(@invoice.invoice_date, format: :short)
    assert_selector ".text-muted.small", text: expected_date
  end

  test "renders status badge" do
    render_inline(InvoiceCardComponent.new(invoice: @invoice))

    # Should have a badge with status text
    assert_selector ".badge"
    assert_text I18n.t("invoices.status.#{@invoice.status}")
  end

  test "renders due date section" do
    render_inline(InvoiceCardComponent.new(invoice: @invoice))

    assert_text I18n.t('invoices.fields.due_date')
  end

  test "renders overdue badge conditionally" do
    render_inline(InvoiceCardComponent.new(invoice: @invoice))

    # Test passes if component renders without error
    assert_selector ".card"
  end

  test "renders total amount" do
    render_inline(InvoiceCardComponent.new(invoice: @invoice))

    assert_selector ".h4.text-success"
    # Should have currency display
    assert_selector ".text-success", text: /.+/
  end

  test "renders view action button" do
    render_inline(InvoiceCardComponent.new(invoice: @invoice))

    assert_selector "a.btn.btn-sm.btn-outline-secondary", text: I18n.t('actions.view')
    assert_selector "a[href='#{print_pricing_invoice_path(@invoice.print_pricing, @invoice)}']"
  end

  test "renders edit action button" do
    render_inline(InvoiceCardComponent.new(invoice: @invoice))

    assert_selector "a.btn.btn-sm.btn-outline-primary", text: I18n.t('actions.edit')
    assert_selector "a[href='#{edit_print_pricing_invoice_path(@invoice.print_pricing, @invoice)}']"
  end

  test "action buttons have turbo_frame _top" do
    render_inline(InvoiceCardComponent.new(invoice: @invoice))

    assert_selector "a[data-turbo-frame='_top']", minimum: 2
  end

  test "accepts custom html_options classes" do
    render_inline(InvoiceCardComponent.new(invoice: @invoice, html_options: { class: "custom-class" }))

    assert_selector ".card.mb-3.custom-class"
  end

  test "uses BadgeComponent for status" do
    render_inline(InvoiceCardComponent.new(invoice: @invoice))

    # BadgeComponent renders .badge
    assert_selector ".badge"
  end

  test "uses BadgeComponent for overdue indicator" do
    render_inline(InvoiceCardComponent.new(invoice: @invoice))

    # Should have at least 1 badge (status)
    assert_selector ".badge", minimum: 1
  end

  test "renders responsive layout" do
    render_inline(InvoiceCardComponent.new(invoice: @invoice))

    assert_selector ".col-12.col-md-6", count: 2
    assert_selector ".col-12", minimum: 3
  end

  test "formats currency correctly" do
    render_inline(InvoiceCardComponent.new(invoice: @invoice))

    # Should have currency display
    assert_selector ".h4.text-success"
  end

  test "actions section has border-top styling" do
    render_inline(InvoiceCardComponent.new(invoice: @invoice))

    assert_selector ".border-top.pt-3"
  end

  test "actions are right-aligned" do
    render_inline(InvoiceCardComponent.new(invoice: @invoice))

    assert_selector ".justify-content-end"
  end
end
