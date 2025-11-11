module ApplicationHelper
  def page_title(title = nil)
    if title.present?
      "#{title} | #{t('nav.brand')}"
    else
      t("nav.brand")
    end
  end

  def bootstrap_flash_class(flash_type)
    case flash_type.to_s
    when "notice", "success"
      "alert-success"
    when "alert", "error"
      "alert-danger"
    when "warning"
      "alert-warning"
    else
      "alert-info"
    end
  end

  def format_boolean(value)
    value ? t("common.yes") : t("common.no")
  end

  def format_percentage(value)
    return "0%" if value.nil? || value == 0
    "#{value}%"
  end

  def translate_filament_type(filament_type)
    return "" if filament_type.blank?
    t("print_pricing.filament_types.#{filament_type.downcase}")
  end

  def oauth_provider_icon(provider)
    case provider.to_s.downcase
    when "google"
      content_tag :svg, width: "18", height: "18", viewBox: "0 0 18 18", class: "me-2", "aria-hidden": "true" do
        safe_join([
          content_tag(:path, nil, fill: "#4285F4", d: "M16.51 8H8.98v3h4.3c-.18 1-.74 1.48-1.6 2.04v2.01h2.6a7.8 7.8 0 0 0 2.38-5.88c0-.57-.05-.66-.15-1.18"),
          content_tag(:path, nil, fill: "#34A853", d: "M8.98 17c2.16 0 3.97-.72 5.3-1.94l-2.6-2.04a4.8 4.8 0 0 1-2.7.75 4.8 4.8 0 0 1-4.52-3.36H1.83v2.07A8 8 0 0 0 8.98 17"),
          content_tag(:path, nil, fill: "#FBBC05", d: "M4.46 10.41a4.8 4.8 0 0 1-.25-1.41c0-.49.09-.97.25-1.41V5.52H1.83a8 8 0 0 0 0 7.37l2.63-2.48"),
          content_tag(:path, nil, fill: "#EA4335", d: "M8.98 3.58c1.32 0 2.5.45 3.44 1.35l2.54-2.59A8 8 0 0 0 8.98 1a8 8 0 0 0-7.15 4.48l2.63 2.52c.61-1.85 2.35-3.42 4.52-3.42")
        ])
      end
    when "github"
      content_tag :svg, width: "18", height: "18", viewBox: "0 0 16 16", class: "me-2", fill: "currentColor", "aria-hidden": "true" do
        content_tag(:path, nil, d: "M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.012 8.012 0 0 0 16 8c0-4.42-3.58-8-8-8z")
      end
    when "microsoft"
      content_tag :svg, width: "18", height: "18", viewBox: "0 0 16 16", class: "me-2", fill: "currentColor", "aria-hidden": "true" do
        content_tag(:path, nil, d: "M7.462 0H0v7.19h7.462V0zM16 0H8.538v7.19H16V0zM7.462 8.211H0V16h7.462V8.211zm8.538 0H8.538V16H16V8.211z")
      end
    when "facebook"
      content_tag :svg, width: "18", height: "18", viewBox: "0 0 24 24", class: "me-2", fill: "#1877F2", "aria-hidden": "true" do
        content_tag(:path, nil, d: "M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z")
      end
    when "yahoo japan", "yahoojp"
      content_tag :svg, width: "18", height: "18", viewBox: "0 0 24 24", class: "me-2", fill: "#FF0033", "aria-hidden": "true" do
        content_tag(:path, nil, d: "M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-1.5-4L7 17H5.5l2-5.5L5.5 7H7l1.5 4L10 7h1.5l-2 4.5L11.5 17H10zm7-6h-1v6h-1.5v-6H14V9.5h3V11z")
      end
    else
      ""
    end
  end

  def oauth_provider_button_class(provider)
    case provider.to_s.downcase
    when "google"
      "btn btn-outline-danger"
    when "github"
      "btn btn-outline-dark"
    when "microsoft"
      "btn btn-outline-primary"
    when "facebook"
      "btn btn-outline-primary"
    when "yahoo japan", "yahoojp"
      "btn btn-outline-danger"
    else
      "btn btn-outline-secondary"
    end
  end
end
