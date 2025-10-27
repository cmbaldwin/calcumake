class AddLaborDefaultsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :default_prep_time_minutes, :integer, default: 10
    add_column :users, :default_prep_cost_per_hour, :decimal, precision: 10, scale: 2, default: 1000.0
    add_column :users, :default_postprocessing_time_minutes, :integer, default: 10
    add_column :users, :default_postprocessing_cost_per_hour, :decimal, precision: 10, scale: 2, default: 1000.0
    add_column :users, :default_other_costs, :decimal, precision: 10, scale: 2, default: 450.0
    add_column :users, :default_vat_percentage, :decimal, precision: 5, scale: 2, default: 20.0
  end
end
