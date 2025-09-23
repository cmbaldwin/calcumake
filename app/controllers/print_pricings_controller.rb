class PrintPricingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_print_pricing, only: [ :show, :edit, :update, :destroy, :increment_times_printed, :decrement_times_printed, :invoice ]

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

    if params[:print_pricing][:start_with_one_print] == "1"
      @print_pricing.times_printed = 1
    end

    if @print_pricing.save
      respond_to do |format|
        format.html { redirect_to @print_pricing, notice: "Print pricing was successfully created." }
        format.turbo_stream {
          flash.now[:notice] = "Print pricing was successfully created."
          render "layouts/flash"
        }
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @print_pricing.update(print_pricing_params)
      respond_to do |format|
        format.html { redirect_to @print_pricing, notice: "Print pricing was successfully updated." }
        format.turbo_stream {
          flash.now[:notice] = "Print pricing was successfully updated."
          render "layouts/flash"
        }
      end
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @print_pricing.destroy
    respond_to do |format|
      format.html { redirect_to print_pricings_url, notice: "Print pricing was successfully deleted." }
      format.turbo_stream {
        flash.now[:notice] = "Print pricing was successfully deleted."
        render "layouts/flash"
      }
    end
  end

  def increment_times_printed
    @print_pricing.increment_times_printed!
    @print_pricings = current_user.print_pricings.order(created_at: :desc)
    respond_to do |format|
      format.turbo_stream # Will render increment_times_printed.turbo_stream.erb
      format.html { redirect_to print_pricings_path, notice: t("print_pricing.times_printed_incremented") }
    end
  end

  def decrement_times_printed
    @print_pricing.decrement_times_printed!
    @print_pricings = current_user.print_pricings.order(created_at: :desc)
    respond_to do |format|
      format.turbo_stream # Will render decrement_times_printed.turbo_stream.erb
      format.html { redirect_to print_pricings_path, notice: t("print_pricing.times_printed_decremented") }
    end
  end

  def invoice
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
      :other_costs, :vat_percentage, :printer_id, :times_printed
    )
  end
end
