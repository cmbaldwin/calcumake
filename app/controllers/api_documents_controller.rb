# frozen_string_literal: true

# Controller for API documentation with automatic markdown serving
class ApiDocumentsController < ApplicationController
  include MarkdownRenderable

  before_action :set_api_document, only: [ :show ]

  # GET /api-docs
  def index
    @api_documents = ApiDocument.published.ordered
    @versions = ApiDocument.published.distinct.pluck(:version).sort.reverse
    @categories = ApiDocument.published.distinct.pluck(:category).compact.sort

    respond_to do |format|
      format.html
      format.md do
        render plain: api_index_markdown, content_type: "text/markdown"
      end
    end
  end

  # GET /api-docs/:version/:slug
  def show
    respond_to do |format|
      format.html
      format.md do
        serve_api_document_markdown
      end
    end
  end

  private

  def set_api_document
    @api_document = ApiDocument.published.find_by!(version: params[:version], slug: params[:slug])
  end

  def serve_api_document_markdown
    # Check if markdown file exists
    if @api_document.markdown_path.present? && File.exist?(@api_document.markdown_file_path)
      # Serve the pre-generated markdown file
      send_file @api_document.markdown_file_path,
                type: "text/markdown",
                disposition: "inline"
    else
      # Regenerate if missing
      @api_document.enqueue_markdown_generation
      render plain: "Markdown generation in progress. Please try again in a moment.",
             status: :accepted,
             content_type: "text/markdown"
    end
  end

  def api_index_markdown
    versions = ApiDocument.published.distinct.pluck(:version).sort.reverse

    version_sections = versions.map do |version|
      docs = ApiDocument.published.by_version(version).ordered
      <<~VERSION
        ### Version #{version}

        #{docs.map { |doc| "- [#{doc.title}](#{doc.markdown_url})#{doc.category.present? ? " (#{doc.category})" : ""}" }.join("\n")}
      VERSION
    end.join("\n")

    <<~MARKDOWN
      ---
      title: CalcuMake API Documentation
      url: #{api_documents_url}
      language: en
      type: api_documentation_index
      site_name: CalcuMake
      description: Complete API documentation for CalcuMake 3D printing cost calculator
      versions: [#{versions.join(', ')}]
      ---

      # CalcuMake API Documentation

      Complete API documentation for integrating CalcuMake's 3D printing cost calculation capabilities.

      ## Available Documentation

      #{version_sections}

      ## About the API

      CalcuMake provides a RESTful API for:
      - 3D printing cost calculations
      - Project management
      - Invoice generation
      - Multi-currency support

      For access or questions, contact: [cody@moab.jp](mailto:cody@moab.jp)

      ---

      _© 2025 株式会社モアブ (MOAB Co., Ltd.)_
    MARKDOWN
  end
end
