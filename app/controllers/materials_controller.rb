# frozen_string_literal: true

class MaterialsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Combined search across both filaments and resins
    search_term = params.dig(:q, :name_or_brand_or_color_cont)
    material_type_filter = params.dig(:q, :material_type_eq)

    # Build Ransack queries
    @filament_q = current_user.filaments.ransack(params[:q])
    @resin_q = current_user.resins.ransack(params[:q])

    # Get filtered results
    @filaments = @filament_q.result.order(:material_type, :name)
    @resins = @resin_q.result.order(:resin_type, :name)

    # Get unique material types for filter dropdown
    @filament_types = current_user.filaments.distinct.pluck(:material_type).compact.sort
    @resin_types = current_user.resins.distinct.pluck(:resin_type).compact.sort
  end
end
