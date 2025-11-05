class AddSubscriptionFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :plan, :string, default: 'free', null: false
    add_column :users, :plan_expires_at, :datetime
    add_column :users, :trial_ends_at, :datetime
    add_column :users, :stripe_customer_id, :string
    add_column :users, :stripe_subscription_id, :string

    add_index :users, :plan
    add_index :users, :stripe_customer_id, unique: true, where: "stripe_customer_id IS NOT NULL"
    add_index :users, :stripe_subscription_id, unique: true, where: "stripe_subscription_id IS NOT NULL"
  end
end
