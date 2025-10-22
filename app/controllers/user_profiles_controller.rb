class UserProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(user_params)
      redirect_to user_profile_path, notice: "Profile updated successfully."
    else
      render :show, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :default_currency,
      :default_energy_cost_per_kwh,
      :default_company_name,
      :default_company_address,
      :default_company_email,
      :default_company_phone,
      :default_payment_details,
      :default_invoice_notes,
      :company_logo
    )
  end
end
