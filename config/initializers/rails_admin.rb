RailsAdmin.config do |config|
  config.asset_source = :importmap

  ### Popular gems integration

  ## == Devise ==
  config.authenticate_with do
    # Redirect to sign in if not authenticated
    redirect_to main_app.new_user_session_path unless current_user
  end

  config.authorize_with do
    # Redirect to root if user is not admin
    unless current_user&.admin?
      redirect_to main_app.root_path
    end
  end

  config.current_user_method(&:current_user)

  ## == CancanCan ==
  # config.authorize_with :cancancan

  ## == Pundit ==
  # config.authorize_with :pundit

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/railsadminteam/rails_admin/wiki/Base-configuration

  ## == Gravatar integration ==
  ## To disable Gravatar integration in Navigation Bar set to false
  # config.show_gravatar = true

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app

    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end

  # Article model configuration
  config.model "Article" do
    navigation_label "Content"
    weight 1

    list do
      field :id
      field :title do
        # Show title in current locale
        formatted_value do
          bindings[:object].title
        end
      end
      field :author
      field :published_at
      field :featured
      field :created_at
      field :updated_at
    end

    edit do
      # Base fields (not translated)
      group :base do
        label "Article Details"

        # Info about current locale
        field :current_locale_info, :string do
          label "Editing Locale"
          read_only true
          formatted_value do
            locale = I18n.locale
            locale_names = {
              en: "English",
              ja: "Japanese (日本語)",
              es: "Spanish (Español)",
              fr: "French (Français)",
              ar: "Arabic (العربية)",
              hi: "Hindi (हिन्दी)",
              "zh-CN": "Chinese (中文)"
            }
            locale_name = locale_names[locale] || locale.to_s

            "Currently editing: #{locale_name}"
          end
          help "To edit another language, add ?locale=ja (or es, fr, ar, hi, zh-CN) to the URL"
        end

        field :author do
          help "Author name (not translated)"
        end
        field :published_at do
          help "Leave blank to save as draft. Set to publish immediately or schedule for future."
        end
        field :featured do
          help "Feature this article on the blog index page"
        end
      end

      # Translated fields - Title & SEO
      group :content do
        label "Content (Translatable)"

        field :title do
          help "Article title - translatable per locale"
        end

        field :slug do
          help "URL-friendly slug. Auto-generated from title if left blank."
        end

        field :excerpt do
          help "Short excerpt for article listings (optional)"
        end

        # Rich text content field
        field :content do
          partial "form_action_text"
          help "Article content with rich text editor"
        end
      end

      # SEO fields
      group :seo do
        label "SEO & Meta Data"

        field :meta_description do
          help "Meta description for search engines (optional, auto-generated from excerpt if blank)"
        end

        field :meta_keywords do
          help "Meta keywords for search engines (optional)"
        end

        field :translation_notice do
          help "Show 'auto-translated' notice for non-English locales"
        end
      end
    end

    show do
      field :id
      field :author
      field :title
      field :slug
      field :excerpt
      field :content
      field :meta_description
      field :meta_keywords
      field :published_at
      field :featured
      field :translation_notice
      field :created_at
      field :updated_at
    end
  end
end
