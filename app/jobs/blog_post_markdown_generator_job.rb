# frozen_string_literal: true

# Background job to generate markdown file for blog post
# Runs automatically when blog post is created or updated
class BlogPostMarkdownGeneratorJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(blog_post_id)
    blog_post = BlogPost.find(blog_post_id)

    # Only generate for published posts
    return unless blog_post.published?

    # Create directory if it doesn't exist
    markdown_dir = Rails.root.join("public", "markdown", "blog")
    FileUtils.mkdir_p(markdown_dir)

    # Generate filename: slug-id.md
    filename = "#{blog_post.slug}-#{blog_post.id}.md"
    file_path = markdown_dir.join(filename)

    # Generate markdown content
    markdown_content = generate_markdown(blog_post)

    # Write to file
    File.write(file_path, markdown_content)

    # Update blog post with markdown path
    blog_post.update_column(:markdown_path, filename)

    Rails.logger.info "[Markdown] Generated blog post markdown: #{filename}"
  end

  private

  def generate_markdown(blog_post)
    <<~MARKDOWN
      ---
      title: #{blog_post.title}
      url: #{blog_post.public_url}
      canonical_url: #{blog_post.public_url}
      language: en
      type: blog_post
      published_at: #{blog_post.published_at&.iso8601}
      last_updated: #{blog_post.updated_at.iso8601}
      site_name: CalcuMake
      author: #{blog_post.user.email}
      excerpt: #{blog_post.excerpt}
      keywords:
        - 3d-printing
        - calcumake
        - blog
      ---

      # #{blog_post.title}

      _Published: #{blog_post.published_at&.strftime('%B %d, %Y')}_
      _Last updated: #{blog_post.updated_at.strftime('%B %d, %Y')}_

      #{convert_html_to_markdown(blog_post.content)}

      ---

      **About CalcuMake:** Free 3D printing cost calculator and project management tool. [Learn more](#{Rails.application.routes.url_helpers.about_url})

      _© 2025 株式会社モアブ (MOAB Co., Ltd.)_
    MARKDOWN
  end

  def convert_html_to_markdown(html)
    return html if html.blank?

    # Basic HTML to markdown conversion
    text = html.dup

    # Convert headers
    text.gsub!(/<h1[^>]*>(.*?)<\/h1>/im, "# \\1\n")
    text.gsub!(/<h2[^>]*>(.*?)<\/h2>/im, "## \\1\n")
    text.gsub!(/<h3[^>]*>(.*?)<\/h3>/im, "### \\1\n")
    text.gsub!(/<h4[^>]*>(.*?)<\/h4>/im, "#### \\1\n")

    # Convert lists
    text.gsub!(/<li[^>]*>(.*?)<\/li>/im, "- \\1")
    text.gsub!(/<\/?[uo]l[^>]*>/i, "\n")

    # Convert links
    text.gsub!(/<a[^>]*href=["'](.*?)["'][^>]*>(.*?)<\/a>/im, "[\\2](\\1)")

    # Convert emphasis
    text.gsub!(/<strong[^>]*>(.*?)<\/strong>/im, "**\\1**")
    text.gsub!(/<em[^>]*>(.*?)<\/em>/im, "*\\1*")
    text.gsub!(/<b[^>]*>(.*?)<\/b>/im, "**\\1**")
    text.gsub!(/<i[^>]*>(.*?)<\/i>/im, "*\\1*")

    # Convert paragraphs
    text.gsub!(/<p[^>]*>(.*?)<\/p>/im, "\\1\n\n")

    # Convert line breaks
    text.gsub!(/<br\s*\/?>/i, "\n")

    # Convert code blocks
    text.gsub!(/<pre[^>]*><code[^>]*>(.*?)<\/code><\/pre>/im) do |match|
      "```\n#{Regexp.last_match(1)}\n```"
    end
    text.gsub!(/<code[^>]*>(.*?)<\/code>/im, "`\\1`")

    # Remove remaining HTML tags
    text.gsub!(/<[^>]+>/, "")

    # Clean up entities
    text.gsub!("&nbsp;", " ")
    text.gsub!("&amp;", "&")
    text.gsub!("&lt;", "<")
    text.gsub!("&gt;", ">")
    text.gsub!("&quot;", '"')

    # Clean up extra whitespace
    text.gsub!(/\n\n\n+/, "\n\n")
    text.strip
  end
end
