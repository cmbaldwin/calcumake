# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      def show
        render json: {
          data: {
            id: current_user.id.to_s,
            type: "user",
            attributes: {
              email: current_user.email,
              default_currency: current_user.default_currency,
              default_energy_cost_per_kwh: current_user.default_energy_cost_per_kwh,
              plan: current_user.plan,
              locale: current_user.locale,
              created_at: current_user.created_at.iso8601,
              updated_at: current_user.updated_at.iso8601
            }
          }
        }
      end

      def update
        if current_user.update(user_params)
          render json: {
            data: {
              id: current_user.id.to_s,
              type: "user",
              attributes: {
                email: current_user.email,
                default_currency: current_user.default_currency,
                default_energy_cost_per_kwh: current_user.default_energy_cost_per_kwh,
                plan: current_user.plan,
                locale: current_user.locale,
                updated_at: current_user.updated_at.iso8601
              }
            }
          }
        else
          render json: {
            errors: current_user.errors.map do |error|
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

      def export_data
        render json: {
          data: current_user.export_data
        }
      end

      def usage_stats
        render json: {
          data: {
            print_pricings_count: current_user.print_pricings.count,
            printers_count: current_user.printers.count,
            filaments_count: current_user.filaments.count,
            clients_count: current_user.clients.count,
            invoices_count: current_user.invoices.count,
            plan: current_user.plan,
            limits: {
              print_pricings: current_user.limit_for("print_pricing"),
              printers: current_user.limit_for("printer"),
              filaments: current_user.limit_for("filament"),
              clients: current_user.limit_for("client")
            }
          }
        }
      end

      private

      def user_params
        params.require(:user).permit(
          :default_currency,
          :default_energy_cost_per_kwh,
          :locale,
          :default_prep_time_minutes,
          :default_prep_cost_per_hour,
          :default_postprocessing_time_minutes,
          :default_postprocessing_cost_per_hour,
          :default_other_costs,
          :default_vat_percentage
        )
      end
    end
  end
end
