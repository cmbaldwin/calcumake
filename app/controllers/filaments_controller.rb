# frozen_string_literal: true

class FilamentsController < ApplicationController
  include UsageTrackable

  before_action :authenticate_user!
  before_action :set_filament, only: [ :show, :edit, :update, :destroy, :duplicate ]
  before_action :check_resource_limit, only: [ :duplicate ], prepend: true

  def index
    @q = current_user.filaments.ransack(params[:q])
    @filaments = @q.result.order(:material_type, :name)
    @material_types = current_user.filaments.distinct.pluck(:material_type).compact.sort
  end

  def show
  end

  def new
    @filament = current_user.filaments.build(diameter: 1.75)

    respond_to do |format|
      format.html
      format.turbo_stream { render :modal_form }
    end
  end

  def create
    @filament = current_user.filaments.build(filament_params)

    if @filament.save
      respond_to do |format|
        format.html { redirect_to @filament, notice: t("flash.created", model: t("models.filament")) }
        format.turbo_stream {
          flash.now[:notice] = t("flash.created", model: t("models.filament"))
          # Renders create.turbo_stream.erb
        }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :modal_form, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    if @filament.update(filament_params)
      redirect_to @filament, notice: t("flash.updated", model: t("models.filament"))
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @filament.destroy
    redirect_to filaments_path, notice: t("flash.deleted", model: t("models.filament"))
  end

  def duplicate
    # Create a duplicate with all attributes except unique identifiers
    @new_filament = @filament.dup

    # Make the name unique by appending "Copy"
    @new_filament.name = "#{@filament.name} (#{t('actions.copy')})"

    if @new_filament.save
      redirect_to edit_filament_path(@new_filament), notice: t("flash.duplicated", model: t("models.filament"))
    else
      redirect_to filaments_path, alert: t("flash.duplicate_failed", model: t("models.filament"))
    end
  end

  def import_form
    # Show the import form
  end

  def import
    source_type = params[:source_type] # "url" or "text"
    source_content = params[:source_content]

    importer = FilamentImporter.new(current_user, source_type: source_type, source_content: source_content)
    filaments = importer.import

    if filaments.present?
      flash[:notice] = t("filaments.import.success", count: filaments.count)
      redirect_to filaments_path
    else
      flash.now[:alert] = t("filaments.import.failure", errors: importer.errors.join(", "))
      render :import_form, status: :unprocessable_entity
    end
  end

  private

  # Filaments use total count, not monthly tracking
  def skip_usage_tracking?
    true
  end

  # Filaments use total count, not per-create limits
  def skip_limit_check?
    true
  end

  def set_filament
    @filament = current_user.filaments.find(params[:id])
  end

  def filament_params
    params.require(:filament).permit(
      :name, :brand, :material_type, :diameter, :density,
      :print_temperature_min, :print_temperature_max, :heated_bed_temperature,
      :print_speed_max, :color, :finish, :spool_weight, :spool_price,
      :storage_temperature_max, :moisture_sensitive, :notes
    )
  end
end
