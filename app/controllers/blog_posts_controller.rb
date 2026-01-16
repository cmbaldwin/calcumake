# frozen_string_literal: true

# Controller for blog posts with automatic markdown serving
class BlogPostsController < ApplicationController
  include MarkdownRenderable

  before_action :set_blog_post, only: [ :show ]

  # GET /blog
  def index
    @blog_posts = BlogPost.published.recent.page(params[:page]).per(10)

    respond_to do |format|
      format.html
      format.md do
        render plain: blog_index_markdown, content_type: "text/markdown"
      end
    end
  end

  # GET /blog/:slug
  def show
    respond_to do |format|
      format.html
      format.md do
        serve_blog_post_markdown
      end
    end
  end

  private

  def set_blog_post
    @blog_post = BlogPost.published.find_by!(slug: params[:slug])
  end

  def serve_blog_post_markdown
    # Check if markdown file exists
    if @blog_post.markdown_path.present? && File.exist?(@blog_post.markdown_file_path)
      # Serve the pre-generated markdown file
      send_file @blog_post.markdown_file_path,
                type: "text/markdown",
                disposition: "inline"
    else
      # Regenerate if missing
      @blog_post.enqueue_markdown_generation
      render plain: "Markdown generation in progress. Please try again in a moment.",
             status: :accepted,
             content_type: "text/markdown"
    end
  end

  def blog_index_markdown
    <<~MARKDOWN
      ---
      title: CalcuMake Blog
      url: #{blog_posts_url}
      language: en
      type: blog_index
      site_name: CalcuMake
      description: Blog posts about 3D printing, cost calculation, and project management
      ---

      # CalcuMake Blog

      Latest posts about 3D printing, cost calculation, and project management.

      ## Recent Posts

      #{@blog_posts.map { |post| "- [#{post.title}](#{post.markdown_url}) - _#{post.published_at&.strftime('%B %d, %Y')}_" }.join("\n")}

      ---

      _© 2025 株式会社モアブ (MOAB Co., Ltd.)_
    MARKDOWN
  end
end
