# frozen_string_literal: true

module Api
  module V1
    class PrintPricingsController < BaseController
      before_action :set_print_pricing, only: %i[show update destroy duplicate increment_times_printed decrement_times_printed]

      def index
        @print_pricings = current_user.print_pricings
          .includes(:printer, :client, plates: [ :plate_filaments, :filaments, :plate_resins, :resins ])
          .order(created_at: :desc)

        # Apply search filter
        @print_pricings = @print_pricings.search(params[:q]) if params[:q].present?

        render json: {
          data: @print_pricings.map { |pricing| serialize_print_pricing(pricing) }
        }
      end

      def show
        render json: {
          data: serialize_print_pricing(@print_pricing, include_plates: true)
        }
      end

      def create
        @print_pricing = current_user.print_pricings.build(print_pricing_params)

        if @print_pricing.save
          render json: {
            data: serialize_print_pricing(@print_pricing, include_plates: true)
          }, status: :created
        else
          render json: {
            errors: @print_pricing.errors.map do |error|
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
        if @print_pricing.update(print_pricing_params)
          render json: {
            data: serialize_print_pricing(@print_pricing, include_plates: true)
          }
        else
          render json: {
            errors: @print_pricing.errors.map do |error|
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
        @print_pricing.destroy
        head :no_content
      end

      def duplicate
        @new_pricing = @print_pricing.dup
        @new_pricing.job_name = "#{@print_pricing.job_name} (Copy)"
        @new_pricing.times_printed = 0

        # Duplicate plates with their materials
        @print_pricing.plates.each do |plate|
          new_plate = plate.dup
          @new_pricing.plates << new_plate

          # Duplicate plate filaments
          plate.plate_filaments.each do |pf|
            new_plate.plate_filaments << pf.dup
          end

          # Duplicate plate resins
          plate.plate_resins.each do |pr|
            new_plate.plate_resins << pr.dup
          end
        end

        if @new_pricing.save
          render json: {
            data: serialize_print_pricing(@new_pricing, include_plates: true)
          }, status: :created
        else
          render json: {
            errors: @new_pricing.errors.map do |error|
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

      def increment_times_printed
        @print_pricing.increment_times_printed!
        render json: {
          data: {
            id: @print_pricing.id.to_s,
            times_printed: @print_pricing.times_printed
          }
        }
      end

      def decrement_times_printed
        @print_pricing.decrement_times_printed!
        render json: {
          data: {
            id: @print_pricing.id.to_s,
            times_printed: @print_pricing.times_printed
          }
        }
      end

      private

      def set_print_pricing
        @print_pricing = current_user.print_pricings
          .includes(plates: [ :plate_filaments, :filaments, :plate_resins, :resins ])
          .find(params[:id])
      end

      def print_pricing_params
        params.require(:print_pricing).permit(
          :job_name, :printer_id, :client_id, :units, :times_printed,
          :prep_time_minutes, :prep_cost_per_hour,
          :postprocessing_time_minutes, :postprocessing_cost_per_hour,
          :other_costs, :vat_percentage, :failure_rate_percentage,
          :listing_cost_percentage, :payment_processing_cost_percentage,
          plates_attributes: [
            :id, :_destroy, :printing_time_hours, :printing_time_minutes, :material_technology,
            plate_filaments_attributes: [ :id, :_destroy, :filament_id, :filament_weight, :markup_percentage ],
            plate_resins_attributes: [ :id, :_destroy, :resin_id, :resin_volume_ml, :markup_percentage ]
          ]
        )
      end

      def serialize_print_pricing(pricing, include_plates: false)
        data = {
          id: pricing.id.to_s,
          type: "print_pricing",
          attributes: {
            job_name: pricing.job_name,
            units: pricing.units,
            times_printed: pricing.times_printed,
            total_printing_time_minutes: pricing.total_printing_time_minutes,
            total_material_cost: pricing.total_material_cost&.to_f,
            total_electricity_cost: pricing.total_electricity_cost&.to_f,
            total_labor_cost: pricing.total_labor_cost&.to_f,
            total_machine_upkeep_cost: pricing.total_machine_upkeep_cost&.to_f,
            total_listing_cost: pricing.total_listing_cost&.to_f,
            total_payment_processing_cost: pricing.total_payment_processing_cost&.to_f,
            subtotal: pricing.calculate_subtotal&.to_f,
            final_price: pricing.final_price&.to_f,
            per_unit_price: pricing.per_unit_price&.to_f,
            currency: pricing.default_currency,
            prep_time_minutes: pricing.prep_time_minutes,
            prep_cost_per_hour: pricing.prep_cost_per_hour&.to_f,
            postprocessing_time_minutes: pricing.postprocessing_time_minutes,
            postprocessing_cost_per_hour: pricing.postprocessing_cost_per_hour&.to_f,
            other_costs: pricing.other_costs&.to_f,
            vat_percentage: pricing.vat_percentage&.to_f,
            failure_rate_percentage: pricing.failure_rate_percentage&.to_f,
            listing_cost_percentage: pricing.listing_cost_percentage&.to_f,
            payment_processing_cost_percentage: pricing.payment_processing_cost_percentage&.to_f,
            created_at: pricing.created_at.iso8601,
            updated_at: pricing.updated_at.iso8601
          },
          relationships: {
            printer: pricing.printer ? {
              data: { id: pricing.printer.id.to_s, type: "printer" }
            } : nil,
            client: pricing.client ? {
              data: { id: pricing.client.id.to_s, type: "client" }
            } : nil,
            plates: {
              meta: { count: pricing.plates.count }
            },
            invoices: {
              meta: { count: pricing.invoices.count }
            }
          }
        }

        if include_plates
          data[:relationships][:plates][:data] = pricing.plates.map do |plate|
            serialize_plate(plate)
          end
        end

        data
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
            material_types: plate.material_types
          },
          relationships: {
            filaments: plate.fdm? ? {
              data: plate.plate_filaments.map do |pf|
                {
                  id: pf.id.to_s,
                  filament_id: pf.filament_id.to_s,
                  filament_name: pf.filament&.name,
                  filament_weight: pf.filament_weight&.to_f,
                  markup_percentage: pf.markup_percentage&.to_f,
                  total_cost: pf.total_cost&.to_f
                }
              end
            } : nil,
            resins: plate.resin? ? {
              data: plate.plate_resins.map do |pr|
                {
                  id: pr.id.to_s,
                  resin_id: pr.resin_id.to_s,
                  resin_name: pr.resin&.display_name,
                  resin_volume_ml: pr.resin_volume_ml&.to_f,
                  markup_percentage: pr.markup_percentage&.to_f,
                  total_cost: pr.total_cost&.to_f
                }
              end
            } : nil
          }
        }
      end
    end
  end
end
