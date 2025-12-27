# frozen_string_literal: true

module Api
  module V1
    class ClientsController < BaseController
      before_action :set_client, only: %i[show update destroy]

      def index
        @clients = current_user.clients.order(:name)

        # Apply search filter
        @clients = @clients.search(params[:q]) if params[:q].present?

        render json: {
          data: @clients.map { |client| serialize_client(client) }
        }
      end

      def show
        render json: {
          data: serialize_client(@client)
        }
      end

      def create
        @client = current_user.clients.build(client_params)

        if @client.save
          render json: {
            data: serialize_client(@client)
          }, status: :created
        else
          render json: {
            errors: @client.errors.map do |error|
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
        if @client.update(client_params)
          render json: {
            data: serialize_client(@client)
          }
        else
          render json: {
            errors: @client.errors.map do |error|
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
        @client.destroy
        head :no_content
      end

      private

      def set_client
        @client = current_user.clients.find(params[:id])
      end

      def client_params
        params.require(:client).permit(
          :name, :email, :phone, :company_name,
          :address, :city, :state, :postal_code, :country,
          :notes
        )
      end

      def serialize_client(client)
        {
          id: client.id.to_s,
          type: "client",
          attributes: {
            name: client.name,
            email: client.email,
            phone: client.phone,
            company_name: client.company_name,
            address: client.address,
            city: client.city,
            state: client.state,
            postal_code: client.postal_code,
            country: client.country,
            notes: client.notes,
            created_at: client.created_at.iso8601,
            updated_at: client.updated_at.iso8601
          },
          relationships: {
            print_pricings: {
              meta: { count: client.print_pricings.count }
            },
            invoices: {
              meta: { count: client.invoices.count }
            }
          }
        }
      end
    end
  end
end
