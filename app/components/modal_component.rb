# frozen_string_literal: true

class ModalComponent < ViewComponent::Base
  SIZES = %w[sm md lg xl].freeze

  renders_one :header
  renders_one :body
  renders_one :footer

  def initialize(
    id:,
    title: nil,
    size: "md",
    footer: true,
    centered: false,
    scrollable: false,
    html_options: {}
  )
    @id = id
    @title = title
    @size = size
    @show_footer = footer
    @centered = centered
    @scrollable = scrollable
    @html_options = html_options

    validate_size!
  end

  def modal_dialog_classes
    classes = ["modal-dialog"]
    classes << "modal-#{@size}" unless @size == "md"
    classes << "modal-dialog-centered" if @centered
    classes << "modal-dialog-scrollable" if @scrollable
    classes.join(" ")
  end

  def show_default_footer?
    @show_footer && !footer?
  end

  private

  def validate_size!
    return if SIZES.include?(@size)
    raise ArgumentError, "Invalid size: #{@size}. Must be one of: #{SIZES.join(', ')}"
  end
end
