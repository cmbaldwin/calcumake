class CreateUserConsents < ActiveRecord::Migration[8.1]
  def change
    create_table :user_consents do |t|
      t.references :user, null: false, foreign_key: true
      t.string :consent_type, null: false
      t.boolean :accepted, null: false, default: false
      t.string :ip_address
      t.text :user_agent

      t.timestamps
    end

    add_index :user_consents, [ :user_id, :consent_type, :created_at ], name: "index_consents_on_user_type_date"
  end
end
