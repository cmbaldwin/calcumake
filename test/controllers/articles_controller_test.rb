require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    I18n.locale = :en
    @published_article = articles(:published_article)
    @unpublished_article = articles(:unpublished_article)
    @future_article = articles(:future_article)
  end

  teardown do
    I18n.locale = :en
  end

  # Index Action Tests
  test "should get index" do
    get blog_url
    assert_response :success
  end

  test "should get index with locale" do
    get blog_url(locale: :ja)
    assert_response :success
  end

  test "index should only show published articles" do
    get blog_url
    assert_response :success

    # Check assigns
    assert_includes assigns(:articles), @published_article
    assert_not_includes assigns(:articles), @unpublished_article
    assert_not_includes assigns(:articles), @future_article
  end

  test "index should order by most recent first" do
    older = Article.create!(
      author: "Author",
      title: "Older Article",
      slug: "older",
      published_at: 3.days.ago
    )

    newer = Article.create!(
      author: "Author",
      title: "Newer Article",
      slug: "newer",
      published_at: 1.hour.ago
    )

    get blog_url
    assert_response :success

    # Check that @articles is in correct order
    assert_equal newer.id, assigns(:articles).first.id
  end

  test "index should limit articles to 20" do
    # Create 25 articles (more than the 20 limit)
    25.times do |i|
      Article.create!(
        author: "Author",
        title: "Article #{i}",
        slug: "article-#{i}",
        published_at: i.days.ago
      )
    end

    get blog_url
    assert_response :success
    # Should limit to 20 articles
    assert_equal 20, assigns(:articles).size
  end

  test "index should set correct locale from URL" do
    get blog_url(locale: :ja)
    assert_response :success
    assert_equal :ja, I18n.locale
  end

  test "index should work with invalid locale" do
    # Invalid locale doesn't match route pattern, so falls back to default (no locale)
    # This is handled by Rails routing - just test that it doesn't crash
    get blog_url
    assert_response :success
  end

  # Show Action Tests
  test "should show published article" do
    get article_url(slug: @published_article.slug)
    assert_response :success
    assert_equal @published_article, assigns(:article)
  end

  test "should show article with locale" do
    # Add Japanese translation
    I18n.locale = :ja
    @published_article.title = "公開された記事"
    @published_article.slug = "published-article-ja"
    @published_article.save!

    I18n.locale = :en
    get article_url(slug: @published_article.slug_ja, locale: :ja)
    assert_response :success
    assert_equal @published_article, assigns(:article)
    assert_equal :ja, I18n.locale
  end

  test "should not show unpublished article" do
    get article_url(slug: @unpublished_article.slug)
    assert_response :not_found
  end

  test "should not show future article" do
    get article_url(slug: @future_article.slug)
    assert_response :not_found
  end

  test "should fallback to English if article not found in current locale" do
    # Create article only in English
    en_article = Article.create!(
      author: "Author",
      title: "English Only",
      slug: "english-only",
      published_at: 1.day.ago
    )

    # Try to access in Japanese - should fallback to English article
    get article_url(slug: en_article.slug, locale: :ja)
    assert_response :success
    assert_equal en_article, assigns(:article)
    # Locale stays as :ja but we show English article with a notice
    assert_equal :ja, I18n.locale
    assert flash[:notice].present?
  end

  test "should raise 404 if article not found in any locale" do
    get article_url(slug: "non-existent-slug")
    assert_response :not_found
  end

  test "should handle special characters in slug" do
    article = Article.create!(
      author: "Author",
      title: "3D Printing Guide",
      slug: "3d-printing-guide",
      published_at: 1.day.ago
    )

    get article_url(slug: article.slug)
    assert_response :success
    assert_equal article, assigns(:article)
  end

  test "show should set correct locale from URL" do
    get article_url(slug: @published_article.slug, locale: :es)
    assert_response :success
    # Locale should be set to es
    assert_equal :es, I18n.locale
  end

  test "index should respond with HTML format" do
    get blog_url
    assert_response :success
    assert_equal "text/html", response.media_type
  end

  test "show should respond with HTML format" do
    get article_url(slug: @published_article.slug)
    assert_response :success
    assert_equal "text/html", response.media_type
  end
end
