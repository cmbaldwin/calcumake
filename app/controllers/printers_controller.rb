class PrintersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_printer, only: [:show, :edit, :update, :destroy]

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
      redirect_to @printer, notice: 'Printer was successfully created.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @printer.update(printer_params)
      redirect_to @printer, notice: 'Printer was successfully updated.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @printer.destroy
    redirect_to printers_url, notice: 'Printer was successfully deleted.'
  end

  private

  def set_printer
    @printer = current_user.printers.find(params[:id])
  end

  def printer_params
    params.require(:printer).permit(
      :name, :manufacturer, :power_consumption, :cost, :payoff_goal_years,
      :daily_usage_hours, :investment_return_years, :repair_cost_percentage
    )
  end
end
