class Shared::DateRangeFilterComponent < ViewComponent::Base
  def initialize(form:)
    @form = form
  end

  def presets
    [
      { label: I18n.t("analytics.filters.last_7_days"), value: "last_7_days" },
      { label: I18n.t("analytics.filters.last_30_days"), value: "last_30_days" },
      { label: I18n.t("analytics.filters.last_90_days"), value: "last_90_days" },
      { label: I18n.t("analytics.filters.this_month"), value: "this_month" },
      { label: I18n.t("analytics.filters.last_month"), value: "last_month" },
      { label: I18n.t("analytics.filters.this_year"), value: "this_year" }
    ]
  end
end
