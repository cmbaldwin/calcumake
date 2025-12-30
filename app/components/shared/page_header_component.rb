# frozen_string_literal: true

module Shared
  class PageHeaderComponent < ViewComponent::Base
    def initialize(
      title:,
      subtitle: nil,
      action_text: nil,
      action_url: nil,
      action_variant: "primary",
      action_size: "lg",
      title_size: "display-5",
      html_options: {}
    )
      @title = title
      @subtitle = subtitle
      @action_text = action_text
      @action_url = action_url
      @action_variant = action_variant
      @action_size = action_size
      @title_size = title_size
      @html_options = html_options
    end

    private

    attr_reader :title, :subtitle, :action_text, :action_url, :action_variant, :action_size, :title_size, :html_options

    def wrapper_classes
      classes = ["text-center", "mb-5"]
      classes << html_options[:class] if html_options[:class].present?
      classes.join(" ")
    end

    def title_classes
      "#{title_size} fw-bold text-primary mb-3"
    end

    def subtitle_classes
      "lead text-muted mb-4"
    end

    def has_action?
      action_text.present? && action_url.present?
    end

    def has_subtitle?
      subtitle.present?
    end

    def action_button_class
      "btn btn-#{action_variant} btn-#{action_size}"
    end
  end
end
