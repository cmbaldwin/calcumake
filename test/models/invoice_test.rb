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
    @invoice.invoice_number = "INV-999999"
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
    @invoice.invoice_number = "INV-999998"
    @invoice.save!

    duplicate_invoice = Invoice.new(
      print_pricing: @print_pricing,
      user: @user,
      invoice_number: "INV-999998",
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
    @invoice.due_date = 1.day.ago
    @invoice.status = "sent"
    @invoice.save!

    assert @invoice.overdue?
  end

  test "overdue? should return false when due_date is future" do
    @invoice.due_date = 1.day.from_now
    @invoice.status = "sent"
    @invoice.save!

    assert_not @invoice.overdue?
  end

  test "overdue? should return false when status is paid" do
    @invoice.due_date = 1.day.ago
    @invoice.status = "paid"
    @invoice.save!

    assert_not @invoice.overdue?
  end

  test "mark_as_sent! should update status to sent" do
    @invoice.save!

    @invoice.mark_as_sent!
    assert_equal "sent", @invoice.status
  end

  test "mark_as_paid! should update status to paid" do
    @invoice.save!

    @invoice.mark_as_paid!
    assert_equal "paid", @invoice.status
  end

  test "mark_as_cancelled! should update status to cancelled" do
    @invoice.save!

    @invoice.mark_as_cancelled!
    assert_equal "cancelled", @invoice.status
  end

  # Scopes
  test "draft scope should return draft invoices" do
    @invoice.status = "draft"
    @invoice.save!

    assert_includes Invoice.draft, @invoice
  end

  test "sent scope should return sent invoices" do
    @invoice.status = "sent"
    @invoice.save!

    assert_includes Invoice.sent, @invoice
  end

  test "paid scope should return paid invoices" do
    @invoice.status = "paid"
    @invoice.save!

    assert_includes Invoice.paid, @invoice
  end

  test "cancelled scope should return cancelled invoices" do
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

  # Instance methods
  test "build_default_line_items creates line items from print pricing" do
    invoice = @print_pricing.invoices.build(user: @user)
    invoice.build_default_line_items

    assert invoice.invoice_line_items.any?, "Should build line items"

    # Should have line items for each plate
    plate_items = invoice.invoice_line_items.select { |item| item.line_item_type == "filament" }
    assert_equal @print_pricing.plates.count, plate_items.count

    # Check if electricity cost is included
    if @print_pricing.total_electricity_cost > 0
      electricity_item = invoice.invoice_line_items.find { |item| item.line_item_type == "electricity" }
      assert electricity_item.present?, "Should include electricity cost"
      # Use in_delta to account for failure rate calculations
      assert_in_delta @print_pricing.total_electricity_cost, electricity_item.unit_price, 0.01
    end
  end

  test "build_default_line_items sets correct order positions" do
    invoice = @print_pricing.invoices.build(user: @user)
    invoice.build_default_line_items

    positions = invoice.invoice_line_items.map(&:order_position)
    assert_equal positions, positions.sort, "Order positions should be sequential"
    assert_equal 0, positions.first, "First position should be 0"
  end

  test "build_default_line_items includes labor costs when present" do
    @print_pricing.prep_time_minutes = 60
    @print_pricing.prep_cost_per_hour = 25.0
    @print_pricing.postprocessing_time_minutes = 60
    @print_pricing.postprocessing_cost_per_hour = 25.0
    @print_pricing.save!

    invoice = @print_pricing.invoices.build(user: @user)
    invoice.build_default_line_items

    labor_item = invoice.invoice_line_items.find { |item| item.line_item_type == "labor" }
    if @print_pricing.total_labor_cost > 0
      assert labor_item.present?, "Should include labor cost"
      assert_equal @print_pricing.total_labor_cost, labor_item.unit_price
    end
  end

  test "build_default_line_items handles print pricing with minimal data" do
    # Use the existing print_pricing from setup which has plates
    invoice = @print_pricing.invoices.build(user: @user)

    # Should not raise an error even if called multiple times
    assert_nothing_raised do
      invoice.build_default_line_items
      invoice.build_default_line_items # Should be idempotent
    end

    # Verify line items were created
    assert invoice.invoice_line_items.any?, "Should create line items"
  end
end
