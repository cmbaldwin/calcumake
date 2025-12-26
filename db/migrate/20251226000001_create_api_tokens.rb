# frozen_string_literal: true

class CreateApiTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :api_tokens do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.string :token_digest, null: false
      t.string :token_hint, null: false
      t.datetime :last_used_at
      t.datetime :expires_at
      t.datetime :revoked_at
      t.inet :created_from_ip
      t.string :user_agent
      t.timestamps
    end

    add_index :api_tokens, :token_digest, unique: true
    add_index :api_tokens, %i[user_id created_at]
    add_index :api_tokens, :expires_at, where: "expires_at IS NOT NULL"
  end
end
