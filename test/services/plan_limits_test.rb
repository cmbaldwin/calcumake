require "test_helper"

class PlanLimitsTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @user.update!(plan: "free", trial_ends_at: nil)
  end

  # Helper method to create a print_pricing record (replaces UsageTracking.track!)
  def create_print_pricing(user)
    printer = user.printers.first || user.printers.create!(
      name: "Test Printer",
      power_consumption: 200,
      cost: 500,
      payoff_goal_years: 3,
      daily_usage_hours: 8
    )
    filament = user.filaments.first || user.filaments.create!(
      name: "Test Filament",
      cost_per_kg: 20,
      color: "Black",
      material: "PLA"
    )
    pricing = user.print_pricings.build(job_name: "Test Job #{user.print_pricings.count + 1}", printer: printer)
    plate = pricing.plates.build(printing_time_hours: 1, printing_time_minutes: 0)
    plate.plate_filaments.build(filament: filament, filament_weight: 10)
    pricing.save!
    pricing
  end

  test "FREE_LIMITS should have correct limits" do
    assert_equal 5, PlanLimits::FREE_LIMITS[:print_pricings]
    assert_equal 1, PlanLimits::FREE_LIMITS[:printers]
    assert_equal 4, PlanLimits::FREE_LIMITS[:filaments]
    assert_equal 5, PlanLimits::FREE_LIMITS[:invoices]
  end

  test "STARTUP_LIMITS should have correct limits" do
    assert_equal 50, PlanLimits::STARTUP_LIMITS[:print_pricings]
    assert_equal 10, PlanLimits::STARTUP_LIMITS[:printers]
    assert_equal 16, PlanLimits::STARTUP_LIMITS[:filaments]
    assert_equal Float::INFINITY, PlanLimits::STARTUP_LIMITS[:invoices]
  end

  test "PRO_LIMITS should be unlimited" do
    assert_equal Float::INFINITY, PlanLimits::PRO_LIMITS[:print_pricings]
    assert_equal Float::INFINITY, PlanLimits::PRO_LIMITS[:printers]
    assert_equal Float::INFINITY, PlanLimits::PRO_LIMITS[:filaments]
    assert_equal Float::INFINITY, PlanLimits::PRO_LIMITS[:invoices]
  end

  test "limits_for should return FREE_LIMITS for free user" do
    @user.update!(plan: "free")
    limits = PlanLimits.limits_for(@user)

    assert_equal PlanLimits::FREE_LIMITS, limits
  end

  test "limits_for should return STARTUP_LIMITS for startup user" do
    @user.update!(plan: "startup")
    limits = PlanLimits.limits_for(@user)

    assert_equal PlanLimits::STARTUP_LIMITS, limits
  end

  test "limits_for should return PRO_LIMITS for pro user" do
    @user.update!(plan: "pro")
    limits = PlanLimits.limits_for(@user)

    assert_equal PlanLimits::PRO_LIMITS, limits
  end

  test "limits_for should return STARTUP_LIMITS for user in trial period" do
    @user.update!(plan: "free", trial_ends_at: 10.days.from_now)
    limits = PlanLimits.limits_for(@user)

    assert_equal PlanLimits::STARTUP_LIMITS, limits
  end

  test "can_create? should return true when under limit" do
    @user.update!(plan: "free")
    @user.print_pricings.destroy_all  # Start fresh

    # Free plan has 5 print_pricings limit, create 3
    3.times do
      create_print_pricing(@user)
    end

    assert PlanLimits.can_create?(@user, "print_pricing")
  end

  test "can_create? should return false when at limit" do
    @user.update!(plan: "free")
    @user.print_pricings.destroy_all  # Start fresh

    # Free plan has 5 print_pricings limit, create 5
    5.times do
      create_print_pricing(@user)
    end

    assert_not PlanLimits.can_create?(@user, "print_pricing")
  end

  test "can_create? should always return true for unlimited resources" do
    @user.update!(plan: "pro")

    # Create many resources
    100.times do
      create_print_pricing(@user)
    end

    assert PlanLimits.can_create?(@user, "print_pricing")
  end

  test "limit_for should return correct limit for resource type" do
    @user.update!(plan: "free")

    assert_equal 5, PlanLimits.limit_for(@user, "print_pricing")
    assert_equal 1, PlanLimits.limit_for(@user, "printer")
    assert_equal 4, PlanLimits.limit_for(@user, "filament")
    assert_equal 5, PlanLimits.limit_for(@user, "invoice")
  end

  test "current_usage should return correct count for monthly resources" do
    @user.update!(plan: "free")
    @user.print_pricings.destroy_all  # Start fresh

    3.times { create_print_pricing(@user) }

    assert_equal 3, PlanLimits.current_usage(@user, "print_pricing")
  end

  test "current_usage should return total count for non-monthly resources" do
    @user.update!(plan: "free")
    @user.printers.destroy_all  # Start fresh

    # Create actual printer records with all required fields
    @user.printers.create!(name: "Printer 1", power_consumption: 200, cost: 500, payoff_goal_years: 3, daily_usage_hours: 8)
    @user.printers.create!(name: "Printer 2", power_consumption: 150, cost: 400, payoff_goal_years: 2, daily_usage_hours: 8)

    assert_equal 2, PlanLimits.current_usage(@user, "printer")
  end

  test "remaining should return correct remaining count" do
    @user.update!(plan: "free")
    @user.print_pricings.destroy_all  # Start fresh

    2.times { create_print_pricing(@user) }

    # Free plan has 5 limit, used 2, should have 3 remaining
    assert_equal 3, PlanLimits.remaining(@user, "print_pricing")
  end

  test "remaining should return Float::INFINITY for unlimited resources" do
    @user.update!(plan: "pro")

    assert_equal Float::INFINITY, PlanLimits.remaining(@user, "print_pricing")
  end

  test "limit_reached? should return true when at limit" do
    @user.update!(plan: "free")
    @user.print_pricings.destroy_all  # Start fresh

    5.times { create_print_pricing(@user) }

    assert PlanLimits.limit_reached?(@user, "print_pricing")
  end

  test "limit_reached? should return false when under limit" do
    @user.update!(plan: "free")
    @user.print_pricings.destroy_all  # Start fresh

    2.times { create_print_pricing(@user) }

    assert_not PlanLimits.limit_reached?(@user, "print_pricing")
  end

  test "usage_percentage should return correct percentage" do
    @user.update!(plan: "free")
    @user.print_pricings.destroy_all  # Start fresh

    2.times { create_print_pricing(@user) }

    # 2 out of 5 = 40%
    assert_equal 40, PlanLimits.usage_percentage(@user, "print_pricing")
  end

  test "usage_percentage should return 0 for unlimited resources" do
    @user.update!(plan: "pro")

    10.times { create_print_pricing(@user) }

    assert_equal 0, PlanLimits.usage_percentage(@user, "print_pricing")
  end

  test "approaching_limit? should return true at 80% usage" do
    @user.update!(plan: "free")
    @user.print_pricings.destroy_all  # Start fresh

    4.times { create_print_pricing(@user) }

    # 4 out of 5 = 80%
    assert PlanLimits.approaching_limit?(@user, "print_pricing")
  end

  test "approaching_limit? should return false below 80% usage" do
    @user.update!(plan: "free")
    @user.print_pricings.destroy_all  # Start fresh

    3.times { create_print_pricing(@user) }

    # 3 out of 5 = 60%
    assert_not PlanLimits.approaching_limit?(@user, "print_pricing")
  end

  test "approaching_limit? should return false for unlimited resources" do
    @user.update!(plan: "pro")

    100.times { create_print_pricing(@user) }

    assert_not PlanLimits.approaching_limit?(@user, "print_pricing")
  end

  test "features_for should return correct features for free plan" do
    features = PlanLimits.features_for("free")

    assert_equal "Free", features[:name]
    assert_equal "$0", features[:price]
    assert_equal PlanLimits::FREE_LIMITS, features[:limits]
    assert features[:trial]
    assert_instance_of Array, features[:features]
  end

  test "features_for should return correct features for startup plan" do
    features = PlanLimits.features_for("startup")

    assert_equal "Startup", features[:name]
    assert_equal "$1.50/month", features[:price]
    assert_equal PlanLimits::STARTUP_LIMITS, features[:limits]
    assert_not features[:trial]
  end

  test "features_for should return correct features for pro plan" do
    features = PlanLimits.features_for("pro")

    assert_equal "Pro", features[:name]
    assert_equal "$15/month", features[:price]
    assert_equal PlanLimits::PRO_LIMITS, features[:limits]
    assert_not features[:trial]
  end
end
