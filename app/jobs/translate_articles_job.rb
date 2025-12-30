# frozen_string_literal: true

# Automatically translates published articles that are missing translations
# Runs periodically to ensure all articles are available in all supported locales
class TranslateArticlesJob < ApplicationJob
  queue_as :default

  TARGET_LOCALES = %w[ja es fr ar hi zh-CN].freeze

  LANGUAGE_NAMES = {
    "ja" => "Japanese",
    "es" => "Spanish",
    "fr" => "French",
    "ar" => "Arabic",
    "hi" => "Hindi",
    "zh-CN" => "Simplified Chinese"
  }.freeze

  def perform
    api_key = ENV["OPENROUTER_TRANSLATION_KEY"]
    unless api_key
      Rails.logger.info "[ArticleTranslation] Skipping - OPENROUTER_TRANSLATION_KEY not configured"
      return
    end

    setup_openrouter_client(api_key)
    client = OpenRouter::Client.new

    articles_to_translate = find_articles_needing_translation

    if articles_to_translate.empty?
      Rails.logger.info "[ArticleTranslation] No articles need translation"
      return
    end

    Rails.logger.info "[ArticleTranslation] Found #{articles_to_translate.size} articles needing translation"

    articles_to_translate.each do |article|
      translate_article(article, client)
    end

    Rails.logger.info "[ArticleTranslation] Translation complete"
  end

  private

  def setup_openrouter_client(api_key)
    OpenRouter.configure do |config|
      config.access_token = api_key
      config.site_name = "CalcuMake Article Translation"
      config.site_url = "https://calcumake.com"
    end
  end

  def find_articles_needing_translation
    Article.published.select do |article|
      TARGET_LOCALES.any? do |locale|
        # Check if translation actually exists in the translations table
        # Mobility returns the fallback value, so we need to check the backend directly
        title_translation = article.title_backend.read(locale, fallback: false)

        # For Action Text content, check if it exists in the target locale
        content_exists = I18n.with_locale(locale) do
          article.content.body.present? && article.content.body.to_s != article.content(:en).body.to_s
        end

        title_translation.blank? || !content_exists
      end
    end
  end

  def translate_article(article, client)
    Rails.logger.info "[ArticleTranslation] Translating article ##{article.id}: #{article.title_en}"

    TARGET_LOCALES.each do |locale|
      translate_article_to_locale(article, locale, client)
    end
  rescue StandardError => e
    Rails.logger.error "[ArticleTranslation] Error translating article ##{article.id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  def translate_article_to_locale(article, locale, client)
    I18n.with_locale(locale) do
      # Check if translation already exists using the backend directly
      title_translation = article.title_backend.read(locale, fallback: false)

      if title_translation.present?
        Rails.logger.info "[ArticleTranslation] Article ##{article.id} already has #{LANGUAGE_NAMES[locale]} translation"
        return
      end

      Rails.logger.info "[ArticleTranslation] Translating article ##{article.id} to #{LANGUAGE_NAMES[locale]}"

      # Translate title
      title_translation = translate_text(article.title_en, locale, client)
      article.title = title_translation if title_translation

      # Auto-generate slug from translated title
      article.slug = article.title.parameterize if article.title.present?

      # Translate excerpt if present in English
      if article.excerpt_en.present?
        excerpt_translation = translate_text(article.excerpt_en, locale, client)
        article.excerpt = excerpt_translation if excerpt_translation
      end

      # Translate Action Text content
      english_content_html = nil
      I18n.with_locale(:en) do
        english_content_html = article.content.body.to_html if article.content.body.present?
      end

      if english_content_html.present?
        content_translation = translate_text(english_content_html, locale, client, is_html: true)
        article.content = content_translation if content_translation
      end

      # Save the article with translations
      if article.save
        Rails.logger.info "[ArticleTranslation] Successfully translated article ##{article.id} to #{LANGUAGE_NAMES[locale]}"
      else
        Rails.logger.error "[ArticleTranslation] Failed to save article ##{article.id}: #{article.errors.full_messages.join(', ')}"
      end
    end
  rescue StandardError => e
    Rails.logger.error "[ArticleTranslation] Error translating to #{locale}: #{e.message}"
  end

  def translate_text(text, target_language, client, is_html: false)
    return nil if text.blank?

    content_type = is_html ? "HTML content" : "text"

    prompt = <<~PROMPT
      You are a professional translator for a 3D printing management blog called CalcuMake.

      Translate the following English #{content_type} to #{LANGUAGE_NAMES[target_language]}.

      CRITICAL RULES:
      1. Preserve all HTML tags EXACTLY as shown if present
      2. Preserve all attributes in HTML tags (class, id, data-*, etc.)
      3. ONLY translate the text content, NOT the HTML structure
      4. Keep technical 3D printing terms accurate
      5. Use natural, professional blog language
      6. Maintain the same tone and style
      7. Return ONLY the translated #{content_type}, nothing else

      Original #{content_type}:
      #{text}

      Translate to #{LANGUAGE_NAMES[target_language]}:
    PROMPT

    response = client.complete(
      [
        {
          role: "user",
          content: prompt
        }
      ],
      model: "google/gemini-2.0-flash-001",
      extras: {
        temperature: 0.3,
        max_tokens: 8000
      }
    )

    content = response.dig("choices", 0, "message", "content")

    unless content
      Rails.logger.error "[ArticleTranslation] No content in API response"
      return nil
    end

    # Clean up markdown code blocks if present
    content = content.gsub(/```(?:html)?\s*(.*?)\s*```/m, '\1')
    content.strip
  rescue StandardError => e
    Rails.logger.error "[ArticleTranslation] Translation error: #{e.message}"
    nil
  end
end
