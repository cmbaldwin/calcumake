class PrintPricingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_print_pricing, only: [ :show, :edit, :update, :destroy, :increment_times_printed, :decrement_times_printed, :duplicate ]

  def index
    @print_pricings = current_user.print_pricings.search(params[:query]).order(created_at: :desc)
  end

  def show
  end

  def new
    @print_pricing = current_user.print_pricings.build(
      prep_time_minutes: current_user.default_prep_time_minutes,
      prep_cost_per_hour: current_user.default_prep_cost_per_hour,
      postprocessing_time_minutes: current_user.default_postprocessing_time_minutes,
      postprocessing_cost_per_hour: current_user.default_postprocessing_cost_per_hour,
      other_costs: current_user.default_other_costs,
      vat_percentage: current_user.default_vat_percentage
    )
    plate = @print_pricing.plates.build # Build one plate by default
    plate.plate_filaments.build # Build one filament by default
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
          redirect_to @print_pricing, notice: "Print pricing was successfully created."
        }
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    # Ensure at least one plate exists for editing
    if @print_pricing.plates.empty?
      plate = @print_pricing.plates.build
      plate.plate_filaments.build
    else
      # Ensure each existing plate has at least one filament for editing
      @print_pricing.plates.each do |plate|
        plate.plate_filaments.build if plate.plate_filaments.empty?
      end
    end
  end

  def update
    if @print_pricing.update(print_pricing_params)
      respond_to do |format|
        format.html { redirect_to @print_pricing, notice: "Print pricing was successfully updated." }
        format.turbo_stream {
          redirect_to @print_pricing, notice: "Print pricing was successfully updated."
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

  def duplicate
    # Duplicate the print pricing with all its plates
    @new_print_pricing = @print_pricing.dup
    @new_print_pricing.job_name = "#{@print_pricing.job_name} (Copy)"
    @new_print_pricing.times_printed = 0

    # Duplicate all plates and their filaments
    @print_pricing.plates.each do |plate|
      new_plate = @new_print_pricing.plates.build(plate.attributes.except("id", "print_pricing_id", "created_at", "updated_at"))

      # Duplicate plate filaments
      plate.plate_filaments.each do |plate_filament|
        new_plate.plate_filaments.build(plate_filament.attributes.except("id", "plate_id", "created_at", "updated_at"))
      end
    end

    if @new_print_pricing.save
      respond_to do |format|
        format.html { redirect_to @new_print_pricing, notice: t("print_pricing.duplicated_successfully") }
        format.turbo_stream {
          redirect_to @new_print_pricing, notice: t("print_pricing.duplicated_successfully")
        }
      end
    else
      respond_to do |format|
        format.html { redirect_to @print_pricing, alert: t("print_pricing.duplicate_failed") }
        format.turbo_stream {
          flash.now[:alert] = t("print_pricing.duplicate_failed")
          render "layouts/flash"
        }
      end
    end
  end

  private

  def set_print_pricing
    @print_pricing = current_user.print_pricings.find(params[:id])
  end

  def print_pricing_params
    params.require(:print_pricing).permit(
      :job_name, :prep_time_minutes, :prep_cost_per_hour,
      :postprocessing_time_minutes, :postprocessing_cost_per_hour,
      :other_costs, :vat_percentage, :printer_id, :times_printed,
      plates_attributes: [
        :id, :printing_time_hours, :printing_time_minutes, :_destroy,
        plate_filaments_attributes: [
          :id, :filament_id, :filament_weight, :_destroy
        ]
      ]
    )
  end
end
