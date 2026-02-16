# frozen_string_literal: true

class SetupAssistantController < ApplicationController
  before_action :authenticate_user!

  def message
    result = Ai::SetupAssistant.new(
      user: current_user,
      context: assistant_params[:context],
      onboarding_step: assistant_params[:onboarding_step]
    ).call(
      message: assistant_params[:message],
      conversation: assistant_params[:conversation]
    )

    status = result[:ok] ? :ok : :unprocessable_entity
    render json: result.except(:ok), status: status
  end

  private

  def assistant_params
    permitted = params.permit(:message, :context, :onboarding_step, conversation: [ :role, :content ])
    permitted[:conversation] ||= []
    permitted
  end
end
