# frozen_string_literal: true

class UsageStatsComponent < ViewComponent::Base
  def initialize(usage:)
    @usage = usage
  end

  def resources
    [
      { key: :print_pricings, data: @usage[:print_pricings] || @usage["print_pricings"] },
      { key: :printers, data: @usage[:printers] || @usage["printers"] },
      { key: :filaments, data: @usage[:filaments] || @usage["filaments"] },
      { key: :invoices, data: @usage[:invoices] || @usage["invoices"] }
    ]
  end

  def approaching_limits
    @usage.select { |_k, v| v[:percentage] >= 80 && v[:limit] != Float::INFINITY }
  end

  def has_approaching_limits?
    approaching_limits.any?
  end
end
