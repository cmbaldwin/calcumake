require "test_helper"

class MarkdownHelperTest < ActionView::TestCase
  test "markdown_heading should generate proper markdown heading" do
    assert_equal "## Test Heading", markdown_heading("Test Heading", level: 2)
    assert_equal "### Test Heading", markdown_heading("Test Heading", level: 3)
    assert_equal "# Test Heading", markdown_heading("Test Heading", level: 1)
  end

  test "markdown_link should generate proper markdown link" do
    assert_equal "[Click here](https://example.com)", markdown_link("Click here", "https://example.com")
  end

  test "markdown_link should include title if provided" do
    result = markdown_link("Click here", "https://example.com", title: "Example Site")
    assert_equal "[Click here](https://example.com \"Example Site\")", result
  end

  test "markdown_list should generate unordered list" do
    items = ["Item 1", "Item 2", "Item 3"]
    result = markdown_list(items)
    assert_includes result, "- Item 1"
    assert_includes result, "- Item 2"
    assert_includes result, "- Item 3"
  end

  test "markdown_list should generate ordered list" do
    items = ["First", "Second", "Third"]
    result = markdown_list(items, ordered: true)
    assert_includes result, "1. First"
    assert_includes result, "2. Second"
    assert_includes result, "3. Third"
  end

  test "markdown_list should return empty string for blank items" do
    assert_equal "", markdown_list(nil)
    assert_equal "", markdown_list([])
  end

  test "language_name_for_locale should return correct language names" do
    assert_equal "English", language_name_for_locale(:en)
    assert_equal "日本語", language_name_for_locale(:ja)
    assert_equal "中文", language_name_for_locale(:"zh-CN")
    assert_equal "हिंदी", language_name_for_locale(:hi)
    assert_equal "Español", language_name_for_locale(:es)
    assert_equal "Français", language_name_for_locale(:fr)
    assert_equal "العربية", language_name_for_locale(:ar)
  end

  test "markdown_frontmatter should generate proper metadata hash" do
    metadata = markdown_frontmatter(
      title: "Test Page",
      url: "https://example.com/test",
      type: "test_page",
      description: "A test page",
      keywords: %w[test page]
    )

    assert_equal "Test Page", metadata[:title]
    assert_equal "https://example.com/test", metadata[:url]
    assert_equal "https://example.com/test", metadata[:canonical_url]
    assert_equal "en", metadata[:language]
    assert_equal "test_page", metadata[:type]
    assert_equal "A test page", metadata[:description]
    assert_equal %w[test page], metadata[:keywords]
    assert_includes metadata[:last_updated], Date.today.year.to_s
  end

  test "format_frontmatter should generate YAML with delimiters" do
    metadata = { title: "Test", language: "en" }
    result = format_frontmatter(metadata)

    assert_includes result, "---"
    assert_includes result, "title: Test"
    assert_includes result, "language: en"
    assert result.start_with?("---")
    assert result.end_with?("---")
  end

  test "markdown_language_navigation should generate language links" do
    result = markdown_language_navigation("/test-page", current_locale: :en)

    # Should have English as bold (current)
    assert_includes result, "**English**"

    # Should have other languages as links
    assert_includes result, "[日本語](/ja/test-page.md)"
    assert_includes result, "[中文](/zh-CN/test-page.md)"

    # Should have "Available in:" prefix
    assert_includes result, "Available in:"
  end
end
