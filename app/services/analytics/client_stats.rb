module Analytics
  class ClientStats
    attr_reader :user, :start_date, :end_date

    def initialize(user, start_date: nil, end_date: nil)
      @user = user
      @end_date = end_date || Date.current
      @start_date = start_date || 30.days.ago.to_date
    end

    # Top clients by revenue
    def top_clients_by_revenue(limit: 10)
      @top_clients_by_revenue ||= begin
        client_stats = user.clients.map do |client|
          pricings = current_period_pricings.where(client: client)
          revenue = pricings.sum { |p| p.final_price * p.times_printed }

          {
            client: client,
            revenue: revenue,
            job_count: pricings.count,
            total_prints: pricings.sum(:times_printed)
          }
        end.reject { |stat| stat[:revenue].zero? }

        client_stats.sort_by { |stat| -stat[:revenue] }.take(limit)
      end
    end

    # Top clients by profitability
    def top_clients_by_profit(limit: 10)
      @top_clients_by_profit ||= begin
        client_stats = user.clients.map do |client|
          pricings = current_period_pricings.where(client: client)
          profit = pricings.sum do |p|
            profit_per_print = p.final_price - p.calculate_subtotal
            profit_per_print * p.times_printed
          end

          {
            client: client,
            profit: profit,
            job_count: pricings.count,
            profit_margin: calculate_profit_margin(pricings)
          }
        end.reject { |stat| stat[:profit].zero? }

        client_stats.sort_by { |stat| -stat[:profit] }.take(limit)
      end
    end

    # Average order value per client
    def average_order_value
      total_revenue = current_period_pricings.sum { |p| p.final_price * p.times_printed }
      total_jobs = current_period_pricings.count

      total_jobs > 0 ? (total_revenue / total_jobs.to_f).round(2) : 0
    end

    # Client activity analysis (active vs inactive)
    def client_activity_summary
      all_clients = user.clients.count
      active_clients = user.clients.joins(:print_pricings)
        .where(print_pricings: { created_at: start_date..end_date })
        .distinct
        .count

      {
        total_clients: all_clients,
        active_clients: active_clients,
        inactive_clients: all_clients - active_clients,
        activity_rate: all_clients > 0 ? (active_clients.to_f / all_clients * 100).round(1) : 0
      }
    end

    # Clients at risk (no orders in period)
    def at_risk_clients(days_threshold: 60)
      threshold_date = days_threshold.days.ago

      user.clients.select do |client|
        last_pricing = client.print_pricings.order(created_at: :desc).first
        last_pricing && last_pricing.created_at < threshold_date
      end.sort_by { |c| c.print_pricings.maximum(:created_at) || Time.at(0) }
    end

    # Revenue concentration (80/20 rule)
    def revenue_concentration
      all_clients = top_clients_by_revenue(limit: 1000) # Get all
      return { top_20_percent_revenue: 0, total_revenue: 0 } if all_clients.empty?

      total_revenue = all_clients.sum { |stat| stat[:revenue] }
      top_20_percent_count = [ (all_clients.size * 0.2).ceil, 1 ].max
      top_20_percent_revenue = all_clients.take(top_20_percent_count).sum { |stat| stat[:revenue] }

      {
        top_20_percent_revenue: top_20_percent_revenue,
        total_revenue: total_revenue,
        concentration_percentage: total_revenue > 0 ? (top_20_percent_revenue / total_revenue.to_f * 100).round(1) : 0
      }
    end

    private

    def current_period_pricings
      @current_period_pricings ||= user.print_pricings
        .includes(:plates, :client)
        .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
    end

    def calculate_profit_margin(pricings)
      return 0 if pricings.empty?

      total_revenue = pricings.sum { |p| p.final_price * p.times_printed }
      total_cost = pricings.sum { |p| p.calculate_subtotal * p.times_printed }

      return 0 if total_revenue.zero?

      profit = total_revenue - total_cost
      (profit / total_revenue.to_f * 100).round(1)
    end
  end
end
