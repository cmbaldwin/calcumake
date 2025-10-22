class InvoicesController < ApplicationController
  include ApplicationHelper

  before_action :authenticate_user!
  before_action :set_print_pricing
  before_action :set_invoice, only: [ :show, :edit, :update, :destroy, :mark_as_sent, :mark_as_paid, :mark_as_cancelled ]
  before_action :authorize_invoice, only: [ :show, :edit, :update, :destroy, :mark_as_sent, :mark_as_paid, :mark_as_cancelled ]

  def index
    @invoices = @print_pricing.invoices.recent
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

    # Build default line items from print pricing
    build_default_line_items
  end

  def create
    @invoice = @print_pricing.invoices.build(invoice_params)
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

  def set_invoice
    @invoice = @print_pricing.invoices.find(params[:id])
  end

  def authorize_invoice
    unless @invoice.user == current_user
      redirect_to root_path, alert: t("errors.unauthorized")
    end
  end

  def invoice_params
    params.require(:invoice).permit(
      :payment_details, :notes, :invoice_number, :invoice_date, :due_date,
      :status, :currency,
      invoice_line_items_attributes: [
        :id, :description, :quantity, :unit_price, :line_item_type, :order_position, :_destroy
      ]
    )
  end

  def build_default_line_items
    position = 0

    # Filament cost line items (one per plate)
    @print_pricing.plates.each_with_index do |plate, index|
      @invoice.invoice_line_items.build(
        description: "#{t('print_pricing.sections.plate')} #{index + 1}: #{plate.filament_weight}g #{translate_filament_type(plate.filament_type)}",
        quantity: 1,
        unit_price: plate.total_filament_cost,
        line_item_type: "filament",
        order_position: position
      )
      position += 1
    end

    # Electricity cost
    if @print_pricing.total_electricity_cost > 0
      @invoice.invoice_line_items.build(
        description: t("print_pricing.electricity_cost"),
        quantity: 1,
        unit_price: @print_pricing.total_electricity_cost,
        line_item_type: "electricity",
        order_position: position
      )
      position += 1
    end

    # Labor costs
    if @print_pricing.total_labor_cost > 0
      @invoice.invoice_line_items.build(
        description: t("print_pricing.labor_cost"),
        quantity: 1,
        unit_price: @print_pricing.total_labor_cost,
        line_item_type: "labor",
        order_position: position
      )
      position += 1
    end

    # Machine upkeep
    if @print_pricing.total_machine_upkeep_cost > 0
      @invoice.invoice_line_items.build(
        description: t("print_pricing.machine_upkeep"),
        quantity: 1,
        unit_price: @print_pricing.total_machine_upkeep_cost,
        line_item_type: "machine",
        order_position: position
      )
      position += 1
    end

    # Other costs
    if @print_pricing.other_costs && @print_pricing.other_costs > 0
      @invoice.invoice_line_items.build(
        description: t("print_pricing.other_costs"),
        quantity: 1,
        unit_price: @print_pricing.other_costs,
        line_item_type: "other",
        order_position: position
      )
    end
  end
end
