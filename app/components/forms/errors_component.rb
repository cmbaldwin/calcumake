# frozen_string_literal: true

module Forms
  class ErrorsComponent < ViewComponent::Base
    def initialize(model:, dismissible: false, html_options: {})
      @model = model
      @dismissible = dismissible
      @html_options = html_options
    end

    def render?
      @model.errors.any?
    end

    def alert_classes
      classes = [ "alert", "alert-danger", "mb-4" ]
      classes << "alert-dismissible fade show" if @dismissible
      classes << @html_options[:class] if @html_options[:class]
      classes.join(" ")
    end

    def model_name
      @model.class.model_name.human.downcase
    end

    def error_count_text
      I18n.t("common.error_count", count: @model.errors.count)
    end

    def errors_prohibited_text
      I18n.t(
        "common.errors_prohibited",
        count: @model.errors.count,
        errors: error_count_text,
        model: model_name
      )
    end
  end
end
