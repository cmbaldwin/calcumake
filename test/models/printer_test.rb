require "test_helper"

class PrinterTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @printer = Printer.new(
      user: @user,
      name: "Test Printer",
      manufacturer: "Prusa",
      power_consumption: 200.0,
      cost: 500.0,
      payoff_goal_years: 3
    )
  end

  test "should be valid with valid attributes" do
    assert @printer.valid?
  end

  test "should require name" do
    @printer.name = nil
    assert_not @printer.valid?
    assert_includes @printer.errors[:name], "can't be blank"
  end

  test "should require positive power consumption" do
    @printer.power_consumption = -1
    assert_not @printer.valid?
    assert_includes @printer.errors[:power_consumption], "must be greater than 0"
  end

  test "should require positive cost" do
    @printer.cost = -1
    assert_not @printer.valid?
    assert_includes @printer.errors[:cost], "must be greater than 0"
  end

  test "should require positive payoff goal years" do
    @printer.payoff_goal_years = 0
    assert_not @printer.valid?
    assert_includes @printer.errors[:payoff_goal_years], "must be greater than 0"
  end

  test "should set date_added automatically" do
    @printer.save!
    assert_not_nil @printer.date_added
  end

  test "paid_off? should return false for new printer" do
    @printer.save!
    assert_not @printer.paid_off?
  end

  test "paid_off? should return true for old printer past payoff goal" do
    @printer.date_added = 5.years.ago
    @printer.payoff_goal_years = 3
    @printer.save!
    assert @printer.paid_off?
  end

  test "months_to_payoff should return correct months remaining" do
    @printer.date_added = 1.year.ago
    @printer.payoff_goal_years = 3
    @printer.save!
    
    months_remaining = @printer.months_to_payoff
    # Should be approximately 24 months (2 years remaining)
    assert months_remaining > 20
    assert months_remaining < 26
  end

  test "months_to_payoff should return 0 for paid off printer" do
    @printer.date_added = 5.years.ago
    @printer.payoff_goal_years = 3
    @printer.save!
    assert_equal 0, @printer.months_to_payoff
  end

  test "should have valid manufacturer options" do
    valid_manufacturers = Printer::MANUFACTURERS
    assert_includes valid_manufacturers, 'Prusa'
    assert_includes valid_manufacturers, 'Bambu Lab'
    assert_includes valid_manufacturers, 'Creality'
    assert_includes valid_manufacturers, 'Other'
  end

  test "should belong to user" do
    assert_respond_to @printer, :user
    assert_equal @user, @printer.user
  end
end
