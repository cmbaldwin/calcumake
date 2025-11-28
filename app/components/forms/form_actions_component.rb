# frozen_string_literal: true

module Forms
  class FormActionsComponent < ViewComponent::Base
    def initialize(
      form:,
      submit_text: nil,
      cancel_url: nil,
      cancel_text: nil,
      submit_class: "btn btn-primary px-4",
      cancel_class: "btn btn-outline-secondary px-4",
      wrapper_class: "d-flex justify-content-center gap-3 mb-5",
      submit_data: {},
      cancel_data: {}
    )
      @form = form
      @submit_text = submit_text
      @cancel_url = cancel_url
      @cancel_text = cancel_text
      @submit_class = submit_class
      @cancel_class = cancel_class
      @wrapper_class = wrapper_class
      @submit_data = submit_data
      @cancel_data = cancel_data
    end

    private

    attr_reader :form, :submit_text, :cancel_url, :cancel_text,
                :submit_class, :cancel_class, :wrapper_class,
                :submit_data, :cancel_data

    def default_submit_text
      if form_object&.persisted?
        I18n.t("actions.update", default: "Update")
      else
        I18n.t("actions.create", default: "Create")
      end
    end

    def default_cancel_text
      I18n.t("actions.cancel", default: "Cancel")
    end

    def resolved_submit_text
      submit_text || default_submit_text
    end

    def resolved_cancel_text
      cancel_text || default_cancel_text
    end

    def show_cancel?
      cancel_url.present?
    end

    # Helper to safely get the form object
    def form_object
      @form&.object
    rescue StandardError
      nil
    end
  end
end
