# frozen_string_literal: true

module Forms
  class CheckboxFieldComponent < ViewComponent::Base
    def initialize(
      form:,
      attribute:,
      label: nil,
      hint: nil,
      wrapper: true,
      wrapper_class: "col-12",
      options: {}
    )
      @form = form
      @attribute = attribute
      @label = label
      @hint = hint
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

    def checkbox_options
      opts = @options.dup
      # Extract form-check wrapper classes (like form-switch)
      @form_check_class = opts.delete(:class) if opts[:class].to_s.include?("form-switch")
      opts[:class] = merge_classes("form-check-input", opts[:class])
      opts
    end

    def form_check_class
      merge_classes("form-check", @form_check_class)
    end

    def show_hint?
      @hint.present?
    end

    private

    def merge_classes(*classes)
      classes.compact.join(" ")
    end
  end
end
