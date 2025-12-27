# frozen_string_literal: true

module Api
  module V1
    class MaterialsController < BaseController
      def index
        filaments = current_user.filaments.order(:material_type, :name)
        resins = current_user.resins.order(:resin_type, :name)

        # Apply search filter
        if params[:q].present?
          filaments = filaments.search(params[:q])
          resins = resins.search(params[:q])
        end

        # Apply technology filter
        case params[:technology]
        when "fdm"
          resins = resins.none
        when "resin"
          filaments = filaments.none
        end

        render json: {
          data: {
            filaments: filaments.map { |f| serialize_filament(f) },
            resins: resins.map { |r| serialize_resin(r) }
          },
          meta: {
            filaments_count: filaments.count,
            resins_count: resins.count,
            total_count: filaments.count + resins.count,
            filament_types: current_user.filaments.distinct.pluck(:material_type).compact.sort,
            resin_types: current_user.resins.distinct.pluck(:resin_type).compact.sort
          }
        }
      end

      private

      def serialize_filament(filament)
        {
          id: filament.id.to_s,
          type: "filament",
          technology: "fdm",
          attributes: {
            name: filament.name,
            brand: filament.brand,
            material_type: filament.material_type,
            color: filament.color,
            diameter: filament.diameter&.to_f,
            spool_weight: filament.spool_weight&.to_f,
            spool_price: filament.spool_price&.to_f,
            cost_per_gram: filament.cost_per_gram&.to_f,
            notes: filament.notes,
            created_at: filament.created_at.iso8601,
            updated_at: filament.updated_at.iso8601
          }
        }
      end

      def serialize_resin(resin)
        {
          id: resin.id.to_s,
          type: "resin",
          technology: "resin",
          attributes: {
            name: resin.name,
            brand: resin.brand,
            resin_type: resin.resin_type,
            color: resin.color,
            bottle_volume_ml: resin.bottle_volume_ml&.to_f,
            bottle_price: resin.bottle_price&.to_f,
            cost_per_ml: resin.cost_per_ml&.to_f,
            needs_wash: resin.needs_wash,
            notes: resin.notes,
            created_at: resin.created_at.iso8601,
            updated_at: resin.updated_at.iso8601
          }
        }
      end
    end
  end
end
