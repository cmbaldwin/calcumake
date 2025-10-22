require "test_helper"

class InvoiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @print_pricing = print_pricings(:one)
    @invoice = Invoice.new(
      print_pricing: @print_pricing,
      user: @user,
      invoice_date: Date.current,
      currency: "USD",
      status: "draft"
    )
  end

  # Associations
  test "belongs to print_pricing" do
    assert_respond_to @invoice, :print_pricing
  end

  test "belongs to user" do
    assert_respond_to @invoice, :user
  end

  test "has many invoice_line_items" do
    assert_respond_to @invoice, :invoice_line_items
  end

  test "has one attached company_logo" do
    assert_respond_to @invoice, :company_logo
  end

  # Validations
  test "should be valid with valid attributes" do
    @invoice.invoice_number = "INV-000001"
    assert @invoice.valid?
  end

  test "should require print_pricing" do
    @invoice.print_pricing = nil
    assert_not @invoice.valid?
    assert_includes @invoice.errors[:print_pricing], "must exist"
  end

  test "should require user" do
    @invoice.user = nil
    assert_not @invoice.valid?
    assert_includes @invoice.errors[:user], "must exist"
  end

  test "should auto-generate invoice_number if not provided" do
    @invoice.invoice_number = nil
    @invoice.save!
    assert_not_nil @invoice.invoice_number
    assert_match(/INV-\d{6}/, @invoice.invoice_number)
  end

  test "should require unique invoice_number" do
    @invoice.invoice_number = "INV-000001"
    @invoice.save!

    duplicate_invoice = Invoice.new(
      print_pricing: @print_pricing,
      user: @user,
      invoice_number: "INV-000001",
      invoice_date: Date.current,
      currency: "USD"
    )

    assert_not duplicate_invoice.valid?
    assert_includes duplicate_invoice.errors[:invoice_number], "has already been taken"
  end

  test "should set default invoice_date if not provided" do
    @invoice.invoice_date = nil
    @invoice.save!
    assert_equal Date.current, @invoice.invoice_date
  end

  test "should set default status if not provided" do
    @invoice.status = nil
    @invoice.save!
    assert_equal "draft", @invoice.status
  end

  test "should validate status inclusion" do
    @invoice.invoice_number = "INV-000001"
    @invoice.status = "invalid_status"
    assert_not @invoice.valid?
    assert_includes @invoice.errors[:status], "is not included in the list"
  end

  test "should set default currency if not provided" do
    @invoice.currency = nil
    @invoice.save!
    assert_equal "USD", @invoice.currency
  end

  # Callbacks
  test "should auto-generate invoice_number on create" do
    @invoice.invoice_number = nil
    @invoice.save!
    assert_not_nil @invoice.invoice_number
    assert_match(/INV-\d{6}/, @invoice.invoice_number)
  end

  test "should set defaults on create" do
    invoice = Invoice.create!(
      print_pricing: @print_pricing,
      user: @user
    )

    assert_equal Date.current, invoice.invoice_date
    assert_equal "draft", invoice.status
    assert_not_nil invoice.currency
  end

  # Instance methods
  test "subtotal should sum line item totals" do
    @invoice.invoice_number = "INV-000001"
    @invoice.save!

    @invoice.invoice_line_items.create!(
      description: "Item 1",
      quantity: 2,
      unit_price: 10.00,
      line_item_type: "custom",
      order_position: 0
    )

    @invoice.invoice_line_items.create!(
      description: "Item 2",
      quantity: 1,
      unit_price: 15.00,
      line_item_type: "custom",
      order_position: 1
    )

    assert_equal 35.00, @invoice.subtotal
  end

  test "total should equal subtotal" do
    @invoice.invoice_number = "INV-000001"
    @invoice.save!

    @invoice.invoice_line_items.create!(
      description: "Item 1",
      quantity: 2,
      unit_price: 10.00,
      line_item_type: "custom",
      order_position: 0
    )

    assert_equal @invoice.subtotal, @invoice.total
  end

  test "overdue? should return true when due_date is past and status is not paid" do
    @invoice.invoice_number = "INV-000001"
    @invoice.due_date = 1.day.ago
    @invoice.status = "sent"
    @invoice.save!

    assert @invoice.overdue?
  end

  test "overdue? should return false when due_date is future" do
    @invoice.invoice_number = "INV-000001"
    @invoice.due_date = 1.day.from_now
    @invoice.status = "sent"
    @invoice.save!

    assert_not @invoice.overdue?
  end

  test "overdue? should return false when status is paid" do
    @invoice.invoice_number = "INV-000001"
    @invoice.due_date = 1.day.ago
    @invoice.status = "paid"
    @invoice.save!

    assert_not @invoice.overdue?
  end

  test "mark_as_sent! should update status to sent" do
    @invoice.invoice_number = "INV-000001"
    @invoice.save!

    @invoice.mark_as_sent!
    assert_equal "sent", @invoice.status
  end

  test "mark_as_paid! should update status to paid" do
    @invoice.invoice_number = "INV-000001"
    @invoice.save!

    @invoice.mark_as_paid!
    assert_equal "paid", @invoice.status
  end

  test "mark_as_cancelled! should update status to cancelled" do
    @invoice.invoice_number = "INV-000001"
    @invoice.save!

    @invoice.mark_as_cancelled!
    assert_equal "cancelled", @invoice.status
  end

  # Scopes
  test "draft scope should return draft invoices" do
    @invoice.invoice_number = "INV-000001"
    @invoice.status = "draft"
    @invoice.save!

    assert_includes Invoice.draft, @invoice
  end

  test "sent scope should return sent invoices" do
    @invoice.invoice_number = "INV-000001"
    @invoice.status = "sent"
    @invoice.save!

    assert_includes Invoice.sent, @invoice
  end

  test "paid scope should return paid invoices" do
    @invoice.invoice_number = "INV-000001"
    @invoice.status = "paid"
    @invoice.save!

    assert_includes Invoice.paid, @invoice
  end

  test "cancelled scope should return cancelled invoices" do
    @invoice.invoice_number = "INV-000001"
    @invoice.status = "cancelled"
    @invoice.save!

    assert_includes Invoice.cancelled, @invoice
  end

  test "recent scope should order by invoice_date descending" do
    older = Invoice.create!(
      print_pricing: @print_pricing,
      user: @user,
      invoice_date: 2.days.ago,
      currency: "USD"
    )

    newer = Invoice.create!(
      print_pricing: @print_pricing,
      user: @user,
      invoice_date: 1.day.ago,
      currency: "USD"
    )

    recent = Invoice.recent
    assert_equal newer, recent.first
    assert_equal older, recent.second
  end
end
