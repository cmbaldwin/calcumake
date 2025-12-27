# frozen_string_literal: true

module Api
  module V1
    class PrintersController < BaseController
      before_action :set_printer, only: %i[show update destroy]

      def index
        @printers = current_user.printers.order(:name)

        # Apply technology filter
        if params[:technology].present? && %w[fdm resin].include?(params[:technology])
          @printers = @printers.where(material_technology: params[:technology])
        end

        render json: {
          data: @printers.map { |printer| serialize_printer(printer) }
        }
      end

      def show
        render json: {
          data: serialize_printer(@printer)
        }
      end

      def create
        @printer = current_user.printers.build(printer_params)

        if @printer.save
          render json: {
            data: serialize_printer(@printer)
          }, status: :created
        else
          render json: {
            errors: @printer.errors.map do |error|
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
        if @printer.update(printer_params)
          render json: {
            data: serialize_printer(@printer)
          }
        else
          render json: {
            errors: @printer.errors.map do |error|
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
        @printer.destroy
        head :no_content
      end

      private

      def set_printer
        @printer = current_user.printers.find(params[:id])
      end

      def printer_params
        params.require(:printer).permit(
          :name, :manufacturer, :model, :material_technology,
          :power_consumption, :cost, :payoff_goal_years,
          :daily_usage_hours, :repair_cost_percentage,
          :date_added, :notes
        )
      end

      def serialize_printer(printer)
        {
          id: printer.id.to_s,
          type: "printer",
          attributes: {
            name: printer.name,
            manufacturer: printer.manufacturer,
            material_technology: printer.material_technology,
            power_consumption: printer.power_consumption,
            cost: printer.cost&.to_f,
            payoff_goal_years: printer.payoff_goal_years,
            daily_usage_hours: printer.daily_usage_hours,
            repair_cost_percentage: printer.repair_cost_percentage&.to_f,
            date_added: printer.date_added&.iso8601,
            paid_off: printer.paid_off?,
            months_to_payoff: printer.months_to_payoff,
            created_at: printer.created_at.iso8601,
            updated_at: printer.updated_at.iso8601
          },
          relationships: {
            print_pricings: {
              meta: {
                count: printer.print_pricings.count
              }
            }
          }
        }
      end
    end
  end
end
