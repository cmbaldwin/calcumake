# frozen_string_literal: true

class ApiTokensController < ApplicationController
  before_action :authenticate_user!
  before_action :set_api_token, only: :destroy

  def index
    @api_tokens = current_user.api_tokens.order(created_at: :desc)
  end

  def new
    @api_token = current_user.api_tokens.build
  end

  def create
    @api_token = current_user.api_tokens.build(api_token_params)
    @api_token.created_from_ip = request.remote_ip
    @api_token.user_agent = request.user_agent

    # Set expiration based on selected option
    set_expiration

    if @api_token.save
      @plain_token = @api_token.plain_token

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to user_profile_path(anchor: "api-tokens"), notice: t("api_tokens.created_success") }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @api_token.revoke!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to user_profile_path(anchor: "api-tokens"), notice: t("api_tokens.revoked_success") }
    end
  end

  private

  def set_api_token
    @api_token = current_user.api_tokens.find(params[:id])
  end

  def api_token_params
    params.require(:api_token).permit(:name)
  end

  def set_expiration
    expiration_option = params.dig(:api_token, :expiration) || ApiToken::DEFAULT_EXPIRATION
    duration = ApiToken.expiration_duration(expiration_option)
    @api_token.expires_at = duration ? duration.from_now : nil
  end
end
