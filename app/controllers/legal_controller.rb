class LegalController < ApplicationController
  include MarkdownRenderable

  def privacy_policy
    respond_with_markdown(
      "legal.privacy_policy",
      metadata: {
        title: t("legal.privacy_policy.title"),
        url: privacy_policy_url,
        base_path: "/privacy-policy",
        include_locale_in_path: false,
        type: "legal_document",
        description: t("legal.privacy_policy.description", default: "Privacy policy for CalcuMake"),
        keywords: %w[privacy data-protection gdpr 3d-printing calcumake]
      }
    )
  end

  def user_agreement
    respond_with_markdown(
      "legal.user_agreement",
      metadata: {
        title: t("legal.user_agreement.title"),
        url: user_agreement_url,
        base_path: "/user-agreement",
        include_locale_in_path: false,
        type: "legal_document",
        description: t("legal.user_agreement.description", default: "Terms of service for CalcuMake"),
        keywords: %w[terms service agreement 3d-printing calcumake]
      }
    )
  end

  def support
    respond_with_markdown(
      "legal.support",
      metadata: {
        title: t("legal.support.title"),
        url: support_url,
        base_path: "/support",
        include_locale_in_path: false,
        type: "support_page",
        description: t("legal.support.description", default: "Support and FAQ for CalcuMake"),
        keywords: %w[support help faq 3d-printing calcumake]
      }
    )
  end
end
