# frozen_string_literal: true

module Api
  module V1
    class PlatesController < BaseController
      before_action :set_print_pricing
      before_action :set_plate, only: [ :show ]

      def index
        @plates = @print_pricing.plates
          .includes(:plate_filaments, :filaments, :plate_resins, :resins)

        render json: {
          data: @plates.map { |plate| serialize_plate(plate) }
        }
      end

      def show
        render json: {
          data: serialize_plate(@plate)
        }
      end

      private

      def set_print_pricing
        @print_pricing = current_user.print_pricings.find(params[:print_pricing_id])
      end

      def set_plate
        @plate = @print_pricing.plates
          .includes(:plate_filaments, :filaments, :plate_resins, :resins)
          .find(params[:id])
      end

      def serialize_plate(plate)
        {
          id: plate.id.to_s,
          type: "plate",
          attributes: {
            material_technology: plate.material_technology,
            printing_time_hours: plate.printing_time_hours,
            printing_time_minutes: plate.printing_time_minutes,
            total_printing_time_minutes: plate.total_printing_time_minutes,
            total_material_cost: plate.total_material_cost&.to_f,
            total_filament_weight: plate.fdm? ? plate.total_filament_weight&.to_f : nil,
            total_resin_volume: plate.resin? ? plate.total_resin_volume&.to_f : nil,
            material_types: plate.material_types,
            created_at: plate.created_at&.iso8601,
            updated_at: plate.updated_at&.iso8601
          },
          relationships: {
            print_pricing: {
              data: { id: plate.print_pricing_id.to_s, type: "print_pricing" }
            },
            filaments: plate.fdm? ? {
              data: plate.plate_filaments.map { |pf| serialize_plate_filament(pf) }
            } : nil,
            resins: plate.resin? ? {
              data: plate.plate_resins.map { |pr| serialize_plate_resin(pr) }
            } : nil
          }
        }
      end

      def serialize_plate_filament(plate_filament)
        {
          id: plate_filament.id.to_s,
          type: "plate_filament",
          filament_id: plate_filament.filament_id.to_s,
          attributes: {
            filament_name: plate_filament.filament&.name,
            filament_brand: plate_filament.filament&.brand,
            material_type: plate_filament.filament&.material_type,
            filament_weight: plate_filament.filament_weight&.to_f,
            markup_percentage: plate_filament.markup_percentage&.to_f,
            total_cost: plate_filament.total_cost&.to_f
          }
        }
      end

      def serialize_plate_resin(plate_resin)
        {
          id: plate_resin.id.to_s,
          type: "plate_resin",
          resin_id: plate_resin.resin_id.to_s,
          attributes: {
            resin_name: plate_resin.resin&.name,
            resin_brand: plate_resin.resin&.brand,
            resin_type: plate_resin.resin&.resin_type,
            resin_volume_ml: plate_resin.resin_volume_ml&.to_f,
            markup_percentage: plate_resin.markup_percentage&.to_f,
            total_cost: plate_resin.total_cost&.to_f
          }
        }
      end
    end
  end
end
