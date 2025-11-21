# frozen_string_literal: true

module Forms
  # Renders a number field with prepend/append addons (currency symbols, units, etc.)
  #
  # @example With currency symbol prefix
  #   <%= render Forms::NumberFieldWithAddonComponent.new(
  #     form: form,
  #     attribute: :spool_price,
  #     label: "Price",
  #     prepend: "$"
  #   ) %>
  #
  # @example With unit suffix
  #   <%= render Forms::NumberFieldWithAddonComponent.new(
  #     form: form,
  #     attribute: :spool_weight,
  #     label: "Weight",
  #     append: "g"
  #   ) %>
  #
  # @example With both prefix and suffix
  #   <%= render Forms::NumberFieldWithAddonComponent.new(
  #     form: form,
  #     attribute: :rate,
  #     label: "Hourly Rate",
  #     prepend: "$",
  #     append: "/hr"
  #   ) %>
  class NumberFieldWithAddonComponent < ViewComponent::Base
    def initialize(
      form:,
      attribute:,
      label: nil,
      hint: nil,
      prepend: nil,
      append: nil,
      required: false,
      wrapper: true,
      wrapper_class: "col-12",
      input_group_size: nil,  # sm, lg, or nil for default
      step: 0.01,
      min: nil,
      max: nil,
      placeholder: nil,
      options: {}
    )
      @form = form
      @attribute = attribute
      @label = label
      @hint = hint
      @prepend = prepend
      @append = append
      @required = required
      @wrapper = wrapper
      @wrapper_class = wrapper_class
      @input_group_size = input_group_size
      @step = step
      @min = min
      @max = max
      @placeholder = placeholder
      @options = options || {}
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

    def input_group_class
      classes = ["input-group"]
      classes << "input-group-#{@input_group_size}" if @input_group_size
      classes.join(" ")
    end

    def field_options
      opts = @options.dup
      opts[:class] = merge_classes("form-control", opts[:class])
      opts[:step] = @step if @step
      opts[:min] = @min if @min
      opts[:max] = @max if @max
      opts[:placeholder] = @placeholder if @placeholder
      opts[:required] = true if @required
      opts
    end

    private

    def merge_classes(*classes)
      classes.compact.join(" ")
    end
  end
end
