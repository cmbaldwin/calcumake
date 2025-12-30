require "test_helper"

class SitemapTest < ActiveSupport::TestCase
  def setup
    # Clear any existing sitemap files
    FileUtils.rm_f(Rails.root.join("public", "sitemap*.xml"))

    # Create test articles with translations
    @english_article = Article.create!(
      title: "Test Article for Sitemap",
      slug: "test-sitemap-article",
      excerpt: "Testing sitemap generation",
      author: "Test Author",
      published_at: 1.day.ago
    )
    @english_article.content = "<p>Test content</p>"
    @english_article.save!

    # Add a Japanese translation
    I18n.with_locale(:ja) do
      @english_article.title = "サイトマップテスト記事"
      @english_article.slug = "test-sitemap-article-ja"
      @english_article.save!
    end
  end

  def teardown
    @english_article.destroy if @english_article.persisted?
    FileUtils.rm_f(Rails.root.join("public", "sitemap*.xml"))
  end

  test "sitemap generation succeeds" do
    # Generate sitemap
    require "sitemap_generator"
    assert_nothing_raised do
      SitemapGenerator::Sitemap.default_host = "https://calcumake.com"
      SitemapGenerator::Sitemap.create do
        add root_path, priority: 1.0, changefreq: "weekly"
      end
    end

    # Verify sitemap files were created
    assert File.exist?(Rails.root.join("public", "sitemap.xml")),
           "sitemap.xml should be created"
  end

  test "sitemap includes required static pages" do
    # Generate full sitemap
    silence_stream($stdout) do
      system("cd #{Rails.root} && bin/rails sitemap:refresh:no_ping")
    end

    sitemap_content = File.read(Rails.root.join("public", "sitemap.xml"))

    # Check for required pages
    assert_includes sitemap_content, "https://calcumake.com/3d-print-pricing-calculator",
                    "Sitemap should include pricing calculator"
    assert_includes sitemap_content, "https://calcumake.com/blog",
                    "Sitemap should include blog"
    assert_includes sitemap_content, "https://calcumake.com/support",
                    "Sitemap should include support page"
  end

  test "sitemap does not have duplicate root URLs" do
    # Generate sitemap
    silence_stream($stdout) do
      system("cd #{Rails.root} && bin/rails sitemap:refresh:no_ping")
    end

    sitemap_content = File.read(Rails.root.join("public", "sitemap.xml"))

    # Extract all URLs
    urls = sitemap_content.scan(%r{<loc>(.*?)</loc>}).flatten

    # Count occurrences of root URL
    root_url_count = urls.count("https://calcumake.com")

    assert_equal 1, root_url_count,
                 "Root URL should appear exactly once, found #{root_url_count} times"
  end

  test "sitemap includes all blog locale pages" do
    silence_stream($stdout) do
      system("cd #{Rails.root} && bin/rails sitemap:refresh:no_ping")
    end

    sitemap_content = File.read(Rails.root.join("public", "sitemap.xml"))

    # Check for blog pages in different locales
    expected_blog_urls = [
      "https://calcumake.com/blog",      # English
      "https://calcumake.com/ja/blog",   # Japanese
      "https://calcumake.com/es/blog",   # Spanish
      "https://calcumake.com/fr/blog",   # French
      "https://calcumake.com/ar/blog",   # Arabic
      "https://calcumake.com/hi/blog",   # Hindi
      "https://calcumake.com/zh-CN/blog" # Chinese
    ]

    expected_blog_urls.each do |blog_url|
      assert_includes sitemap_content, blog_url,
                      "Sitemap should include #{blog_url}"
    end
  end

  test "sitemap includes published articles" do
    silence_stream($stdout) do
      system("cd #{Rails.root} && bin/rails sitemap:refresh:no_ping")
    end

    sitemap_content = File.read(Rails.root.join("public", "sitemap.xml"))

    # Check that at least one published article is included (fixtures create test articles)
    assert_match %r{/blog/[^<]+</loc>}, sitemap_content,
                 "Sitemap should include published articles"
  end

  test "sitemap does not include unpublished articles" do
    unpublished = Article.create!(
      title: "Unpublished Article",
      slug: "unpublished-sitemap-test",
      author: "Test",
      published_at: nil
    )

    silence_stream($stdout) do
      system("cd #{Rails.root} && bin/rails sitemap:refresh:no_ping")
    end

    sitemap_content = File.read(Rails.root.join("public", "sitemap.xml"))

    assert_not_includes sitemap_content, "/#{unpublished.slug}",
                        "Sitemap should not include unpublished articles"
  ensure
    unpublished.destroy if unpublished.persisted?
  end

  test "all sitemap URLs are unique" do
    silence_stream($stdout) do
      system("cd #{Rails.root} && bin/rails sitemap:refresh:no_ping")
    end

    sitemap_content = File.read(Rails.root.join("public", "sitemap.xml"))

    # Extract all URLs
    urls = sitemap_content.scan(%r{<loc>(.*?)</loc>}).flatten

    # Find duplicates
    duplicates = urls.group_by { |url| url }.select { |_, v| v.size > 1 }.keys

    assert_empty duplicates,
                 "Found duplicate URLs in sitemap: #{duplicates.join(', ')}"
  end

  test "sitemap does not include auth pages" do
    silence_stream($stdout) do
      system("cd #{Rails.root} && bin/rails sitemap:refresh:no_ping")
    end

    sitemap_content = File.read(Rails.root.join("public", "sitemap.xml"))

    # These should be blocked by robots.txt and not in sitemap
    assert_not_includes sitemap_content, "/sign_in",
                        "Sitemap should not include sign_in page"
    assert_not_includes sitemap_content, "/sign_up",
                        "Sitemap should not include sign_up page"
  end

  test "sitemap has valid XML structure" do
    silence_stream($stdout) do
      system("cd #{Rails.root} && bin/rails sitemap:refresh:no_ping")
    end

    sitemap_path = Rails.root.join("public", "sitemap.xml")

    # Use xmllint to validate if available, otherwise just check XML parsing
    if system("which xmllint > /dev/null 2>&1")
      assert system("xmllint --noout #{sitemap_path} 2>/dev/null"),
             "Sitemap XML should be valid"
    else
      # Fallback: just ensure it can be parsed
      assert_nothing_raised do
        require "rexml/document"
        REXML::Document.new(File.read(sitemap_path))
      end
    end
  end

  private

  def silence_stream(stream)
    old_stream = stream.dup
    stream.reopen(IO::NULL)
    stream.sync = true
    yield
  ensure
    stream.reopen(old_stream)
    old_stream.close
  end
end
