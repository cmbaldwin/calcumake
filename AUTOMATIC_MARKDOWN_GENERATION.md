# Automatic Markdown Generation for Blog & API Documentation

## Overview

This system automatically generates AI-optimized markdown files for blog posts and API documentation whenever content is created or updated. It uses background jobs (Solid Queue) to generate markdown asynchronously, ensuring optimal performance.

## Architecture

### Components

1. **Models** (`BlogPost`, `ApiDocument`)
   - Store content in database
   - Track markdown file path
   - Auto-trigger markdown generation on save

2. **Background Jobs** (`BlogPostMarkdownGeneratorJob`, `ApiDocumentMarkdownGeneratorJob`)
   - Generate markdown files asynchronously
   - Convert HTML content to clean markdown
   - Write files to `public/markdown/` directory
   - Handle retries on failure

3. **Controllers** (`BlogPostsController`, `ApiDocumentsController`)
   - Serve both HTML and markdown versions
   - Send pre-generated markdown files when requested
   - Queue regeneration if file missing

4. **Routes**
   - Blog: `/blog` and `/blog/:slug`
   - API Docs: `/api-docs` and `/api-docs/:version/:slug`
   - Both support `.md` format

## How It Works

### 1. Content Creation/Update Flow

```
User creates/updates blog post or API doc
    ↓
Model validates and saves to database
    ↓
after_commit callback fires
    ↓
Background job queued (Solid Queue)
    ↓
Job generates markdown file
    ↓
File written to public/markdown/{blog|api}/
    ↓
Model updated with markdown_path
```

### 2. Markdown Serving Flow

```
AI agent requests /blog/my-post.md
    ↓
Controller checks if markdown file exists
    ↓
If exists: Serve file directly (fast!)
If missing: Queue regeneration, return 202 Accepted
```

## File Structure

```
public/
└── markdown/
    ├── blog/
    │   ├── my-post-1.md
    │   ├── another-post-2.md
    │   └── ...
    └── api/
        ├── 1.0-authentication-1.md
        ├── 1.0-calculations-2.md
        └── ...
```

## Models

### BlogPost

**Fields:**
- `title` - Post title
- `slug` - URL-friendly slug (auto-generated)
- `content` - Post content (HTML)
- `excerpt` - Short excerpt
- `published` - Boolean flag
- `published_at` - Publication timestamp
- `user_id` - Author reference
- `markdown_path` - Path to generated markdown file

**Scopes:**
- `published` - Only published posts with `published_at`
- `recent` - Ordered by `published_at DESC`

**Methods:**
- `enqueue_markdown_generation` - Queue background job
- `markdown_url` - Public URL to markdown version
- `markdown_file_path` - Full filesystem path
- `markdown_stale?` - Check if regeneration needed

### ApiDocument

**Fields:**
- `title` - Document title
- `slug` - URL-friendly slug (auto-generated)
- `version` - API version (e.g., "1.0", "2.0")
- `content` - Document content (HTML)
- `description` - Short description
- `published` - Boolean flag
- `position` - Sort order
- `category` - Grouping category
- `markdown_path` - Path to generated markdown file

**Scopes:**
- `published` - Only published documents
- `by_version(version)` - Filter by version
- `by_category(category)` - Filter by category
- `ordered` - Sort by position, then title

## Background Jobs

### BlogPostMarkdownGeneratorJob

Converts blog posts to AI-optimized markdown.

**Generated Markdown Includes:**
- YAML frontmatter with metadata
- Title and publication date
- Converted HTML content (clean markdown)
- About CalcuMake footer
- Copyright notice

**HTML to Markdown Conversions:**
- `<h1>` → `#`
- `<h2>` → `##`
- `<strong>`, `<b>` → `**text**`
- `<em>`, `<i>` → `*text*`
- `<a href="">` → `[text](url)`
- `<code>` → `` `code` ``
- `<pre><code>` → ` ```code``` `
- Lists, paragraphs, line breaks

**Retry Strategy:**
- 3 attempts
- Polynomially increasing wait time

### ApiDocumentMarkdownGeneratorJob

Similar to blog job, but includes:
- Version information
- Category grouping
- API-specific metadata
- Link to full API documentation

## Controllers

### BlogPostsController

**Routes:**
- `GET /blog` - List all published blog posts
- `GET /blog/:slug` - Show individual blog post

**Markdown Support:**
- Index: `/blog.md` - Lists all posts with links
- Show: `/blog/:slug.md` - Serves pre-generated markdown

**Behavior:**
- If markdown file exists → Send file (fast)
- If markdown missing → Queue regeneration, return 202 Accepted

### ApiDocumentsController

**Routes:**
- `GET /api-docs` - List all API documentation
- `GET /api-docs/:version/:slug` - Show individual API document

**Markdown Support:**
- Index: `/api-docs.md` - Lists docs by version
- Show: `/api-docs/:version/:slug.md` - Serves pre-generated markdown

## Usage Examples

### Creating a Blog Post

```ruby
# In Rails console or admin interface
blog_post = BlogPost.create!(
  title: "How to Calculate 3D Printing Costs",
  content: "<h2>Introduction</h2><p>This guide explains...</p>",
  excerpt: "Learn how to accurately price your 3D prints",
  published: true,
  published_at: Time.current,
  user: current_user
)

# Markdown file automatically generated in background
# Available at: /blog/how-to-calculate-3d-printing-costs.md
```

### Creating API Documentation

```ruby
api_doc = ApiDocument.create!(
  title: "Authentication",
  version: "1.0",
  content: "<h2>API Keys</h2><p>To authenticate...</p>",
  description: "How to authenticate with CalcuMake API",
  category: "getting-started",
  position: 1,
  published: true
)

# Markdown file automatically generated in background
# Available at: /api-docs/1.0/authentication.md
```

### Updating Content

```ruby
blog_post.update!(
  title: "Updated Title",
  content: "<h2>New Content</h2>..."
)

# Markdown file automatically regenerated in background
```

### Accessing Markdown in AI

```bash
# AI agent fetches blog post
curl https://calcumake.com/blog/my-post.md

# AI agent fetches API docs
curl https://calcumake.com/api-docs/1.0/authentication.md

# AI agent discovers all markdown content
curl https://calcumake.com/markdown.md
```

## Markdown Index Integration

The main markdown index (`/markdown.md`) automatically includes:
- Recent 5 blog posts (if any exist)
- Latest 10 API documents (if any exist)
- Links to full blog and API indexes

Updated dynamically on each request.

## Sitemap Integration

Blog posts and API docs are automatically added to sitemap:
- Individual post/doc pages (HTML + Markdown)
- Index pages (HTML + Markdown)
- Includes `lastmod` timestamp
- Priority: 0.7 for content, 0.8 for indexes

Regenerate sitemap after adding content:
```bash
rake sitemap:refresh
```

## Performance Considerations

### Caching Strategy

1. **Pre-generated Files**
   - Markdown files generated once, served many times
   - No runtime conversion overhead
   - Direct file serving (very fast)

2. **Asynchronous Generation**
   - Content saves immediately
   - Markdown generation happens in background
   - No impact on user experience

3. **Regeneration**
   - Only triggered when content changes
   - Automatic cleanup of old files
   - Stale detection built-in

### Storage

- Markdown files stored in `public/markdown/`
- Served directly by web server (Nginx/Apache)
- No Rails/app server overhead
- CDN-friendly (cacheable)

### Solid Queue

- Uses Rails 8's built-in job queue
- PostgreSQL-backed (reliable)
- Automatic retries on failure
- Configurable workers

## Monitoring

### Logs

Check background job execution:
```bash
# In Rails logs
[Markdown] Generated blog post markdown: my-post-1.md
[Markdown] Generated API document markdown: 1.0-auth-1.md
```

### Health Checks

Monitor markdown generation:
```ruby
# Check if markdown needs regeneration
BlogPost.published.select(&:markdown_stale?).count

# Check for missing markdown files
BlogPost.published.where(markdown_path: nil).count
```

### Queue Status

```bash
# Check Solid Queue status
bin/rails solid_queue:status

# Check for failed jobs
SolidQueue::Job.where(status: 'failed').count
```

## Testing

### Model Tests

```ruby
# Test markdown generation is queued
assert_enqueued_with(job: BlogPostMarkdownGeneratorJob) do
  blog_post.save!
end

# Test URL generation
assert_includes blog_post.markdown_url, ".md"
```

### Job Tests

```ruby
# Test file creation
BlogPostMarkdownGeneratorJob.perform_now(blog_post.id)
assert File.exist?(blog_post.markdown_file_path)

# Test content conversion
content = File.read(blog_post.markdown_file_path)
assert_includes content, "# #{blog_post.title}"
```

### Integration Tests

```ruby
# Test markdown serving
get blog_post_path(blog_post.slug, format: :md)
assert_response :success
assert_equal "text/markdown; charset=utf-8", response.content_type
```

## Deployment

### Before Deployment

1. Run migrations:
   ```bash
   bin/rails db:migrate
   ```

2. Create markdown directories:
   ```bash
   mkdir -p public/markdown/blog public/markdown/api
   ```

3. Set proper permissions:
   ```bash
   chmod 755 public/markdown public/markdown/blog public/markdown/api
   ```

### After Deployment

1. Regenerate markdown for existing content (if migrating):
   ```ruby
   BlogPost.published.find_each(&:enqueue_markdown_generation)
   ApiDocument.published.find_each(&:enqueue_markdown_generation)
   ```

2. Regenerate sitemap:
   ```bash
   rake sitemap:refresh
   ```

3. Monitor job queue:
   ```bash
   watch bin/rails solid_queue:status
   ```

## Maintenance

### Regenerate All Markdown

```ruby
# Regenerate all blog posts
BlogPost.published.find_each do |post|
  BlogPostMarkdownGeneratorJob.perform_later(post.id)
end

# Regenerate all API docs
ApiDocument.published.find_each do |doc|
  ApiDocumentMarkdownGeneratorJob.perform_later(doc.id)
end
```

### Clean Up Old Files

```ruby
# Remove markdown files for deleted posts
Dir.glob(Rails.root.join("public/markdown/blog/*.md")).each do |file|
  id = file.match(/-(\d+)\.md$/)[1].to_i
  FileUtils.rm(file) unless BlogPost.exists?(id)
end
```

### Disk Space Management

Monitor markdown directory size:
```bash
du -sh public/markdown
```

Set up log rotation for job logs.

## Troubleshooting

### Markdown File Not Generated

1. Check if job was queued:
   ```ruby
   SolidQueue::Job.where(class_name: 'BlogPostMarkdownGeneratorJob')
   ```

2. Check job status:
   ```ruby
   SolidQueue::Job.failed.last&.error
   ```

3. Check file permissions:
   ```bash
   ls -la public/markdown/blog/
   ```

4. Manually trigger:
   ```ruby
   BlogPostMarkdownGeneratorJob.perform_now(blog_post.id)
   ```

### Markdown File Outdated

1. Check if content updated after file:
   ```ruby
   blog_post.markdown_stale? # Should return true
   ```

2. Force regeneration:
   ```ruby
   blog_post.enqueue_markdown_generation
   ```

### Job Failures

1. Check error logs:
   ```ruby
   SolidQueue::Job.failed.last.error
   ```

2. Common issues:
   - File permissions
   - Invalid HTML in content
   - Missing user association
   - Disk space full

## Future Enhancements

### Planned Features

1. **Multi-Language Support**
   - Generate markdown for all 7 languages
   - Language-specific slugs
   - Automatic translation integration

2. **Versioning**
   - Keep history of markdown versions
   - Rollback capability
   - Compare versions

3. **Rich Metadata**
   - Reading time estimates
   - Tag cloud for keywords
   - Related content links

4. **Analytics Integration**
   - Track AI crawler visits
   - Most accessed markdown files
   - Popular search terms

5. **Advanced Conversions**
   - Better table handling
   - Image alt text optimization
   - Code syntax highlighting hints

## Security Considerations

### Content Validation

- Sanitize HTML before conversion
- Validate slugs to prevent path traversal
- Check file write permissions

### Access Control

- Blog posts require user association
- Only published content generates markdown
- Admin interface for content management

### Rate Limiting

Consider rate limiting markdown endpoints if abuse detected.

## References

- Rails ActiveJob: https://guides.rubyonrails.org/active_job_basics.html
- Solid Queue: https://github.com/basecamp/solid_queue
- Markdown Spec: https://commonmark.org/
- "The Third Audience": https://dri.es/the-third-audience

---

**Implementation Date:** 2026-01-16
**Version:** 1.0
**Status:** ✅ Complete

© 2025 株式会社モアブ (MOAB Co., Ltd.)
