class ArticlesController < ApplicationController
  before_action :set_article, only: :show

  # GET /blog
  # GET /:locale/blog
  def index
    # Eager load rich_text content and translations to prevent N+1 queries
    # Simple pagination: limit to 20 most recent articles
    @articles = Article.published
      .includes(:rich_text_content, :translations)
      .recent
      .limit(20)
  end

  # GET /blog/:slug
  # GET /:locale/blog/:slug
  def show
    # Article already set in before_action with eager loading
  end

  private

  def set_article
    # Find article by slug in the current locale
    # First try to find by slug in current locale
    @article = Article.published
      .includes(:rich_text_content, :translations)
      .where("article_translations.slug = ? AND article_translations.locale = ?", params[:slug], I18n.locale.to_s)
      .joins(:translations)
      .first

    # If not found and not in English, try English as fallback
    if @article.nil? && I18n.locale != :en
      @article = Article.published
        .includes(:rich_text_content, :translations)
        .where("article_translations.slug = ? AND article_translations.locale = ?", params[:slug], "en")
        .joins(:translations)
        .first

      flash.now[:notice] = "This article is only available in English" if @article.present?
    end

    # Raise 404 if still not found
    raise ActiveRecord::RecordNotFound if @article.nil?
  end
end
