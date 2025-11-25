class Article < ApplicationRecord
  # Mobility translations for title, slug, excerpt, and meta fields
  extend Mobility
  translates :title, backend: :table
  translates :slug, backend: :table
  translates :excerpt, backend: :table
  translates :meta_description, backend: :table
  translates :meta_keywords, backend: :table
  translates :translation_notice, backend: :table

  # Action Text for rich content (also translated)
  has_rich_text :content

  # Validations
  validates :author, presence: true
  validates :title, presence: true
  validates :slug, presence: true
  validate :slug_uniqueness_per_locale

  # Callbacks
  before_validation :generate_slug, if: -> { title.present? && slug.blank? }

  # Scopes
  scope :published, -> { where.not(published_at: nil).where("published_at <= ?", Time.current) }
  scope :featured, -> { where(featured: true) }
  scope :recent, -> { order(published_at: :desc) }
  scope :by_locale, ->(locale) { i18n.locale(locale) }

  # Check if article is published
  def published?
    published_at.present? && published_at <= Time.current
  end

  # Publish the article
  def publish!
    update!(published_at: Time.current)
  end

  # Unpublish the article
  def unpublish!
    update!(published_at: nil)
  end

  # Get reading time estimate in minutes
  def reading_time
    return 0 unless content.body.present?

    words = content.body.to_plain_text.split.size
    (words / 200.0).ceil # Assuming 200 words per minute
  end

  # Cache key for fragment caching
  def cache_key_with_locale
    [cache_key_with_version, I18n.locale].join("/")
  end

  private

  # Generate URL-friendly slug from title
  def generate_slug
    self.slug = title.parameterize
  end

  # Custom validation for slug uniqueness per locale
  def slug_uniqueness_per_locale
    return unless slug.present?

    # Check if another article has this slug in the current locale
    existing = Article.i18n.where(slug: slug).where.not(id: id).exists?
    errors.add(:slug, "has already been taken") if existing
  end
end
