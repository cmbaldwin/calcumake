module ArticlesHelper
  # Generate structured data for an article (JSON-LD)
  def article_structured_data(article)
    data = {
      "@context": "https://schema.org",
      "@type": "BlogPosting",
      "headline": article.title,
      "author": {
        "@type": "Person",
        "name": article.author
      },
      "publisher": {
        "@type": "Organization",
        "name": t("articles.structured_data.organization")
      },
      "datePublished": article.published_at.iso8601,
      "dateModified": article.updated_at.iso8601,
      "description": article.excerpt.presence || article.title,
      "mainEntityOfPage": {
        "@type": "WebPage",
        "@id": article_url(slug: article.slug, locale: I18n.locale)
      },
      "inLanguage": I18n.locale.to_s
    }

    # Add word count if content exists
    if article.content.body.present?
      data["wordCount"] = article.content.body.to_plain_text.split.size
    end

    data.to_json.html_safe
  end

  # Generate meta description for article
  def article_meta_description(article)
    if article.meta_description.present?
      article.meta_description
    elsif article.excerpt.present?
      article.excerpt.truncate(160)
    elsif article.content.body.present?
      article.content.body.to_plain_text.truncate(160)
    else
      article.title
    end
  end

  # Generate meta keywords for article
  def article_meta_keywords(article)
    if article.meta_keywords.present?
      article.meta_keywords
    else
      t("articles.meta.keywords")
    end
  end

  # Format published date
  def article_published_date(article)
    l(article.published_at, format: :long)
  end

  # Show reading time if available
  def article_reading_time(article)
    return unless article.reading_time > 0

    t("articles.reading_time", count: article.reading_time)
  end

  # Check if article should show translation notice
  def show_translation_notice?(article)
    article.translation_notice == true && I18n.locale != :en
  end
end
