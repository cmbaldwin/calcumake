require "test_helper"

class UsageTrackingTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @period_start = Date.current.beginning_of_month
  end

  test "should belong to user" do
    tracking = UsageTracking.new(
      user: @user,
      resource_type: "print_pricing",
      count: 5,
      period_start: @period_start
    )
    assert tracking.valid?
    assert_equal @user, tracking.user
  end

  test "should validate presence of resource_type" do
    tracking = UsageTracking.new(
      user: @user,
      count: 5,
      period_start: @period_start
    )
    assert_not tracking.valid?
    assert_includes tracking.errors[:resource_type], "can't be blank"
  end

  test "should validate resource_type is in allowed list" do
    valid_types = %w[print_pricing printer filament invoice]

    valid_types.each do |type|
      tracking = UsageTracking.new(
        user: @user,
        resource_type: type,
        count: 5,
        period_start: @period_start
      )
      assert tracking.valid?, "#{type} should be valid"
    end

    tracking = UsageTracking.new(
      user: @user,
      resource_type: "invalid_type",
      count: 5,
      period_start: @period_start
    )
    assert_not tracking.valid?
    assert_includes tracking.errors[:resource_type], "is not included in the list"
  end

  test "should validate uniqueness of user, resource_type, and period_start" do
    UsageTracking.create!(
      user: @user,
      resource_type: "print_pricing",
      count: 5,
      period_start: @period_start
    )

    duplicate = UsageTracking.new(
      user: @user,
      resource_type: "print_pricing",
      count: 10,
      period_start: @period_start
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "should allow same resource_type for different users" do
    other_user = users(:two)

    UsageTracking.create!(
      user: @user,
      resource_type: "print_pricing",
      count: 5,
      period_start: @period_start
    )

    tracking = UsageTracking.new(
      user: other_user,
      resource_type: "print_pricing",
      count: 10,
      period_start: @period_start
    )

    assert tracking.valid?
  end

  test "for_current_period should find or create tracking for current month" do
    tracking = UsageTracking.for_current_period(@user, "print_pricing")

    assert_equal @user, tracking.user
    assert_equal "print_pricing", tracking.resource_type
    assert_equal Date.current.beginning_of_month, tracking.period_start
    assert_equal 0, tracking.count
  end

  test "for_current_period should return existing tracking" do
    existing = UsageTracking.create!(
      user: @user,
      resource_type: "print_pricing",
      count: 5,
      period_start: @period_start
    )

    tracking = UsageTracking.for_current_period(@user, "print_pricing")

    assert_equal existing.id, tracking.id
    assert_equal 5, tracking.count
  end

  test "track! should increment usage count" do
    UsageTracking.track!(@user, "print_pricing")

    tracking = UsageTracking.find_by(
      user: @user,
      resource_type: "print_pricing",
      period_start: @period_start
    )

    assert_equal 1, tracking.count

    UsageTracking.track!(@user, "print_pricing")
    tracking.reload
    assert_equal 2, tracking.count
  end

  test "current_usage should return count for current period" do
    UsageTracking.create!(
      user: @user,
      resource_type: "invoice",
      count: 7,
      period_start: @period_start
    )

    usage = UsageTracking.current_usage(@user, "invoice")
    assert_equal 7, usage
  end

  test "current_usage should return 0 if no tracking exists" do
    usage = UsageTracking.current_usage(@user, "print_pricing")
    assert_equal 0, usage
  end

  test "cleanup_old_periods should delete old tracking records" do
    # Create tracking for 13 months ago (should be deleted)
    old_tracking = UsageTracking.create!(
      user: @user,
      resource_type: "print_pricing",
      count: 5,
      period_start: 13.months.ago.beginning_of_month
    )

    # Create tracking for 6 months ago (should be kept)
    recent_tracking = UsageTracking.create!(
      user: @user,
      resource_type: "invoice",
      count: 3,
      period_start: 6.months.ago.beginning_of_month
    )

    # Create current tracking (should be kept)
    current_tracking = UsageTracking.create!(
      user: @user,
      resource_type: "filament",
      count: 2,
      period_start: @period_start
    )

    UsageTracking.cleanup_old_periods(12)

    assert_not UsageTracking.exists?(old_tracking.id)
    assert UsageTracking.exists?(recent_tracking.id)
    assert UsageTracking.exists?(current_tracking.id)
  end
end
