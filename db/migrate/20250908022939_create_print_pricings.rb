class CreatePrintPricings < ActiveRecord::Migration[8.0]
  def change
    create_table :print_pricings do |t|
      t.references :user, null: false, foreign_key: true
      t.string :job_name
      t.string :currency
      t.integer :printing_time_hours
      t.integer :printing_time_minutes
      t.decimal :filament_weight
      t.string :filament_type
      t.decimal :spool_price
      t.decimal :spool_weight
      t.decimal :markup_percentage
      t.decimal :power_consumption
      t.decimal :energy_cost_per_kwh
      t.integer :prep_time_minutes
      t.decimal :prep_cost_per_hour
      t.integer :postprocessing_time_minutes
      t.decimal :postprocessing_cost_per_hour
      t.decimal :printer_cost
      t.integer :investment_return_years
      t.integer :daily_usage_hours
      t.decimal :repair_cost_percentage
      t.decimal :other_costs
      t.decimal :vat_percentage
      t.decimal :final_price

      t.timestamps
    end
  end
end
