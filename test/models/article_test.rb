require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  setup do
    I18n.locale = :en
  end

  teardown do
    I18n.locale = :en
  end

  # Validations Tests
  test "should require author" do
    article = Article.new(title: "Test", slug: "test")
    assert_not article.valid?
    assert_includes article.errors[:author], "can't be blank"
  end

  test "should require title" do
    article = Article.new(author: "Test Author", slug: "test")
    assert_not article.valid?
    assert_includes article.errors[:title], "can't be blank"
  end

  test "should require slug" do
    article = Article.new(author: "Test Author", title: "")
    article.slug = ""
    assert_not article.valid?
    assert_includes article.errors[:slug], "can't be blank"
  end

  test "should enforce unique slug per locale" do
    article1 = Article.create!(
      author: "Author 1",
      title: "First Article",
      slug: "test-article"
    )

    article2 = Article.new(
      author: "Author 2",
      title: "Second Article",
      slug: "test-article"
    )

    assert_not article2.valid?
    assert_includes article2.errors[:slug], "has already been taken"
  end

  test "should allow same slug in different locales" do
    article1 = Article.create!(
      author: "Author 1",
      title: "English Article",
      slug: "same-slug"
    )

    I18n.locale = :ja
    article1.title = "日本語の記事"
    article1.slug = "same-slug"
    assert article1.save

    article2 = Article.new(
      author: "Author 2",
      title: "別の日本語記事",
      slug: "different-slug"
    )
    assert article2.valid?
  end

  # Auto-slug Generation Tests
  test "should auto-generate slug from title" do
    article = Article.new(
      author: "Test Author",
      title: "My Great Article Title"
    )
    article.valid?
    assert_equal "my-great-article-title", article.slug
  end

  test "should not overwrite existing slug" do
    article = Article.new(
      author: "Test Author",
      title: "New Title",
      slug: "custom-slug"
    )
    article.valid?
    assert_equal "custom-slug", article.slug
  end

  test "should handle special characters in title when generating slug" do
    article = Article.new(
      author: "Test Author",
      title: "3D Printing: The Ultimate Guide!"
    )
    article.valid?
    assert_equal "3d-printing-the-ultimate-guide", article.slug
  end

  # Translation Tests
  test "should translate title across locales" do
    article = Article.create!(
      author: "Test Author",
      title: "English Title"
    )

    I18n.locale = :ja
    article.title = "日本語タイトル"
    article.save!

    I18n.locale = :en
    assert_equal "English Title", article.title

    I18n.locale = :ja
    assert_equal "日本語タイトル", article.title
  end

  test "should use locale accessors" do
    article = Article.create!(
      author: "Test Author",
      title: "English Title"
    )

    article.title_ja = "日本語タイトル"
    article.title_es = "Título en Español"
    article.save!

    assert_equal "English Title", article.title_en
    assert_equal "日本語タイトル", article.title_ja
    assert_equal "Título en Español", article.title_es
  end

  test "should fallback to English when translation missing" do
    article = Article.create!(
      author: "Test Author",
      title: "English Title"
    )

    I18n.locale = :ja
    # Fallback configured in mobility.rb
    assert_equal "English Title", article.title
  end

  test "should translate excerpt" do
    article = Article.create!(
      author: "Test Author",
      title: "Test",
      excerpt: "English excerpt"
    )

    I18n.locale = :ja
    article.excerpt = "日本語の抜粋"
    article.save!

    I18n.locale = :en
    assert_equal "English excerpt", article.excerpt

    I18n.locale = :ja
    assert_equal "日本語の抜粋", article.excerpt
  end

  test "should translate meta fields" do
    article = Article.create!(
      author: "Test Author",
      title: "Test",
      meta_description: "English meta",
      meta_keywords: "english, keywords"
    )

    I18n.locale = :ja
    article.meta_description = "日本語メタ"
    article.meta_keywords = "日本語, キーワード"
    article.save!

    I18n.locale = :en
    assert_equal "English meta", article.meta_description
    assert_equal "english, keywords", article.meta_keywords

    I18n.locale = :ja
    assert_equal "日本語メタ", article.meta_description
    assert_equal "日本語, キーワード", article.meta_keywords
  end

  test "should handle translation_notice flag per locale" do
    article = Article.create!(
      author: "Test Author",
      title: "English Title"
    )

    assert_equal false, article.translation_notice

    I18n.locale = :ja
    article.title = "日本語タイトル"
    article.translation_notice = true
    article.save!

    I18n.locale = :en
    assert_equal false, article.translation_notice

    I18n.locale = :ja
    assert_equal true, article.translation_notice
  end

  # Scope Tests
  test "published scope should return only published articles" do
    published = Article.create!(
      author: "Author",
      title: "Published",
      published_at: 1.day.ago
    )

    unpublished = Article.create!(
      author: "Author",
      title: "Unpublished",
      published_at: nil
    )

    future = Article.create!(
      author: "Author",
      title: "Future",
      published_at: 1.day.from_now
    )

    published_articles = Article.published
    assert_includes published_articles, published
    assert_not_includes published_articles, unpublished
    assert_not_includes published_articles, future
  end

  test "featured scope should return only featured articles" do
    featured = Article.create!(
      author: "Author",
      title: "Featured",
      featured: true
    )

    not_featured = Article.create!(
      author: "Author",
      title: "Not Featured",
      featured: false
    )

    featured_articles = Article.featured
    assert_includes featured_articles, featured
    assert_not_includes featured_articles, not_featured
  end

  test "recent scope should order by published_at descending" do
    old_time = 3.days.ago
    recent_time = 1.day.ago

    old = Article.create!(
      author: "Author",
      title: "Old",
      published_at: old_time
    )

    recent = Article.create!(
      author: "Author",
      title: "Recent",
      published_at: recent_time
    )

    articles = Article.where(id: [ old.id, recent.id ]).recent.to_a
    assert_equal 2, articles.size
    # Most recent should be first
    assert_equal recent.id, articles.first.id
    assert_equal old.id, articles.last.id
  end

  # Published Status Tests
  test "published? should return true for published articles" do
    article = Article.create!(
      author: "Author",
      title: "Published",
      published_at: 1.day.ago
    )

    assert article.published?
  end

  test "published? should return false for unpublished articles" do
    article = Article.create!(
      author: "Author",
      title: "Unpublished",
      published_at: nil
    )

    assert_not article.published?
  end

  test "published? should return false for future articles" do
    article = Article.create!(
      author: "Author",
      title: "Future",
      published_at: 1.day.from_now
    )

    assert_not article.published?
  end

  test "publish! should set published_at to current time" do
    article = Article.create!(
      author: "Author",
      title: "Article"
    )

    assert_nil article.published_at

    freeze_time do
      article.publish!
      assert_equal Time.current, article.published_at
      assert article.published?
    end
  end

  test "unpublish! should set published_at to nil" do
    article = Article.create!(
      author: "Author",
      title: "Article",
      published_at: 1.day.ago
    )

    assert article.published?

    article.unpublish!
    assert_nil article.published_at
    assert_not article.published?
  end

  # Action Text Tests
  test "should have rich text content" do
    article = Article.create!(
      author: "Author",
      title: "Article"
    )

    article.content = "<h1>Rich Text Content</h1><p>This is a test.</p>"
    article.save!

    assert article.content.body.present?
    assert_includes article.content.to_plain_text, "Rich Text Content"
  end

  # Reading Time Tests
  test "reading_time should calculate correctly for 200 words" do
    article = Article.create!(
      author: "Author",
      title: "Article"
    )

    # Create exactly 200 words
    words = ([ "word" ] * 200).join(" ")
    article.content = "<p>#{words}</p>"
    article.save!

    assert_equal 1, article.reading_time
  end

  test "reading_time should calculate correctly for 450 words" do
    article = Article.create!(
      author: "Author",
      title: "Article"
    )

    # Create 450 words (should be 3 minutes)
    words = ([ "word" ] * 450).join(" ")
    article.content = "<p>#{words}</p>"
    article.save!

    assert_equal 3, article.reading_time
  end

  test "reading_time should return 0 for empty content" do
    article = Article.create!(
      author: "Author",
      title: "Article"
    )

    assert_equal 0, article.reading_time
  end

  # Cache Key Tests
  test "cache_key_with_locale should include locale" do
    article = Article.create!(
      author: "Author",
      title: "Article"
    )

    I18n.locale = :en
    en_key = article.cache_key_with_locale
    assert_includes en_key, "en"

    I18n.locale = :ja
    ja_key = article.cache_key_with_locale
    assert_includes ja_key, "ja"

    assert_not_equal en_key, ja_key
  end

  # Featured Default Tests
  test "featured should default to false" do
    article = Article.create!(
      author: "Author",
      title: "Article"
    )

    assert_equal false, article.featured
  end
end
