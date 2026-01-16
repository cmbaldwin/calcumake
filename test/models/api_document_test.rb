require "test_helper"

class ApiDocumentTest < ActiveSupport::TestCase
  test "should be valid with required attributes" do
    api_doc = ApiDocument.new(
      title: "Test API Doc",
      slug: "test-api-doc",
      version: "1.0",
      content: "This is test content"
    )
    assert api_doc.valid?
  end

  test "should require title" do
    api_doc = ApiDocument.new(version: "1.0", content: "Content")
    assert_not api_doc.valid?
    assert_includes api_doc.errors[:title], "can't be blank"
  end

  test "should require version" do
    api_doc = ApiDocument.new(title: "Title", content: "Content")
    assert_not api_doc.valid?
    assert_includes api_doc.errors[:version], "can't be blank"
  end

  test "should require content" do
    api_doc = ApiDocument.new(title: "Title", version: "1.0")
    assert_not api_doc.valid?
    assert_includes api_doc.errors[:content], "can't be blank"
  end

  test "should require unique slug" do
    ApiDocument.create!(title: "First", slug: "test-slug", version: "1.0", content: "Content")
    duplicate = ApiDocument.new(title: "Second", slug: "test-slug", version: "1.0", content: "Content")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "should auto-generate slug from title" do
    api_doc = ApiDocument.new(title: "Hello API World", version: "1.0", content: "Content")
    api_doc.valid?
    assert_equal "hello-api-world", api_doc.slug
  end

  test "should only include published docs in published scope" do
    published = ApiDocument.create!(
      title: "Published",
      slug: "published",
      version: "1.0",
      content: "Content",
      published: true
    )
    unpublished = ApiDocument.create!(
      title: "Unpublished",
      slug: "unpublished",
      version: "1.0",
      content: "Content",
      published: false
    )

    assert_includes ApiDocument.published, published
    assert_not_includes ApiDocument.published, unpublished
  end

  test "should filter by version" do
    v1_doc = ApiDocument.create!(
      title: "V1 Doc",
      slug: "v1-doc",
      version: "1.0",
      content: "Content",
      published: true
    )
    v2_doc = ApiDocument.create!(
      title: "V2 Doc",
      slug: "v2-doc",
      version: "2.0",
      content: "Content",
      published: true
    )

    assert_includes ApiDocument.by_version("1.0"), v1_doc
    assert_not_includes ApiDocument.by_version("1.0"), v2_doc
  end

  test "should filter by category" do
    auth_doc = ApiDocument.create!(
      title: "Auth Doc",
      slug: "auth-doc",
      version: "1.0",
      content: "Content",
      category: "authentication",
      published: true
    )
    calc_doc = ApiDocument.create!(
      title: "Calc Doc",
      slug: "calc-doc",
      version: "1.0",
      content: "Content",
      category: "calculations",
      published: true
    )

    assert_includes ApiDocument.by_category("authentication"), auth_doc
    assert_not_includes ApiDocument.by_category("authentication"), calc_doc
  end

  test "should enqueue markdown generation after save for published doc" do
    api_doc = ApiDocument.new(
      title: "Test",
      slug: "test",
      version: "1.0",
      content: "Content",
      published: true
    )

    assert_enqueued_with(job: ApiDocumentMarkdownGeneratorJob) do
      api_doc.save!
    end
  end

  test "should not enqueue markdown generation for unpublished doc" do
    api_doc = ApiDocument.new(
      title: "Test",
      slug: "test",
      version: "1.0",
      content: "Content",
      published: false
    )

    assert_no_enqueued_jobs(only: ApiDocumentMarkdownGeneratorJob) do
      api_doc.save!
    end
  end

  test "should generate correct markdown URL" do
    api_doc = ApiDocument.create!(
      title: "Test",
      slug: "test-doc",
      version: "1.0",
      content: "Content",
      published: true
    )

    assert_includes api_doc.markdown_url, "/api-docs/1.0/test-doc.md"
  end

  test "should order by position and title" do
    doc1 = ApiDocument.create!(title: "B Doc", slug: "b-doc", version: "1.0", content: "Content", position: 2, published: true)
    doc2 = ApiDocument.create!(title: "A Doc", slug: "a-doc", version: "1.0", content: "Content", position: 1, published: true)
    doc3 = ApiDocument.create!(title: "C Doc", slug: "c-doc", version: "1.0", content: "Content", position: 1, published: true)

    ordered = ApiDocument.published.ordered
    assert_equal doc2, ordered.first
    assert_equal doc1, ordered.last
  end
end
