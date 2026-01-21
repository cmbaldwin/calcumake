class AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_pro_plan

  def show
    # Parse date range from params or use defaults
    @start_date = params[:start_date]&.to_date || 30.days.ago.to_date
    @end_date = params[:end_date]&.to_date || Date.current

    # Initialize analytics service
    @analytics = Analytics::OverviewStats.new(current_user, start_date: @start_date, end_date: @end_date)

    # Load data based on active tab
    @active_tab = params[:tab] || "overview"

    case @active_tab
    when "printers"
      @printer_analytics = Analytics::PrinterStats.new(current_user, start_date: @start_date, end_date: @end_date)
    when "clients"
      @client_analytics = Analytics::ClientStats.new(current_user, start_date: @start_date, end_date: @end_date)
    when "materials"
      @material_analytics = Analytics::MaterialStats.new(current_user, start_date: @start_date, end_date: @end_date)
    end
  end

  private

  def require_pro_plan
    unless current_user.pro? || current_user.admin?
      redirect_to subscriptions_pricing_path,
        alert: I18n.t("analytics.pro_plan_required")
    end
  end
end
