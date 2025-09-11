class CreatePrinters < ActiveRecord::Migration[8.0]
  def change
    create_table :printers do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :manufacturer
      t.decimal :power_consumption, precision: 8, scale: 2
      t.decimal :cost, precision: 10, scale: 2
      t.integer :payoff_goal_years
      t.datetime :date_added, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end
  end
end
