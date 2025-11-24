# frozen_string_literal: true

require "test_helper"

class Invoices::StatusBadgeComponentTest < ViewComponent::TestCase
  test "renders paid status badge" do
    invoice = invoices(:one)
    invoice.status = "paid"
    render_inline(Invoices::StatusBadgeComponent.new(invoice: invoice))

    assert_selector "span.badge.bg-success"
    assert_text I18n.t("invoices.status.paid")
  end

  test "renders sent status badge" do
    invoice = invoices(:two)
    render_inline(Invoices::StatusBadgeComponent.new(invoice: invoice))

    assert_selector "span.badge.bg-info"
    assert_text I18n.t("invoices.status.sent")
  end

  test "renders cancelled status badge" do
    invoice = invoices(:one)
    invoice.status = "cancelled"
    render_inline(Invoices::StatusBadgeComponent.new(invoice: invoice))

    assert_selector "span.badge.bg-danger"
    assert_text I18n.t("invoices.status.cancelled")
  end

  test "renders draft status badge with secondary variant" do
    invoice = invoices(:one) # status is draft
    render_inline(Invoices::StatusBadgeComponent.new(invoice: invoice))

    assert_selector "span.badge.bg-secondary"
    assert_text I18n.t("invoices.status.draft")
  end

  test "applies custom size" do
    invoice = invoices(:one)
    invoice.status = "paid"
    render_inline(Invoices::StatusBadgeComponent.new(invoice: invoice, size: "lg"))

    assert_selector "span.badge.fs-4" # lg size = fs-4
  end

  test "default size is fs-6" do
    invoice = invoices(:one)
    invoice.status = "paid"
    render_inline(Invoices::StatusBadgeComponent.new(invoice: invoice))

    assert_selector "span.badge.fs-6"
  end

  test "supports empty string size for no font size class" do
    invoice = invoices(:one)
    invoice.status = "paid"
    render_inline(Invoices::StatusBadgeComponent.new(invoice: invoice, size: ""))

    assert_selector "span.badge.bg-success"
    refute_selector "span.badge.fs-6"
  end

  test "variant_for_status returns correct variant" do
    component = Invoices::StatusBadgeComponent.new(invoice: invoices(:one))

    assert_equal "success", component.variant_for_status("paid")
    assert_equal "info", component.variant_for_status("sent")
    assert_equal "danger", component.variant_for_status("cancelled")
    assert_equal "secondary", component.variant_for_status("draft")
    assert_equal "secondary", component.variant_for_status("unknown")
  end

  test "size_class returns correct Bootstrap class" do
    component = Invoices::StatusBadgeComponent.new(invoice: invoices(:one))

    assert_equal "fs-6", component.size_class("md")
    assert_equal "fs-7", component.size_class("sm")
    assert_equal "fs-4", component.size_class("lg")
    assert_equal "", component.size_class("")
    assert_equal "fs-6", component.size_class(nil)
  end
end
