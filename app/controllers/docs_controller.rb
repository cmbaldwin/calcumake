# frozen_string_literal: true

# Serves MCP documentation in both HTML and raw Markdown formats.
class DocsController < ApplicationController
  # GET /docs/mcp          → HTML page with embedded Markdown
  # GET /docs/mcp/markdown → raw text/markdown (for AI agents)
  def mcp
    @markdown_content = File.read(Rails.root.join("docs/MCP_GUIDE.md"))
  end

  def mcp_markdown
    content = File.read(Rails.root.join("docs/MCP_GUIDE.md"))
    render plain: content, content_type: "text/markdown; charset=utf-8"
  end
end
