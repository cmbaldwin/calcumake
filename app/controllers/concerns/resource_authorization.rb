# frozen_string_literal: true

# ResourceAuthorization - Provides methods for authorizing user access to resources
# Include this concern in controllers that need to check resource ownership
module ResourceAuthorization
  extend ActiveSupport::Concern

  private

  # Authorize that the given resource belongs to the current user
  # @param resource [ApplicationRecord] The resource to authorize
  # @param user_attribute [Symbol] The attribute that contains the user (default: :user)
  # @param redirect_path [String, Symbol] Where to redirect if unauthorized (default: root_path)
  # @param message [String] Custom error message (default: from I18n)
  def authorize_resource_ownership!(resource, user_attribute: :user, redirect_path: :root_path, message: nil)
    return if resource.public_send(user_attribute) == current_user

    flash[:alert] = message || t("errors.unauthorized")
    redirect_to redirect_path
  end

  # Find a resource scoped to the current user
  # Raises ActiveRecord::RecordNotFound if not found
  # @param model_class [Class] The model class to query
  # @param param_key [Symbol] The parameter key to use for lookup (default: :id)
  # @return [ApplicationRecord] The found resource
  def find_user_resource(model_class, param_key: :id)
    current_user.public_send(model_class.model_name.collection).find(params[param_key])
  end
end
