class CreateArticleTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :article_translations do |t|
      # Foreign key to articles table
      t.references :article, null: false, foreign_key: true, index: false

      # Locale for this translation
      t.string :locale, null: false

      # Translated string fields
      t.string :title
      t.string :slug
      t.string :meta_description
      t.string :meta_keywords

      # Translated text fields
      t.text :excerpt

      # Flag for auto-translated content
      t.boolean :translation_notice, default: false, null: false

      t.timestamps
    end

    # Composite index for lookups by article and locale
    add_index :article_translations, [ :article_id, :locale ], unique: true

    # Index for slug lookups (URL routing)
    add_index :article_translations, [ :locale, :slug ], unique: true
  end
end
