# frozen_string_literal: true

module Forms
  # FormSectionComponent renders a card-based form section with header
  #
  # Usage:
  #   <%= render Forms::FormSectionComponent.new(
  #     title: "Basic Information",
  #     wrapper_class: "col-md-6",
  #     card_class: "h-100",
  #     body_class: "row g-3"
  #   ) do %>
  #     <!-- form fields here -->
  #   <% end %>
  #
  # Parameters:
  #   title: Section heading text (required)
  #   wrapper_class: CSS class for outer wrapper div (optional, default: none)
  #   card_class: CSS class for card element (optional, default: "card")
  #   header_class: CSS class for card header (optional, default: "card-header")
  #   body_class: CSS class for card body content (optional, default: none)
  #   help_text: Optional help text shown at bottom of card body (optional)
  #
  class FormSectionComponent < ViewComponent::Base
    renders_one :help

    def initialize(
      title:,
      wrapper_class: nil,
      card_class: "card",
      header_class: "card-header",
      body_class: nil,
      help_text: nil,
      info_popup_key: nil
    )
      @title = title
      @wrapper_class = wrapper_class
      @card_class = card_class
      @header_class = header_class
      @body_class = body_class
      @help_text = help_text
      @info_popup_key = info_popup_key
    end

    def render_wrapper?
      @wrapper_class.present?
    end

    def body_wrapper_class
      @body_class.present? ? @body_class : nil
    end

    def show_help?
      @help_text.present? || help?
    end

    def show_info_popup?
      @info_popup_key.present?
    end

    def info_popup_key
      @info_popup_key
    end
  end
end
