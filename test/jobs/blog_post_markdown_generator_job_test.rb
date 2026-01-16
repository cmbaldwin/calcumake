require "test_helper"

class BlogPostMarkdownGeneratorJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @blog_post = BlogPost.create!(
      title: "Test Blog Post",
      slug: "test-blog-post",
      content: "<h2>Hello World</h2><p>This is <strong>test</strong> content.</p>",
      published: true,
      published_at: Time.current,
      user: @user
    )

    # Clean up any existing markdown files
    markdown_dir = Rails.root.join("public", "markdown", "blog")
    FileUtils.rm_rf(markdown_dir) if File.exist?(markdown_dir)
  end

  teardown do
    # Clean up generated files
    markdown_dir = Rails.root.join("public", "markdown", "blog")
    FileUtils.rm_rf(markdown_dir) if File.exist?(markdown_dir)
  end

  test "should create markdown directory if it doesn't exist" do
    markdown_dir = Rails.root.join("public", "markdown", "blog")
    assert_not File.exist?(markdown_dir)

    BlogPostMarkdownGeneratorJob.perform_now(@blog_post.id)

    assert File.exist?(markdown_dir)
    assert File.directory?(markdown_dir)
  end

  test "should generate markdown file" do
    BlogPostMarkdownGeneratorJob.perform_now(@blog_post.id)

    @blog_post.reload
    assert @blog_post.markdown_path.present?

    markdown_file = @blog_post.markdown_file_path
    assert File.exist?(markdown_file)
  end

  test "should generate valid markdown content" do
    BlogPostMarkdownGeneratorJob.perform_now(@blog_post.id)

    @blog_post.reload
    content = File.read(@blog_post.markdown_file_path)

    # Check frontmatter
    assert_includes content, "---"
    assert_includes content, "title: Test Blog Post"
    assert_includes content, "type: blog_post"
    assert_includes content, "language: en"

    # Check content is converted to markdown
    assert_includes content, "# Test Blog Post"
    assert_includes content, "## Hello World"
    assert_includes content, "**test**"

    # Check footer
    assert_includes content, "© 2025 株式会社モアブ (MOAB Co., Ltd.)"
  end

  test "should convert HTML to markdown properly" do
    BlogPostMarkdownGeneratorJob.perform_now(@blog_post.id)

    @blog_post.reload
    content = File.read(@blog_post.markdown_file_path)

    # Headers should be converted
    assert_includes content, "## Hello World"

    # Bold text should be converted
    assert_includes content, "**test**"

    # Paragraphs should be preserved
    assert_includes content, "This is **test** content"
  end

  test "should not generate markdown for unpublished post" do
    @blog_post.update!(published: false)

    BlogPostMarkdownGeneratorJob.perform_now(@blog_post.id)

    @blog_post.reload
    assert_nil @blog_post.markdown_path
  end

  test "should include published date in markdown" do
    published_date = Time.current - 1.day
    @blog_post.update!(published_at: published_date)

    BlogPostMarkdownGeneratorJob.perform_now(@blog_post.id)

    @blog_post.reload
    content = File.read(@blog_post.markdown_file_path)

    assert_includes content, "_Published: #{published_date.strftime('%B %d, %Y')}_"
  end

  test "should retry on failure" do
    # Stub to raise an error
    BlogPost.stub :find, ->(_id) { raise StandardError, "Test error" } do
      assert_raises(StandardError) do
        BlogPostMarkdownGeneratorJob.perform_now(@blog_post.id)
      end
    end

    # Job should be configured to retry
    assert_equal 3, BlogPostMarkdownGeneratorJob.retry_on_configurations.first.attempts
  end
end
