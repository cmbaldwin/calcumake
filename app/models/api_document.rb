# frozen_string_literal: true

# API documentation model with automatic markdown generation for AI ingestion
class ApiDocument < ApplicationRecord
  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :version, presence: true
  validates :content, presence: true

  scope :published, -> { where(published: true) }
  scope :by_version, ->(version) { where(version: version) }
  scope :by_category, ->(category) { where(category: category) }
  scope :ordered, -> { order(:position, :title) }

  before_validation :generate_slug, if: :title_changed?
  after_commit :enqueue_markdown_generation, if: :should_generate_markdown?

  # Generate markdown file asynchronously
  def enqueue_markdown_generation
    ApiDocumentMarkdownGeneratorJob.perform_later(id)
  end

  # Public URL for the API document
  def public_url
    Rails.application.routes.url_helpers.api_document_url(version, slug)
  end

  # Markdown URL
  def markdown_url
    Rails.application.routes.url_helpers.api_document_url(version, slug, format: :md)
  end

  # Check if markdown needs regeneration
  def markdown_stale?
    markdown_path.blank? || !File.exist?(markdown_file_path) || updated_at > File.mtime(markdown_file_path)
  end

  # Full path to markdown file
  def markdown_file_path
    return nil if markdown_path.blank?
    Rails.root.join("public", "markdown", "api", markdown_path)
  end

  private

  def generate_slug
    return if title.blank?
    self.slug = title.parameterize
  end

  def should_generate_markdown?
    published? && (saved_change_to_title? || saved_change_to_content? || saved_change_to_published?)
  end
end
