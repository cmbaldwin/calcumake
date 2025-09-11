user = User.first
unless user.printers.exists?
  user.printers.create!(
    name: 'Test Printer',
    manufacturer: 'Prusa',
    power_consumption: 200,
    cost: 500,
    payoff_goal_years: 3,
    daily_usage_hours: 8,
    repair_cost_percentage: 5.0
  )
  puts "Created test printer"
else
  puts "Printer already exists"
end