class CreateFilaments < ActiveRecord::Migration[8.0]
  def change
    create_table :filaments do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :brand
      t.string :material_type, null: false
      t.decimal :diameter, precision: 4, scale: 2, default: 1.75
      t.decimal :density, precision: 4, scale: 2
      t.integer :print_temperature_min
      t.integer :print_temperature_max
      t.integer :heated_bed_temperature
      t.integer :print_speed_max
      t.string :color
      t.string :finish
      t.decimal :spool_weight, precision: 8, scale: 2
      t.decimal :spool_price, precision: 10, scale: 2
      t.integer :storage_temperature_max
      t.boolean :moisture_sensitive, default: false
      t.boolean :food_safe, default: false
      t.boolean :recyclable, default: false
      t.text :notes

      t.timestamps
    end

    add_index :filaments, [ :user_id, :name ], unique: true
    add_index :filaments, :material_type
  end
end
