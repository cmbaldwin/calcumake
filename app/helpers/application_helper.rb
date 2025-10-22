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
end
