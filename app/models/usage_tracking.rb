class UsageTracking < ApplicationRecord
  belongs_to :user

  # Supported resource types for usage tracking
  RESOURCE_TYPES = %w[print_pricing printer filament invoice].freeze

  validates :resource_type, presence: true, inclusion: { in: RESOURCE_TYPES }
  validates :count, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :period_start, presence: true
  validates :user_id, uniqueness: { scope: [:resource_type, :period_start] }

  # Get or create usage tracking for the current month
  def self.for_current_period(user, resource_type)
    period_start = Date.current.beginning_of_month
    find_or_create_by!(
      user: user,
      resource_type: resource_type,
      period_start: period_start
    )
  end

  # Increment usage count for a resource
  def self.track!(user, resource_type)
    tracking = for_current_period(user, resource_type)
    tracking.increment!(:count)
  end

  # Get current usage for a user and resource type
  def self.current_usage(user, resource_type)
    for_current_period(user, resource_type).count
  rescue ActiveRecord::RecordNotFound
    0
  end

  # Reset all tracking for a new period (called by background job)
  def self.cleanup_old_periods(months_to_keep = 12)
    cutoff_date = months_to_keep.months.ago.beginning_of_month
    where("period_start < ?", cutoff_date).delete_all
  end
end
