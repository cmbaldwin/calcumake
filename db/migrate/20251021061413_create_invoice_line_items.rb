class CreateInvoiceLineItems < ActiveRecord::Migration[8.0]
  def change
    create_table :invoice_line_items do |t|
      t.references :invoice, null: false, foreign_key: true
      t.text :description, null: false
      t.decimal :quantity, precision: 10, scale: 2, null: false, default: 1.0
      t.decimal :unit_price, precision: 10, scale: 2, null: false, default: 0.0
      t.decimal :total_price, precision: 10, scale: 2, null: false, default: 0.0
      t.string :line_item_type, null: false, default: "custom"
      t.integer :order_position, null: false, default: 0

      t.timestamps
    end

    add_index :invoice_line_items, [ :invoice_id, :order_position ]
  end
end
