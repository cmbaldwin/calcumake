# frozen_string_literal: true

# Background job to generate markdown file for API documentation
# Runs automatically when API document is created or updated
class ApiDocumentMarkdownGeneratorJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(api_document_id)
    api_document = ApiDocument.find(api_document_id)

    # Only generate for published docs
    return unless api_document.published?

    # Create directory if it doesn't exist
    markdown_dir = Rails.root.join("public", "markdown", "api")
    FileUtils.mkdir_p(markdown_dir)

    # Generate filename: version-slug-id.md
    filename = "#{api_document.version}-#{api_document.slug}-#{api_document.id}.md"
    file_path = markdown_dir.join(filename)

    # Generate markdown content
    markdown_content = generate_markdown(api_document)

    # Write to file
    File.write(file_path, markdown_content)

    # Update API document with markdown path
    api_document.update_column(:markdown_path, filename)

    Rails.logger.info "[Markdown] Generated API document markdown: #{filename}"
  end

  private

  def generate_markdown(api_document)
    <<~MARKDOWN
      ---
      title: #{api_document.title}
      url: #{api_document.public_url}
      canonical_url: #{api_document.public_url}
      language: en
      type: api_documentation
      version: #{api_document.version}
      category: #{api_document.category}
      last_updated: #{api_document.updated_at.iso8601}
      site_name: CalcuMake
      description: #{api_document.description}
      keywords:
        - api
        - documentation
        - calcumake
        - 3d-printing
      ---

      # #{api_document.title}

      **Version:** #{api_document.version}
      #{"**Category:** #{api_document.category}" if api_document.category.present?}
      _Last updated: #{api_document.updated_at.strftime('%B %d, %Y')}_

      #{api_document.description}

      ---

      #{convert_html_to_markdown(api_document.content)}

      ---

      **About CalcuMake API:** CalcuMake provides a RESTful API for 3D printing cost calculations. [View all API documentation](#{Rails.application.routes.url_helpers.api_documents_url})

      _© 2025 株式会社モアブ (MOAB Co., Ltd.)_
    MARKDOWN
  end

  def convert_html_to_markdown(html)
    return html if html.blank?

    # Basic HTML to markdown conversion
    text = html.dup

    # Convert headers
    text.gsub!(/<h1[^>]*>(.*?)<\/h1>/im, "## \\1\n")  # h1 -> h2 (since title is h1)
    text.gsub!(/<h2[^>]*>(.*?)<\/h2>/im, "### \\1\n")
    text.gsub!(/<h3[^>]*>(.*?)<\/h3>/im, "#### \\1\n")
    text.gsub!(/<h4[^>]*>(.*?)<\/h4>/im, "##### \\1\n")

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
    text.gsub!(/<pre[^>]*><code[^>]*class=["']language-(\w+)["'][^>]*>(.*?)<\/code><\/pre>/im) do |match|
      lang = Regexp.last_match(1)
      code = Regexp.last_match(2)
      "```#{lang}\n#{code}\n```"
    end
    text.gsub!(/<pre[^>]*><code[^>]*>(.*?)<\/code><\/pre>/im) do |match|
      "```\n#{Regexp.last_match(1)}\n```"
    end
    text.gsub!(/<code[^>]*>(.*?)<\/code>/im, "`\\1`")

    # Convert tables (basic)
    text.gsub!(/<table[^>]*>(.*?)<\/table>/im) do |match|
      table_content = Regexp.last_match(1)
      # This is a simplified table conversion
      table_content.gsub!(/<\/?t[rhd][^>]*>/i, "|")
      table_content.gsub!(/<\/?tbody[^>]*>/i, "")
      table_content.gsub!(/<\/?thead[^>]*>/i, "")
      table_content.strip
    end

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
