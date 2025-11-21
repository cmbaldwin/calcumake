# frozen_string_literal: true

module Shared
  # Renders Bootstrap modal dialogs with flexible content slots
  #
  # @example Basic modal
  #   <%= render Shared::ModalComponent.new(id: "my-modal", title: "Modal Title") do |c| %>
  #     <% c.with_body do %>
  #       Modal content here
  #     <% end %>
  #   <% end %>
  #
  # @example Modal with custom footer
  #   <%= render Shared::ModalComponent.new(id: "confirm-modal", title: "Confirm Action") do |c| %>
  #     <% c.with_body do %>
  #       Are you sure?
  #     <% end %>
  #     <% c.with_footer do %>
  #       <%= link_to "Cancel", "#", class: "btn btn-secondary", data: { bs_dismiss: "modal" } %>
  #       <%= link_to "Confirm", "#", class: "btn btn-primary" %>
  #     <% end %>
  #   <% end %>
  #
  # @example Large centered modal
  #   <%= render Shared::ModalComponent.new(id: "large-modal", title: "Details", size: "lg", centered: true) do |c| %>
  #     <% c.with_body do %>
  #       Large modal content
  #     <% end %>
  #   <% end %>
  class ModalComponent < ViewComponent::Base
    renders_one :body
    renders_one :footer

    # @param id [String] Unique ID for the modal (required for Bootstrap modal functionality)
    # @param title [String] Modal title text
    # @param size [String] Modal size: 'sm', 'md', 'lg', 'xl', 'fullscreen'
    # @param centered [Boolean] Whether to vertically center the modal
    # @param scrollable [Boolean] Whether modal body should be scrollable
    # @param static_backdrop [Boolean] Whether clicking backdrop closes modal (false = closes, true = static)
    # @param html_options [Hash] Additional HTML attributes for the modal wrapper
    def initialize(
      id:,
      title:,
      size: "md",
      centered: false,
      scrollable: false,
      static_backdrop: false,
      html_options: {}
    )
      @id = id
      @title = title
      @size = size
      @centered = centered
      @scrollable = scrollable
      @static_backdrop = static_backdrop
      @html_options = html_options
    end

    # Returns combined CSS classes for the modal wrapper
    # @return [String]
    def modal_classes
      classes = [ "modal", "fade" ]
      classes << @html_options[:class] if @html_options[:class]
      classes.compact.join(" ")
    end

    # Returns combined CSS classes for the modal dialog
    # @return [String]
    def dialog_classes
      classes = [ "modal-dialog" ]
      classes << size_class if @size != "md"
      classes << "modal-dialog-centered" if @centered
      classes << "modal-dialog-scrollable" if @scrollable
      classes.compact.join(" ")
    end

    # Returns html_options without class
    # @return [Hash]
    def modal_attrs
      attrs = @html_options.except(:class)
      attrs[:id] = @id
      attrs[:tabindex] = "-1"
      attrs[:role] = "dialog"
      attrs[:"aria-labelledby"] = "#{@id}Title"
      attrs[:"aria-hidden"] = "true"
      attrs[:data] ||= {}
      attrs[:data][:bs_backdrop] = "static" if @static_backdrop
      attrs[:data][:bs_keyboard] = "false" if @static_backdrop
      attrs
    end

    private

    # Maps size parameter to Bootstrap modal size class
    # @return [String, nil]
    def size_class
      case @size
      when "sm" then "modal-sm"
      when "lg" then "modal-lg"
      when "xl" then "modal-xl"
      when "fullscreen" then "modal-fullscreen"
      end
    end
  end
end
