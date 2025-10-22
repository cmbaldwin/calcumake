require "test_helper"

class InvoicesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @print_pricing = print_pricings(:one)
    @invoice = invoices(:one)
    sign_in @user
  end

  # Index action
  test "should get index" do
    get print_pricing_invoices_url(@print_pricing)
    assert_response :success
  end

  test "should only show invoices for the specified print_pricing" do
    get print_pricing_invoices_url(@print_pricing)
    assert_response :success
  end

  # Show action
  test "should show invoice" do
    get print_pricing_invoice_url(@print_pricing, @invoice)
    assert_response :success
  end

  # New action
  test "should get new" do
    get new_print_pricing_invoice_url(@print_pricing)
    assert_response :success
  end

  test "should build default line items for new invoice" do
    get new_print_pricing_invoice_url(@print_pricing)
    assert_response :success
  end

  # Create action
  test "should create invoice" do
    assert_difference("Invoice.count") do
      post print_pricing_invoices_url(@print_pricing), params: {
        invoice: {
          company_name: "Test Company",
          company_email: "test@example.com",
          invoice_date: Date.current,
          due_date: Date.current + 30.days,
          payment_details: "Bank transfer",
          notes: "Test notes",
          invoice_line_items_attributes: [
            {
              description: "Test item",
              quantity: 1,
              unit_price: 100,
              line_item_type: "custom",
              order_position: 0
            }
          ]
        }
      }
    end

    assert_redirected_to print_pricing_invoice_url(@print_pricing, Invoice.last)
    assert_equal "Invoice created successfully", flash[:notice]
  end

  test "should not create invoice with invalid data" do
    assert_no_difference("Invoice.count") do
      post print_pricing_invoices_url(@print_pricing), params: {
        invoice: {
          status: "invalid_status",  # Invalid status will fail validation
          invoice_line_items_attributes: []
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # Edit action
  test "should get edit" do
    get edit_print_pricing_invoice_url(@print_pricing, @invoice)
    assert_response :success
  end

  # Update action
  test "should update invoice" do
    patch print_pricing_invoice_url(@print_pricing, @invoice), params: {
      invoice: {
        notes: "Updated notes",
        payment_details: "Updated payment info"
      }
    }

    assert_redirected_to print_pricing_invoice_url(@print_pricing, @invoice)
    assert_equal "Invoice updated successfully", flash[:notice]

    @invoice.reload
    assert_equal "Updated notes", @invoice.notes
    assert_equal "Updated payment info", @invoice.payment_details
    assert_equal "Updated notes", @invoice.notes
  end

  test "should not update invoice with invalid data" do
    original_name = @invoice.company_name

    patch print_pricing_invoice_url(@print_pricing, @invoice), params: {
      invoice: {
        status: "invalid_status"
      }
    }

    assert_response :unprocessable_entity
    @invoice.reload
    assert_equal original_name, @invoice.company_name
  end

  # Destroy action
  test "should destroy invoice" do
    assert_difference("Invoice.count", -1) do
      delete print_pricing_invoice_url(@print_pricing, @invoice)
    end

    assert_redirected_to print_pricing_path(@print_pricing)
    assert_equal "Invoice deleted successfully", flash[:notice]
  end

  # Status update actions
  test "should mark invoice as sent" do
    assert_equal "draft", @invoice.status

    patch mark_as_sent_print_pricing_invoice_url(@print_pricing, @invoice)

    @invoice.reload
    assert_equal "sent", @invoice.status
    assert_redirected_to print_pricing_invoice_url(@print_pricing, @invoice)
  end

  test "should mark invoice as paid" do
    @invoice.update(status: "sent")

    patch mark_as_paid_print_pricing_invoice_url(@print_pricing, @invoice)

    @invoice.reload
    assert_equal "paid", @invoice.status
    assert_redirected_to print_pricing_invoice_url(@print_pricing, @invoice)
  end

  test "should mark invoice as cancelled" do
    patch mark_as_cancelled_print_pricing_invoice_url(@print_pricing, @invoice)

    @invoice.reload
    assert_equal "cancelled", @invoice.status
    assert_redirected_to print_pricing_invoice_url(@print_pricing, @invoice)
  end

  # Authorization tests
  test "should require authentication for all actions" do
    sign_out @user

    get print_pricing_invoices_url(@print_pricing)
    assert_redirected_to new_user_session_url

    get print_pricing_invoice_url(@print_pricing, @invoice)
    assert_redirected_to new_user_session_url

    get new_print_pricing_invoice_url(@print_pricing)
    assert_redirected_to new_user_session_url
  end

  test "should show next invoice number preview on new invoice form" do
    sign_in @user

    get new_print_pricing_invoice_url(@print_pricing)
    assert_response :success

    # Check that the form shows the next invoice number preview
    next_number = @user.next_invoice_number
    expected_preview = "INV-#{next_number.to_s.rjust(6, '0')}"
    assert_select "input[value='#{expected_preview}'][readonly]"
  end

  test "should not allow deletion of non-draft invoices" do
    sign_in @user
    @invoice.update!(status: "sent")

    delete print_pricing_invoice_url(@print_pricing, @invoice)
    assert_redirected_to print_pricing_invoice_path(@print_pricing, @invoice)

    follow_redirect!
    assert_match "Only draft invoices can be deleted", response.body
    assert Invoice.exists?(@invoice.id), "Invoice should not have been deleted"
  end

  test "should allow deletion of draft invoices" do
    sign_in @user
    @invoice.update!(status: "draft")

    assert_difference("Invoice.count", -1) do
      delete print_pricing_invoice_url(@print_pricing, @invoice)
    end

    assert_redirected_to print_pricing_path(@print_pricing)
  end
end
