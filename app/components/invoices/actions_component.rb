# frozen_string_literal: true

module Invoices
  # ActionsComponent displays action buttons for invoice show page
  #
  # Usage:
  #   <%= render Invoices::ActionsComponent.new(
  #     invoice: @invoice,
  #     print_pricing: @print_pricing
  #   ) %>
  #
  # Parameters:
  #   invoice: Invoice model with status
  #   print_pricing: PrintPricing model (for URL generation)
  #   wrapper_class: Optional CSS class for wrapper div (default: none)
  #   show_status_actions: Show mark as sent/paid buttons (default: true)
  #   show_edit: Show edit button (default: true)
  #   show_pdf: Show PDF download button (default: true)
  #   show_print: Show print button (default: true)
  #
  class ActionsComponent < ViewComponent::Base
    def initialize(
      invoice:,
      print_pricing:,
      wrapper_class: nil,
      show_status_actions: true,
      show_edit: true,
      show_pdf: true,
      show_print: true
    )
      @invoice = invoice
      @print_pricing = print_pricing
      @wrapper_class = wrapper_class
      @show_status_actions = show_status_actions
      @show_edit = show_edit
      @show_pdf = show_pdf
      @show_print = show_print
    end

    def show_status_actions?
      @show_status_actions && @invoice.status != "paid"
    end

    def mark_as_sent_disabled?
      @invoice.status != "draft"
    end

    def mark_as_paid_disabled?
      @invoice.status == "draft"
    end
  end
end
