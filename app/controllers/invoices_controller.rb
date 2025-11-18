class InvoicesController < ApplicationController
  include ApplicationHelper
  include ResourceAuthorization
  include UsageTrackable

  before_action :authenticate_user!
  before_action :set_print_pricing, except: [ :index ]
  before_action :set_print_pricing_for_nested_index, only: [ :index ]
  before_action :set_invoice, only: [ :show, :edit, :update, :destroy, :mark_as_sent, :mark_as_paid, :mark_as_cancelled ]
  before_action :authorize_invoice, only: [ :show, :edit, :update, :destroy, :mark_as_sent, :mark_as_paid, :mark_as_cancelled ]

  def index
    if params[:print_pricing_id].present?
      # Nested route: show invoices for specific print pricing
      @invoices = @print_pricing.invoices.recent
      @nested_view = true
    else
      # Standalone route: show all user's invoices with search
      @q = current_user.invoices.ransack(params[:q])
      @invoices = @q.result.includes(:print_pricing).recent
      @nested_view = false
    end
  end

  def show
  end

  def new
    @invoice = @print_pricing.invoices.build
    @invoice.user = current_user

    # Populate company info from user defaults
    @invoice.company_name = current_user.default_company_name
    @invoice.company_address = current_user.default_company_address
    @invoice.company_email = current_user.default_company_email
    @invoice.company_phone = current_user.default_company_phone
    @invoice.payment_details = current_user.default_payment_details
    @invoice.notes = current_user.default_invoice_notes
    @invoice.currency = current_user.default_currency

    # Build default line items from print pricing
    @invoice.build_default_line_items
  end

  def create
    @invoice = @print_pricing.invoices.build(invoice_params_for_create)
    @invoice.user = current_user

    if @invoice.save
      redirect_to print_pricing_invoice_path(@print_pricing, @invoice),
                  notice: t("invoices.created_successfully")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Ensure we have at least one line item for the form
    @invoice.invoice_line_items.build if @invoice.invoice_line_items.empty?
  end

  def update
    if @invoice.update(invoice_params)
      redirect_to print_pricing_invoice_path(@print_pricing, @invoice),
                  notice: t("invoices.updated_successfully")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @invoice.status == "draft"
      redirect_to print_pricing_invoice_path(@print_pricing, @invoice),
                  alert: t("invoices.cannot_delete_non_draft")
      return
    end

    @invoice.destroy
    redirect_to print_pricing_path(@print_pricing),
                notice: t("invoices.deleted_successfully")
  end

  def mark_as_sent
    if @invoice.mark_as_sent!
      redirect_to print_pricing_invoice_path(@print_pricing, @invoice),
                  notice: t("invoices.marked_as_sent")
    else
      redirect_to print_pricing_invoice_path(@print_pricing, @invoice),
                  alert: t("invoices.failed_to_update")
    end
  end

  def mark_as_paid
    if @invoice.mark_as_paid!
      redirect_to print_pricing_invoice_path(@print_pricing, @invoice),
                  notice: t("invoices.marked_as_paid")
    else
      redirect_to print_pricing_invoice_path(@print_pricing, @invoice),
                  alert: t("invoices.failed_to_update")
    end
  end

  def mark_as_cancelled
    if @invoice.mark_as_cancelled!
      redirect_to print_pricing_invoice_path(@print_pricing, @invoice),
                  notice: t("invoices.marked_as_cancelled")
    else
      redirect_to print_pricing_invoice_path(@print_pricing, @invoice),
                  alert: t("invoices.failed_to_update")
    end
  end

  private

  def set_print_pricing
    @print_pricing = current_user.print_pricings.find(params[:print_pricing_id])
  end

  def set_print_pricing_for_nested_index
    @print_pricing = current_user.print_pricings.find(params[:print_pricing_id]) if params[:print_pricing_id].present?
  end

  def set_invoice
    @invoice = @print_pricing.invoices.find(params[:id])
  end

  def authorize_invoice
    authorize_resource_ownership!(@invoice, redirect_path: root_path)
  end

  def invoice_params
    params.require(:invoice).permit(
      :client_id, :payment_details, :notes, :invoice_number, :invoice_date, :due_date,
      :status, :currency,
      invoice_line_items_attributes: [
        :id, :description, :quantity, :unit_price, :line_item_type, :order_position, :_destroy
      ]
    )
  end

  def invoice_params_for_create
    permitted_params = invoice_params
    # Convert empty invoice_number to nil so auto-generation triggers on create
    permitted_params[:invoice_number] = nil if permitted_params[:invoice_number].blank?
    permitted_params
  end
end
