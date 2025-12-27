# frozen_string_literal: true

class ApiTokensController < ApplicationController
  before_action :authenticate_user!
  before_action :set_api_token, only: :destroy

  def index
    @api_tokens = current_user.api_tokens.order(created_at: :desc)

    # Check if we need to display a newly created token
    if session[:new_api_token_id] && session[:new_api_token_plain]
      @newly_created_token = @api_tokens.find_by(id: session.delete(:new_api_token_id))
      @plain_token = session.delete(:new_api_token_plain)
    end
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
      # Store the plain token in session for one-time display
      session[:new_api_token_id] = @api_token.id
      session[:new_api_token_plain] = @api_token.plain_token

      redirect_to api_tokens_path, notice: t("api_tokens.created_success")
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
