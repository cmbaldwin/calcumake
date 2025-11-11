class PrintersController < ApplicationController
  include UsageTrackable

  before_action :authenticate_user!
  before_action :set_printer, only: [ :show, :edit, :update, :destroy ]

  private

  # Printers use total count, not monthly tracking
  def skip_usage_tracking?
    true
  end

  public

  def index
    @printers = current_user.printers.order(:name)
  end

  def show
  end

  def new
    @printer = current_user.printers.build
  end

  def create
    @printer = current_user.printers.build(printer_params)

    if @printer.save
      respond_to do |format|
        format.html { redirect_to @printer, notice: "Printer was successfully created." }
        format.turbo_stream {
          flash.now[:notice] = "Printer was successfully created."
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
    if @printer.update(printer_params)
      respond_to do |format|
        format.html { redirect_to @printer, notice: "Printer was successfully updated." }
        format.turbo_stream {
          flash.now[:notice] = "Printer was successfully updated."
          render "layouts/flash"
        }
      end
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @printer.destroy
    respond_to do |format|
      format.html { redirect_to printers_url, notice: "Printer was successfully deleted." }
      format.turbo_stream {
        flash.now[:notice] = "Printer was successfully deleted."
        render "layouts/flash"
      }
    end
  end

  private

  def set_printer
    @printer = current_user.printers.includes(:print_pricings).find(params[:id])
  end

  def printer_params
    params.require(:printer).permit(
      :name, :manufacturer, :power_consumption, :cost, :payoff_goal_years,
      :daily_usage_hours, :investment_return_years, :repair_cost_percentage
    )
  end
end
