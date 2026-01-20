module Analytics
  class OverviewStats
    attr_reader :user, :start_date, :end_date

    def initialize(user, start_date: nil, end_date: nil)
      @user = user
      @end_date = end_date || Date.current
      @start_date = start_date || 30.days.ago.to_date
    end

    # Revenue stats
    def total_revenue
      @total_revenue ||= calculate_total_revenue(current_period_pricings)
    end

    def revenue_trend
      previous = calculate_total_revenue(previous_period_pricings)
      return 0 if previous.zero?
      ((total_revenue - previous) / previous.to_f * 100).round(1)
    end

    # Print volume stats
    def total_prints
      @total_prints ||= current_period_pricings.sum(:times_printed)
    end

    def prints_trend
      previous = previous_period_pricings.sum(:times_printed)
      return 0 if previous.zero?
      ((total_prints - previous) / previous.to_f * 100).round(1)
    end

    # Calculation count stats
    def total_calculations
      @total_calculations ||= current_period_pricings.count
    end

    def calculations_trend
      previous = previous_period_pricings.count
      return 0 if previous.zero?
      ((total_calculations - previous) / previous.to_f * 100).round(1)
    end

    # Profit stats
    def total_profit
      @total_profit ||= current_period_pricings.sum { |p| p.total_estimated_profit }
    end

    def profit_trend
      previous = previous_period_pricings.sum { |p| p.total_estimated_profit }
      return 0 if previous.zero?
      ((total_profit - previous) / previous.to_f * 100).round(1)
    end

    # Time series data for charts (native PostgreSQL queries)
    def revenue_by_day
      cache_key = ["analytics", user.id, "revenue_by_day", start_date, end_date]
      Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
        group_by_date(current_period_pricings, "revenue")
      end
    end

    def prints_by_day
      cache_key = ["analytics", user.id, "prints_by_day", start_date, end_date]
      Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
        group_by_date(current_period_pricings, "prints")
      end
    end

    private

    def current_period_pricings
      @current_period_pricings ||= user.print_pricings
        .includes(:plates)
        .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
    end

    def previous_period_pricings
      @previous_period_pricings ||= begin
        period_length = (end_date - start_date).to_i + 1
        previous_start = start_date - period_length.days
        previous_end = start_date - 1.day

        user.print_pricings
          .includes(:plates)
          .where(created_at: previous_start.beginning_of_day..previous_end.end_of_day)
      end
    end

    def calculate_total_revenue(pricings)
      pricings.sum { |p| p.final_price * p.times_printed }
    end

    # Group data by date using native PostgreSQL DATE function
    def group_by_date(pricings, metric)
      case metric
      when "revenue"
        # Group revenue by date
        result = pricings
          .group("DATE(print_pricings.created_at)")
          .select("DATE(print_pricings.created_at) as date, SUM(final_price * times_printed) as value")
          .order("date")

        result.each_with_object({}) do |row, hash|
          hash[row.date] = row.value.to_f
        end

      when "prints"
        # Group print volume by date
        result = pricings
          .group("DATE(print_pricings.created_at)")
          .select("DATE(print_pricings.created_at) as date, SUM(times_printed) as value")
          .order("date")

        result.each_with_object({}) do |row, hash|
          hash[row.date] = row.value.to_i
        end

      else
        {}
      end
    end
  end
end
