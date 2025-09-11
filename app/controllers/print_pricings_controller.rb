class PrintPricingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_print_pricing, only: [:show, :edit, :update, :destroy]

  def index
    @print_pricings = current_user.print_pricings.order(created_at: :desc)
  end

  def show
  end

  def new
    @print_pricing = current_user.print_pricings.build
  end

  def create
    @print_pricing = current_user.print_pricings.build(print_pricing_params)
    
    if @print_pricing.save
      redirect_to @print_pricing, notice: 'Print pricing was successfully created.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @print_pricing.update(print_pricing_params)
      redirect_to @print_pricing, notice: 'Print pricing was successfully updated.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @print_pricing.destroy
    redirect_to print_pricings_url, notice: 'Print pricing was successfully deleted.'
  end

  private

  def set_print_pricing
    @print_pricing = current_user.print_pricings.find(params[:id])
  end

  def print_pricing_params
    params.require(:print_pricing).permit(
      :job_name, :printing_time_hours, :printing_time_minutes,
      :filament_weight, :filament_type, :spool_price, :spool_weight,
      :markup_percentage, :prep_time_minutes, :prep_cost_per_hour, 
      :postprocessing_time_minutes, :postprocessing_cost_per_hour,
      :other_costs, :vat_percentage, :printer_id
    )
  end
end
