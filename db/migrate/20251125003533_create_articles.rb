class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string :author
      t.datetime :published_at
      t.boolean :featured, default: false, null: false

      t.timestamps
    end

    # Performance indexes
    add_index :articles, :published_at
    add_index :articles, :featured
    add_index :articles, [ :featured, :published_at ]
  end
end
