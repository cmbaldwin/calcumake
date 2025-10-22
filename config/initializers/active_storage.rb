# Active Storage configuration for proper S3 content type handling

Rails.application.configure do
  # Ensure proper content types for S3 uploads
  config.active_storage.content_types_to_serve_as_binary.delete("image/svg+xml")

  # Set proper content disposition for images
  config.active_storage.content_types_allowed_inline = [
    "image/png",
    "image/gif",
    "image/jpg",
    "image/jpeg",
    "image/webp",
    "image/svg+xml"
  ]
end

# Custom blob URL handling for proper S3 content types
Rails.application.reloader.to_prepare do
  ActiveStorage::Blob.class_eval do
    def url(expires_in: ActiveStorage.service_urls_expire_in, disposition: :attachment, filename: nil, **options)
      case disposition
      when :inline
        # For inline display, use proper content type
        options[:response_content_type] = content_type if content_type.present?
        options[:response_content_disposition] = "inline; filename=\"#{filename || self.filename.to_s}\""
      when :attachment
        options[:response_content_disposition] = "attachment; filename=\"#{filename || self.filename.to_s}\""
      end

      service.url(key, expires_in: expires_in, **options)
    end
  end
end