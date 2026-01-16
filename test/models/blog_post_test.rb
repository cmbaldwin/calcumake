require "test_helper"

class BlogPostTest < ActiveSupport::TestCase
  test "should be valid with required attributes" do
    user = users(:one)
    blog_post = BlogPost.new(
      title: "Test Blog Post",
      slug: "test-blog-post",
      content: "This is test content",
      user: user
    )
    assert blog_post.valid?
  end

  test "should require title" do
    blog_post = BlogPost.new(content: "Content", user: users(:one))
    assert_not blog_post.valid?
    assert_includes blog_post.errors[:title], "can't be blank"
  end

  test "should require content" do
    blog_post = BlogPost.new(title: "Title", user: users(:one))
    assert_not blog_post.valid?
    assert_includes blog_post.errors[:content], "can't be blank"
  end

  test "should require unique slug" do
    user = users(:one)
    BlogPost.create!(title: "First", slug: "test-slug", content: "Content", user: user)
    duplicate = BlogPost.new(title: "Second", slug: "test-slug", content: "Content", user: user)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "should auto-generate slug from title" do
    blog_post = BlogPost.new(title: "Hello World 123", content: "Content", user: users(:one))
    blog_post.valid?
    assert_equal "hello-world-123", blog_post.slug
  end

  test "should only include published posts in published scope" do
    user = users(:one)
    published = BlogPost.create!(
      title: "Published",
      slug: "published",
      content: "Content",
      published: true,
      published_at: Time.current,
      user: user
    )
    unpublished = BlogPost.create!(
      title: "Unpublished",
      slug: "unpublished",
      content: "Content",
      published: false,
      user: user
    )

    assert_includes BlogPost.published, published
    assert_not_includes BlogPost.published, unpublished
  end

  test "should enqueue markdown generation after save for published post" do
    user = users(:one)
    blog_post = BlogPost.new(
      title: "Test",
      slug: "test",
      content: "Content",
      published: true,
      published_at: Time.current,
      user: user
    )

    assert_enqueued_with(job: BlogPostMarkdownGeneratorJob) do
      blog_post.save!
    end
  end

  test "should not enqueue markdown generation for unpublished post" do
    user = users(:one)
    blog_post = BlogPost.new(
      title: "Test",
      slug: "test",
      content: "Content",
      published: false,
      user: user
    )

    assert_no_enqueued_jobs(only: BlogPostMarkdownGeneratorJob) do
      blog_post.save!
    end
  end

  test "should generate correct markdown URL" do
    user = users(:one)
    blog_post = BlogPost.create!(
      title: "Test",
      slug: "test-post",
      content: "Content",
      published: true,
      published_at: Time.current,
      user: user
    )

    assert_includes blog_post.markdown_url, "/blog/test-post.md"
  end

  test "should generate correct markdown file path" do
    user = users(:one)
    blog_post = BlogPost.create!(
      title: "Test",
      slug: "test-post",
      content: "Content",
      published: true,
      published_at: Time.current,
      user: user
    )

    blog_post.update_column(:markdown_path, "test-post-#{blog_post.id}.md")

    expected_path = Rails.root.join("public", "markdown", "blog", "test-post-#{blog_post.id}.md")
    assert_equal expected_path, blog_post.markdown_file_path
  end
end
