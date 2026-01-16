# frozen_string_literal: true

class CreateApiDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :api_documents do |t|
      t.string :title, null: false
      t.string :slug, null: false, index: { unique: true }
      t.string :version, null: false
      t.text :content, null: false
      t.text :description
      t.boolean :published, default: false, null: false
      t.integer :position, default: 0
      t.string :category
      t.string :markdown_path # Path to generated markdown file

      t.timestamps
    end

    add_index :api_documents, :published
    add_index :api_documents, :version
    add_index :api_documents, :category
    add_index :api_documents, :position
  end
end
