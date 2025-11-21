# frozen_string_literal: true

class Cards::ClientCardComponent < ViewComponent::Base
  def initialize(client:, html_options: {})
    @client = client
    @html_options = html_options
  end

  private

  attr_reader :client, :html_options

  def col_classes
    classes = [ "col-lg-4", "col-md-6" ]
    classes.concat(Array(html_options[:class])) if html_options[:class]
    classes.join(" ")
  end

  def has_company_name?
    client.company_name.present?
  end

  def company_name_badge_text
    truncate_text(client.company_name, 20)
  end

  def company_name_display
    truncate_text(client.company_name, 20)
  end

  def has_email?
    client.email.present?
  end

  def email_display
    truncate_text(client.email, 25)
  end

  def has_phone?
    client.phone.present?
  end

  def phone_display
    client.phone
  end

  def invoices_count
    client.invoices.count
  end

  def dropdown_button_attrs
    {
      class: "btn btn-outline-secondary btn-sm dropdown-toggle",
      type: "button",
      data: { "bs-toggle": "dropdown" },
      "aria-expanded": "false"
    }
  end

  def delete_link_attrs
    {
      class: "dropdown-item text-danger",
      data: {
        turbo_method: :delete,
        turbo_confirm: I18n.t("clients.confirm_delete", name: client.name)
      }
    }
  end

  def truncate_text(text, length)
    helpers.truncate(text, length: length)
  end
end
