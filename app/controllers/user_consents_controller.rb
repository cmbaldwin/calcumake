class UserConsentsController < ApplicationController
  before_action :authenticate_user!, only: :create

  def create
    consent = current_user.record_consent(
      consent_params[:consent_type],
      consent_params[:accepted],
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    respond_to do |format|
      format.json { render json: { success: true, consent: consent }, status: :created }
      format.html { redirect_back fallback_location: root_path, notice: t("gdpr.consent_recorded") }
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.json { render json: { success: false, errors: e.record.errors.full_messages }, status: :unprocessable_entity }
      format.html { redirect_back fallback_location: root_path, alert: t("gdpr.consent_error") }
    end
  end

  private

  def consent_params
    params.require(:consent_type)
    params.require(:accepted)
    params.permit(:consent_type, :accepted)
  end
end
