class CreatePlates < ActiveRecord::Migration[8.0]
  def change
    create_table :plates do |t|
      t.references :print_pricing, null: false, foreign_key: true
      t.integer :printing_time_hours
      t.integer :printing_time_minutes
      t.decimal :filament_weight
      t.string :filament_type
      t.decimal :spool_price
      t.decimal :spool_weight
      t.decimal :markup_percentage

      t.timestamps
    end
  end
end
