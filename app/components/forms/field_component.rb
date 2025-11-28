# frozen_string_literal: true

module Forms
  class FieldComponent < ViewComponent::Base
    def initialize(
      form:,
      attribute:,
      type: :text,
      label: nil,
      hint: nil,
      info_popup_key: nil,
      required: false,
      wrapper: true,
      wrapper_class: "col-12",
      options: {}
    )
      @form = form
      @attribute = attribute
      @type = type
      @label = label
      @hint = hint
      @info_popup_key = info_popup_key
      @required = required
      @wrapper = wrapper
      @wrapper_class = wrapper_class
      @options = options || {}
    end

    def label_text
      return nil if @label == false
      @label || @attribute.to_s.humanize
    end

    def show_label?
      @label != false
    end

    def field_options
      opts = @options.dup
      opts[:class] = merge_classes("form-control", opts[:class])
      opts[:required] = true if @required
      opts
    end

    def show_hint?
      @hint.present?
    end

    def show_info_popup?
      @info_popup_key.present?
    end

    def info_popup_key
      @info_popup_key
    end

    private

    def merge_classes(*classes)
      classes.compact.join(" ")
    end
  end
end
