class AddDefaultSettingsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :default_currency, :string, default: 'USD'
    add_column :users, :default_energy_cost_per_kwh, :decimal, precision: 8, scale: 4, default: 0.12
  end
end
