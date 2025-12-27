# frozen_string_literal: true

module Api
  module V1
    class FilamentsController < BaseController
      before_action :set_filament, only: %i[show update destroy duplicate]

      def index
        @filaments = current_user.filaments.order(:material_type, :name)

        # Apply search filter
        @filaments = @filaments.search(params[:q]) if params[:q].present?

        # Apply type filter
        @filaments = @filaments.by_material_type(params[:material_type]) if params[:material_type].present?

        render json: {
          data: @filaments.map { |filament| serialize_filament(filament) }
        }
      end

      def show
        render json: {
          data: serialize_filament(@filament)
        }
      end

      def create
        @filament = current_user.filaments.build(filament_params)

        if @filament.save
          render json: {
            data: serialize_filament(@filament)
          }, status: :created
        else
          render json: {
            errors: @filament.errors.map do |error|
              {
                status: "422",
                code: "validation_error",
                title: "Validation Failed",
                detail: error.full_message,
                source: { pointer: "/data/attributes/#{error.attribute}" }
              }
            end
          }, status: :unprocessable_entity
        end
      end

      def update
        if @filament.update(filament_params)
          render json: {
            data: serialize_filament(@filament)
          }
        else
          render json: {
            errors: @filament.errors.map do |error|
              {
                status: "422",
                code: "validation_error",
                title: "Validation Failed",
                detail: error.full_message,
                source: { pointer: "/data/attributes/#{error.attribute}" }
              }
            end
          }, status: :unprocessable_entity
        end
      end

      def destroy
        @filament.destroy
        head :no_content
      end

      def duplicate
        @new_filament = @filament.dup
        @new_filament.name = "#{@filament.name} (Copy)"

        if @new_filament.save
          render json: {
            data: serialize_filament(@new_filament)
          }, status: :created
        else
          render json: {
            errors: @new_filament.errors.map do |error|
              {
                status: "422",
                code: "validation_error",
                title: "Duplicate Failed",
                detail: error.full_message,
                source: { pointer: "/data/attributes/#{error.attribute}" }
              }
            end
          }, status: :unprocessable_entity
        end
      end

      private

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

      def serialize_filament(filament)
        {
          id: filament.id.to_s,
          type: "filament",
          attributes: {
            name: filament.name,
            brand: filament.brand,
            material_type: filament.material_type,
            color: filament.color,
            finish: filament.finish,
            diameter: filament.diameter&.to_f,
            density: filament.density&.to_f,
            print_temperature_min: filament.print_temperature_min,
            print_temperature_max: filament.print_temperature_max,
            heated_bed_temperature: filament.heated_bed_temperature,
            print_speed_max: filament.print_speed_max,
            spool_weight: filament.spool_weight&.to_f,
            spool_price: filament.spool_price&.to_f,
            cost_per_gram: filament.cost_per_gram&.to_f,
            storage_temperature_max: filament.storage_temperature_max,
            moisture_sensitive: filament.moisture_sensitive,
            notes: filament.notes,
            created_at: filament.created_at.iso8601,
            updated_at: filament.updated_at.iso8601
          }
        }
      end
    end
  end
end
