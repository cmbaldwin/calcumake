class CreateUsageTrackings < ActiveRecord::Migration[8.0]
  def change
    create_table :usage_trackings do |t|
      t.references :user, null: false, foreign_key: true
      t.string :resource_type, null: false
      t.integer :count, default: 0, null: false
      t.date :period_start, null: false

      t.timestamps
    end

    # Ensure one tracking record per user, resource type, and period
    add_index :usage_trackings, [:user_id, :resource_type, :period_start],
              unique: true,
              name: 'index_usage_trackings_unique'
    add_index :usage_trackings, :period_start
  end
end
