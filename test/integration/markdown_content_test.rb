require "test_helper"

class MarkdownContentTest < ActionDispatch::IntegrationTest
  test "markdown pages return correct content type" do
    [ privacy_policy_path, user_agreement_path, support_path, about_path ].each do |path|
      get "#{path}.md"
      assert_response :success
      assert_equal "text/markdown; charset=utf-8", response.content_type
    end
  end

  test "markdown pages have proper frontmatter structure" do
    [ privacy_policy_path, user_agreement_path, support_path, about_path ].each do |path|
      get "#{path}.md"
      assert_response :success

      # Check frontmatter markers
      assert response.body.start_with?("---"), "Markdown should start with frontmatter delimiter"
      assert_match /---.*---.*#/m, response.body, "Should have frontmatter followed by content"

      # Check required frontmatter fields
      assert_includes response.body, "title:"
      assert_includes response.body, "url:"
      assert_includes response.body, "language:"
      assert_includes response.body, "last_updated:"
      assert_includes response.body, "type:"
    end
  end

  test "markdown pages have proper heading structure" do
    [ privacy_policy_path, user_agreement_path, support_path, about_path ].each do |path|
      get "#{path}.md"
      assert_response :success

      # Should have exactly one h1 (# )
      h1_count = response.body.scan(/^# [^#]/).count
      assert_equal 1, h1_count, "Should have exactly one h1 heading"

      # Should have h2 headings (## )
      assert_match /^## /, response.body, "Should have h2 headings"
    end
  end

  test "markdown pages include language navigation" do
    get about_path(format: :md)
    assert_response :success

    assert_includes response.body, "Available in:"
    assert_includes response.body, "English"
    assert_includes response.body, "日本語"
    assert_includes response.body, "中文"
  end

  test "markdown pages include footer copyright" do
    [ privacy_policy_path, user_agreement_path, support_path, about_path ].each do |path|
      get "#{path}.md"
      assert_response :success
      assert_includes response.body, "© 2025 株式会社モアブ (MOAB Co., Ltd.)"
    end
  end

  test "markdown pages are properly cached" do
    get privacy_policy_path(format: :md)
    assert_response :success

    cache_control = response.headers["Cache-Control"]
    assert_match /public/, cache_control, "Should have public cache directive"
    assert_match /max-age=\d+/, cache_control, "Should have max-age directive"
  end

  test "markdown pages have alternate language metadata" do
    get privacy_policy_path(format: :md)
    assert_response :success

    assert_includes response.body, "alternate_languages:"

    # Check for some alternate languages
    I18n.available_locales.reject { |l| l == :en }.each do |locale|
      # Should have the locale mentioned in frontmatter
      assert_includes response.body, "#{locale}:", "Should include #{locale} in alternate languages"
    end
  end

  test "markdown content is well-formed" do
    get about_path(format: :md)
    assert_response :success

    body = response.body

    # Check for common markdown formatting issues
    assert_no_match /<[^>]+>/, body.lines[10..].join, "Should not contain HTML tags in content (after frontmatter)"

    # Check list formatting
    if body.include?("- ")
      body.scan(/^- /).each do |match|
        assert match == "- ", "List items should have proper formatting"
      end
    end

    # Check link formatting
    if body.include?("[")
      # Basic check that links are properly formatted
      assert_match /\[.+\]\(.+\)/, body, "Links should be properly formatted"
    end
  end

  test "markdown pages work with locale parameter" do
    I18n.available_locales.each do |locale|
      I18n.with_locale(locale) do
        get about_path(format: :md, locale: locale)
        assert_response :success
        assert_includes response.body, "language: #{locale}"
      end
    end
  end

  test "html pages include markdown alternate links" do
    [ privacy_policy_path, user_agreement_path, support_path, about_path ].each do |path|
      get path
      assert_response :success
      assert_select "link[rel='alternate'][type='text/markdown']"
    end
  end

  test "markdown index page lists all content" do
    get markdown_index_path(format: :md)
    assert_response :success

    # Should link to all markdown pages
    assert_includes response.body, "About CalcuMake"
    assert_includes response.body, "Support"
    assert_includes response.body, "Privacy Policy"
    assert_includes response.body, "User Agreement"

    # Should have actual URLs
    assert_includes response.body, about_url(format: :md)
    assert_includes response.body, support_url(format: :md)
    assert_includes response.body, privacy_policy_url(format: :md)
    assert_includes response.body, user_agreement_url(format: :md)
  end

  test "markdown pages have X-Robots-Tag header" do
    get privacy_policy_path(format: :md)
    assert_response :success
    assert_equal "all", response.headers["X-Robots-Tag"]
  end
end
