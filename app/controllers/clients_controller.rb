class ClientsController < ApplicationController
  include ResourceAuthorization

  before_action :authenticate_user!
  before_action :set_client, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_client, only: [ :show, :edit, :update, :destroy ]

  def index
    @q = current_user.clients.ransack(params[:q])
    @clients = @q.result.order(created_at: :desc)
  end

  def show
  end

  def new
    @client = current_user.clients.build
  end

  def create
    @client = current_user.clients.build(client_params)

    if @client.save
      redirect_to @client, notice: t("clients.created_successfully")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @client.update(client_params)
      redirect_to @client, notice: t("clients.updated_successfully")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @client.destroy
    redirect_to clients_path, notice: t("clients.deleted_successfully")
  end

  private

  def set_client
    @client = current_user.clients.find(params[:id])
  end

  def authorize_client
    authorize_resource_ownership!(@client, redirect_path: root_path)
  end

  def client_params
    params.require(:client).permit(:name, :company_name, :email, :phone, :address, :tax_id, :notes)
  end
end
