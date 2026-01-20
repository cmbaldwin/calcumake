class PrintPricingsController < ApplicationController
  include UsageTrackable

  before_action :authenticate_user!
  before_action :set_print_pricing, only: [ :show, :edit, :update, :destroy, :increment_times_printed, :decrement_times_printed, :duplicate ]
  before_action :check_resource_limit, only: [ :duplicate ], prepend: true

  def index
    @q = current_user.print_pricings.ransack(params[:q])
    @print_pricings = @q.result
                        .includes(:plates, :printer, :client)
                        .order(created_at: :desc)

    # Calculate analytics with trends if date range is provided
    if params.dig(:q, :created_at_gteq).present? || params.dig(:q, :created_at_lteq).present?
      start_date = params.dig(:q, :created_at_gteq)&.to_date
      end_date = params.dig(:q, :created_at_lteq)&.to_date || Date.current

      @analytics = Analytics::OverviewStats.new(current_user, start_date: start_date, end_date: end_date)
    end
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

    # Build one plate by default with quick calculator pre-filled values
    plate = @print_pricing.plates.build

    # Pre-fill from quick calculator if parameters are present
    if params[:print_time_hours].present?
      hours = params[:print_time_hours].to_f
      plate.printing_time_hours = hours.to_i
      plate.printing_time_minutes = ((hours % 1) * 60).round
    end

    # Build one filament by default with pre-filled weight
    filament = plate.plate_filaments.build
    if params[:filament_weight].present?
      filament.filament_weight = params[:filament_weight].to_f
    end
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
      format.html { redirect_to print_pricings_url, notice: "Print pricing was successfully deleted.", status: :see_other }
      format.turbo_stream {
        redirect_to print_pricings_url, notice: "Print pricing was successfully deleted.", status: :see_other
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

    # Duplicate all plates and their filaments/resins
    @print_pricing.plates.each do |plate|
      new_plate = @new_print_pricing.plates.build(plate.attributes.except("id", "print_pricing_id", "created_at", "updated_at"))

      # Duplicate plate filaments
      plate.plate_filaments.each do |plate_filament|
        new_plate.plate_filaments.build(plate_filament.attributes.except("id", "plate_id", "created_at", "updated_at"))
      end

      # Duplicate plate resins
      plate.plate_resins.each do |plate_resin|
        new_plate.plate_resins.build(plate_resin.attributes.except("id", "plate_id", "created_at", "updated_at"))
      end
    end

    if @new_print_pricing.save
      # Track the duplicated resource
      UsageTracking.track!(current_user, "print_pricing")

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
    permitted = params.require(:print_pricing).permit(
      :job_name, :prep_time_minutes, :prep_cost_per_hour,
      :postprocessing_time_minutes, :postprocessing_cost_per_hour,
      :other_costs, :vat_percentage, :printer_id, :times_printed,
      :units, :failure_rate_percentage,
      plates_attributes: [
        :id, :printing_time_hours, :printing_time_minutes, :material_technology, :_destroy,
        plate_filaments_attributes: [
          :id, :filament_id, :filament_weight, :markup_percentage, :_destroy
        ],
        plate_resins_attributes: [
          :id, :resin_id, :resin_volume_ml, :markup_percentage, :_destroy
        ]
      ]
    )

    # Filter out mismatched nested attributes based on material_technology
    filter_plate_material_attributes!(permitted)
    permitted
  end

  # Remove plate_filaments for resin plates and plate_resins for FDM plates
  # This handles the case where hidden form fields still submit empty values
  def filter_plate_material_attributes!(permitted_params)
    return unless permitted_params[:plates_attributes]

    permitted_params[:plates_attributes].each do |_key, plate_attrs|
      next unless plate_attrs.is_a?(ActionController::Parameters) || plate_attrs.is_a?(Hash)

      technology = plate_attrs[:material_technology]

      if technology == "resin"
        # For resin plates, remove all plate_filaments
        plate_attrs.delete(:plate_filaments_attributes)
      elsif technology == "fdm" || technology.blank?
        # For FDM plates (or default), remove all plate_resins
        plate_attrs.delete(:plate_resins_attributes)
      end
    end
  end
end
