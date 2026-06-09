class CreateOAuthAuthorizationCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :oauth_authorization_codes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :code, null: false
      t.string :code_challenge
      t.string :code_challenge_method, default: "S256"
      t.string :redirect_uri, null: false
      t.string :client_id, null: false
      t.string :scope, default: "mcp"
      t.string :state
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end

    add_index :oauth_authorization_codes, :code, unique: true
  end
end
