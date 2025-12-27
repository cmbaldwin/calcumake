# frozen_string_literal: true

class ResinsController < ApplicationController
  include UsageTrackable

  before_action :authenticate_user!
  before_action :set_resin, only: [ :show, :edit, :update, :destroy, :duplicate ]
  before_action :check_resource_limit, only: [ :duplicate ], prepend: true

  def index
    @q = current_user.resins.ransack(params[:q])
    @resins = @q.result.order(:resin_type, :name)
    @resin_types = current_user.resins.distinct.pluck(:resin_type).compact.sort
  end

  def show
  end

  def new
    @resin = current_user.resins.build(needs_wash: true)

    respond_to do |format|
      format.html
      format.turbo_stream { render :modal_form }
    end
  end

  def create
    @resin = current_user.resins.build(resin_params)

    if @resin.save
      respond_to do |format|
        format.html { redirect_to resins_path, notice: t("flash.created", model: t("models.resin")) }
        format.turbo_stream {
          flash.now[:notice] = t("flash.created", model: t("models.resin"))
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
    if @resin.update(resin_params)
      redirect_to @resin, notice: t("flash.updated", model: t("models.resin"))
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @resin.destroy
    redirect_to resins_path, notice: t("flash.deleted", model: t("models.resin"))
  end

  def duplicate
    # Create a duplicate with all attributes except unique identifiers
    @new_resin = @resin.dup

    # Make the name unique by appending "Copy"
    @new_resin.name = "#{@resin.name} (#{t('actions.copy')})"

    if @new_resin.save
      redirect_to edit_resin_path(@new_resin), notice: t("flash.duplicated", model: t("models.resin"))
    else
      redirect_to resins_path, alert: t("flash.duplicate_failed", model: t("models.resin"))
    end
  end

  private

  # Resins use total count, not monthly tracking
  def skip_usage_tracking?
    true
  end

  # Resins use total count, not per-create limits
  def skip_limit_check?
    true
  end

  def set_resin
    @resin = current_user.resins.find(params[:id])
  end

  def resin_params
    params.require(:resin).permit(
      :name, :brand, :resin_type, :bottle_volume_ml, :bottle_price,
      :color, :cure_time_seconds, :layer_height_min, :layer_height_max,
      :exposure_time_seconds, :needs_wash, :notes
    )
  end
end
