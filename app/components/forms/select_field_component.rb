# frozen_string_literal: true

module Forms
  # Renders a select/dropdown field with consistent styling and validation
  #
  # @example Basic select
  #   <%= render Forms::SelectFieldComponent.new(
  #     form: form,
  #     attribute: :status,
  #     choices: [['Draft', 'draft'], ['Published', 'published']],
  #     label: "Status"
  #   ) %>
  #
  # @example With prompt and required
  #   <%= render Forms::SelectFieldComponent.new(
  #     form: form,
  #     attribute: :material_type,
  #     choices: [['PLA', 'pla'], ['ABS', 'abs']],
  #     prompt: "Select material...",
  #     required: true
  #   ) %>
  #
  # @example Collection select
  #   <%= render Forms::SelectFieldComponent.new(
  #     form: form,
  #     attribute: :client_id,
  #     collection: @clients,
  #     value_method: :id,
  #     text_method: :name,
  #     label: "Client"
  #   ) %>
  class SelectFieldComponent < ViewComponent::Base
    def initialize(
      form:,
      attribute:,
      choices: nil,
      collection: nil,
      value_method: nil,
      text_method: nil,
      label: nil,
      hint: nil,
      prompt: nil,
      include_blank: false,
      required: false,
      wrapper: true,
      wrapper_class: "col-12",
      select_options: {},
      html_options: {}
    )
      @form = form
      @attribute = attribute
      @choices = choices
      @collection = collection
      @value_method = value_method
      @text_method = text_method
      @label = label
      @hint = hint
      @prompt = prompt
      @include_blank = include_blank
      @required = required
      @wrapper = wrapper
      @wrapper_class = wrapper_class
      @select_options = select_options || {}
      @html_options = html_options || {}
    end

    def label_text
      return nil if @label == false
      @label || @attribute.to_s.humanize
    end

    def show_label?
      @label != false
    end

    def show_hint?
      @hint.present?
    end

    def select_options
      opts = @select_options.dup
      opts[:prompt] = @prompt if @prompt
      opts[:include_blank] = @include_blank if @include_blank && !@prompt
      opts
    end

    def html_options
      opts = @html_options.dup
      opts[:class] = merge_classes("form-select", opts[:class])
      opts[:required] = true if @required
      opts
    end

    def using_collection?
      @collection.present?
    end

    private

    def merge_classes(*classes)
      classes.compact.join(" ")
    end
  end
end
