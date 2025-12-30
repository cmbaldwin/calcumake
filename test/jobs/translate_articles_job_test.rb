require "test_helper"

class TranslateArticlesJobTest < ActiveJob::TestCase
  def setup
    @job = TranslateArticlesJob.new
    @article = Article.create!(
      title: "Test Article for Translation",
      slug: "test-translation-job",
      excerpt: "Testing automated translation",
      author: "Test Author",
      published_at: 1.day.ago
    )
    @article.content = "<h2>Test Content</h2><p>This is test content for translation.</p>"
    @article.save!
  end

  def teardown
    @article.destroy if @article.persisted?
  end

  test "skips execution when API key is not set" do
    # Clear API key if set
    original_key = ENV["OPENROUTER_TRANSLATION_KEY"]
    ENV["OPENROUTER_TRANSLATION_KEY"] = nil

    # Should exit early without errors
    assert_nothing_raised do
      @job.perform
    end
  ensure
    ENV["OPENROUTER_TRANSLATION_KEY"] = original_key
  end

  test "finds articles needing translation" do
    articles_needing_translation = Article.published.select do |article|
      TranslateArticlesJob::TARGET_LOCALES.any? do |locale|
        title_translation = article.title_backend.read(locale, fallback: false)
        title_translation.blank?
      end
    end

    assert_includes articles_needing_translation, @article
  end

  test "detects missing translations correctly" do
    # Article should need translations in all target locales
    TranslateArticlesJob::TARGET_LOCALES.each do |locale|
      title_trans = @article.title_backend.read(locale, fallback: false)
      assert_nil title_trans, "Expected no translation for #{locale}, but found: #{title_trans}"
    end
  end

  test "skips unpublished articles" do
    unpublished = Article.create!(
      title: "Unpublished Article",
      slug: "unpublished-test",
      author: "Test",
      published_at: nil
    )

    articles_needing_translation = Article.published.select do |article|
      TranslateArticlesJob::TARGET_LOCALES.any? do |locale|
        title_translation = article.title_backend.read(locale, fallback: false)
        title_translation.blank?
      end
    end

    assert_not_includes articles_needing_translation, unpublished
  ensure
    unpublished.destroy if unpublished.persisted?
  end

  test "language names are defined for all target locales" do
    TranslateArticlesJob::TARGET_LOCALES.each do |locale|
      assert_includes TranslateArticlesJob::LANGUAGE_NAMES.keys, locale,
                      "Missing language name for locale: #{locale}"
    end
  end

  test "translate_text returns nil for blank input" do
    result = @job.send(:translate_text, "", "ja", nil)
    assert_nil result

    result = @job.send(:translate_text, nil, "ja", nil)
    assert_nil result
  end

  test "skips translation when article already has translation" do
    # Add a Japanese translation
    I18n.with_locale(:ja) do
      @article.title = "テスト記事"
      @article.slug = "test-article"
      @article.save!
    end

    # Verify the translation exists
    ja_title = @article.title_backend.read(:ja, fallback: false)
    assert_equal "テスト記事", ja_title

    # Article should not need Japanese translation anymore
    needs_ja_translation = @article.title_backend.read(:ja, fallback: false).blank?
    assert_not needs_ja_translation, "Article should already have Japanese translation"
  end
end
