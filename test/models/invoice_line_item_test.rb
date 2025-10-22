require "test_helper"

class InvoiceLineItemTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @print_pricing = print_pricings(:one)
    @invoice = Invoice.create!(
      print_pricing: @print_pricing,
      user: @user,
      invoice_date: Date.current,
      currency: "USD"
    )
    @line_item = InvoiceLineItem.new(
      invoice: @invoice,
      description: "Test Item",
      quantity: 2,
      unit_price: 10.00,
      line_item_type: "custom",
      order_position: 0
    )
  end

  # Associations
  test "belongs to invoice" do
    assert_respond_to @line_item, :invoice
  end

  # Validations
  test "should be valid with valid attributes" do
    assert @line_item.valid?
  end

  test "should require invoice" do
    @line_item.invoice = nil
    assert_not @line_item.valid?
    assert_includes @line_item.errors[:invoice], "must exist"
  end

  test "should require description" do
    @line_item.description = nil
    assert_not @line_item.valid?
    assert_includes @line_item.errors[:description], "can't be blank"
  end

  test "should require quantity" do
    @line_item.quantity = nil
    assert_not @line_item.valid?
    assert_includes @line_item.errors[:quantity], "can't be blank"
  end

  test "should require quantity greater than zero" do
    @line_item.quantity = 0
    assert_not @line_item.valid?
    assert_includes @line_item.errors[:quantity], "must be greater than 0"
  end

  test "should require unit_price" do
    @line_item.unit_price = nil
    assert_not @line_item.valid?
    assert_includes @line_item.errors[:unit_price], "can't be blank"
  end

  test "should allow unit_price of zero" do
    @line_item.unit_price = 0
    assert @line_item.valid?
  end

  test "should auto-calculate total_price" do
    @line_item.quantity = 5
    @line_item.unit_price = 20
    @line_item.total_price = nil
    @line_item.save!
    assert_equal 100.0, @line_item.total_price
  end

  test "should require line_item_type" do
    @line_item.line_item_type = nil
    assert_not @line_item.valid?
    assert_includes @line_item.errors[:line_item_type], "can't be blank"
  end

  test "should validate line_item_type inclusion" do
    @line_item.line_item_type = "invalid_type"
    assert_not @line_item.valid?
    assert_includes @line_item.errors[:line_item_type], "is not included in the list"
  end

  test "should require order_position" do
    @line_item.order_position = nil
    assert_not @line_item.valid?
    assert_includes @line_item.errors[:order_position], "can't be blank"
  end

  test "should allow order_position of zero" do
    @line_item.order_position = 0
    assert @line_item.valid?
  end

  # Callbacks
  test "should auto-calculate total_price before validation" do
    @line_item.quantity = 3
    @line_item.unit_price = 15.50
    @line_item.total_price = nil
    @line_item.valid?

    assert_equal 46.50, @line_item.total_price
  end

  test "should recalculate total_price when quantity changes" do
    @line_item.save!
    @line_item.quantity = 5
    @line_item.valid?

    assert_equal 50.00, @line_item.total_price
  end

  test "should recalculate total_price when unit_price changes" do
    @line_item.save!
    @line_item.unit_price = 25.00
    @line_item.valid?

    assert_equal 50.00, @line_item.total_price
  end

  # Scopes
  test "ordered scope should order by order_position" do
    item1 = @invoice.invoice_line_items.create!(
      description: "Item 1",
      quantity: 1,
      unit_price: 10,
      line_item_type: "custom",
      order_position: 2
    )

    item2 = @invoice.invoice_line_items.create!(
      description: "Item 2",
      quantity: 1,
      unit_price: 10,
      line_item_type: "custom",
      order_position: 0
    )

    item3 = @invoice.invoice_line_items.create!(
      description: "Item 3",
      quantity: 1,
      unit_price: 10,
      line_item_type: "custom",
      order_position: 1
    )

    ordered = @invoice.invoice_line_items.ordered
    assert_equal item2, ordered.first
    assert_equal item3, ordered.second
    assert_equal item1, ordered.third
  end
end
