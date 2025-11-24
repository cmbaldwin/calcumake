# frozen_string_literal: true

module Invoices
  class StatusBadgeComponent < ViewComponent::Base
    def initialize(invoice:, size: "md")
      @invoice = invoice
      @size = size
    end

    def variant_for_status(status)
      case status
      when "paid" then "success"
      when "sent" then "info"
      when "cancelled" then "danger"
      else "secondary" # draft or any other status
      end
    end

    def size_class(size)
      case size
      when "sm" then "fs-7"
      when "md" then "fs-6"
      when "lg" then "fs-4"
      when "" then ""
      else "fs-6" # default
      end
    end

    def status_text
      I18n.t("invoices.status.#{@invoice.status}")
    end
  end
end
