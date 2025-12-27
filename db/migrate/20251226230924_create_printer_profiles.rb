class CreatePrinterProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :printer_profiles do |t|
      t.string :manufacturer, null: false
      t.string :model, null: false
      t.string :category
      t.string :technology, null: false, default: "fdm"
      t.integer :power_consumption_peak_watts
      t.integer :power_consumption_avg_watts
      t.decimal :cost_usd, precision: 10, scale: 2
      t.text :source
      t.boolean :verified, default: false
      t.datetime :last_verified_at

      t.timestamps
    end

    add_index :printer_profiles, [ :manufacturer, :model ], unique: true
    add_index :printer_profiles, :technology
    add_index :printer_profiles, :category
  end
end
