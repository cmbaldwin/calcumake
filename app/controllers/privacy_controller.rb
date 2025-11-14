class PrivacyController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :data_export ]
  before_action :authenticate_user!, only: [ :data_export, :data_deletion ]

  def privacy_policy
    # Privacy policy page - accessible to all users
  end

  def terms_of_service
    # Terms of service page - accessible to all users
  end

  def cookie_policy
    # Cookie policy page - accessible to all users
  end

  def data_export
    # GDPR Right to Data Portability - users can export all their data
    respond_to do |format|
      format.json do
        send_data current_user.export_data.to_json,
                  filename: "calcumake_data_export_#{current_user.id}_#{Time.current.to_i}.json",
                  type: "application/json",
                  disposition: "attachment"
      end
      format.html do
        # Show export page with download button
      end
    end
  end

  def data_deletion
    # GDPR Right to Erasure - users can request account deletion
    if request.post?
      # Soft delete or mark for deletion - depending on requirements
      current_user.destroy
      sign_out current_user
      redirect_to root_path, notice: t("gdpr.account_deleted")
    end
  end
end
