class CreateResins < ActiveRecord::Migration[8.1]
  def change
    create_table :resins do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :brand
      t.string :resin_type, null: false
      t.decimal :bottle_volume_ml, precision: 10, scale: 2
      t.decimal :bottle_price, precision: 10, scale: 2
      t.string :color
      t.integer :cure_time_seconds
      t.decimal :layer_height_min, precision: 4, scale: 3
      t.decimal :layer_height_max, precision: 4, scale: 3
      t.integer :exposure_time_seconds
      t.boolean :needs_wash, default: true
      t.text :notes

      t.timestamps
    end

    add_index :resins, [ :user_id, :name ], unique: true
  end
end
