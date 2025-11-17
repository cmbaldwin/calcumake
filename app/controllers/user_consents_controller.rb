class UserConsentsController < ApplicationController
  before_action :authenticate_user!, only: :create

  def create
    # Validate required parameters - check key existence, not truthiness
    raise ActionController::ParameterMissing.new(:consent_type) unless params.key?(:consent_type)
    raise ActionController::ParameterMissing.new(:accepted) unless params.key?(:accepted)

    consent = current_user.record_consent(
      params[:consent_type],
      params[:accepted],
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
end
