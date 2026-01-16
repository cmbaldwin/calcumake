# frozen_string_literal: true

class CreateBlogPosts < ActiveRecord::Migration[8.0]
  def change
    create_table :blog_posts do |t|
      t.string :title, null: false
      t.string :slug, null: false, index: { unique: true }
      t.text :content, null: false
      t.text :excerpt
      t.boolean :published, default: false, null: false
      t.datetime :published_at
      t.references :user, null: false, foreign_key: true
      t.string :markdown_path # Path to generated markdown file

      t.timestamps
    end

    add_index :blog_posts, :published
    add_index :blog_posts, :published_at
  end
end
