# frozen_string_literal: true

module Api
  module V1
    class ResinsController < BaseController
      before_action :set_resin, only: %i[show update destroy duplicate]

      def index
        @resins = current_user.resins.order(:resin_type, :name)

        # Apply search filter
        @resins = @resins.search(params[:q]) if params[:q].present?

        # Apply type filter
        @resins = @resins.by_resin_type(params[:resin_type]) if params[:resin_type].present?

        render json: {
          data: @resins.map { |resin| serialize_resin(resin) }
        }
      end

      def show
        render json: {
          data: serialize_resin(@resin)
        }
      end

      def create
        @resin = current_user.resins.build(resin_params)

        if @resin.save
          render json: {
            data: serialize_resin(@resin)
          }, status: :created
        else
          render json: {
            errors: @resin.errors.map do |error|
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
        if @resin.update(resin_params)
          render json: {
            data: serialize_resin(@resin)
          }
        else
          render json: {
            errors: @resin.errors.map do |error|
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
        @resin.destroy
        head :no_content
      end

      def duplicate
        @new_resin = @resin.dup
        @new_resin.name = "#{@resin.name} (Copy)"

        if @new_resin.save
          render json: {
            data: serialize_resin(@new_resin)
          }, status: :created
        else
          render json: {
            errors: @new_resin.errors.map do |error|
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

      def set_resin
        @resin = current_user.resins.find(params[:id])
      end

      def resin_params
        params.require(:resin).permit(
          :name, :brand, :resin_type, :color,
          :bottle_volume_ml, :bottle_price,
          :cure_time_seconds, :exposure_time_seconds,
          :layer_height_min, :layer_height_max,
          :needs_wash, :notes
        )
      end

      def serialize_resin(resin)
        {
          id: resin.id.to_s,
          type: "resin",
          attributes: {
            name: resin.name,
            brand: resin.brand,
            resin_type: resin.resin_type,
            color: resin.color,
            bottle_volume_ml: resin.bottle_volume_ml&.to_f,
            bottle_price: resin.bottle_price&.to_f,
            cost_per_ml: resin.cost_per_ml&.to_f,
            cure_time_seconds: resin.cure_time_seconds,
            exposure_time_seconds: resin.exposure_time_seconds,
            layer_height_min: resin.layer_height_min&.to_f,
            layer_height_max: resin.layer_height_max&.to_f,
            layer_height_range: resin.layer_height_range,
            needs_wash: resin.needs_wash,
            notes: resin.notes,
            display_name: resin.display_name,
            created_at: resin.created_at.iso8601,
            updated_at: resin.updated_at.iso8601
          }
        }
      end
    end
  end
end
