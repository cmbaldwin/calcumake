module Analytics
  class MaterialStats
    attr_reader :user, :start_date, :end_date

    def initialize(user, start_date: nil, end_date: nil)
      @user = user
      @end_date = end_date || Date.current
      @start_date = start_date || 30.days.ago.to_date
    end

    # Most used filaments by weight
    def top_filaments_by_usage(limit: 10)
      @top_filaments_by_usage ||= begin
        filament_usage = {}

        current_period_pricings.each do |pricing|
          pricing.plates.each do |plate|
            plate.plate_filaments.each do |pf|
              filament = pf.filament
              weight_used = pf.filament_weight * pricing.times_printed

              if filament_usage[filament.id]
                filament_usage[filament.id][:weight_grams] += weight_used
                filament_usage[filament.id][:cost] += (weight_used / 1000.0) * filament.price_per_kg
                filament_usage[filament.id][:print_count] += pricing.times_printed
              else
                filament_usage[filament.id] = {
                  filament: filament,
                  weight_grams: weight_used,
                  cost: (weight_used / 1000.0) * filament.price_per_kg,
                  print_count: pricing.times_printed
                }
              end
            end
          end
        end

        filament_usage.values
          .sort_by { |stat| -stat[:weight_grams] }
          .take(limit)
      end
    end

    # Most used resins by volume
    def top_resins_by_usage(limit: 10)
      @top_resins_by_usage ||= begin
        resin_usage = {}

        current_period_pricings.each do |pricing|
          pricing.plates.each do |plate|
            plate.plate_resins.each do |pr|
              resin = pr.resin
              volume_used = pr.resin_volume_ml * pricing.times_printed

              if resin_usage[resin.id]
                resin_usage[resin.id][:volume_ml] += volume_used
                resin_usage[resin.id][:cost] += (volume_used / 1000.0) * resin.price_per_liter
                resin_usage[resin.id][:print_count] += pricing.times_printed
              else
                resin_usage[resin.id] = {
                  resin: resin,
                  volume_ml: volume_used,
                  cost: (volume_used / 1000.0) * resin.price_per_liter,
                  print_count: pricing.times_printed
                }
              end
            end
          end
        end

        resin_usage.values
          .sort_by { |stat| -stat[:volume_ml] }
          .take(limit)
      end
    end

    # Total material costs
    def total_material_costs
      {
        filament_cost: total_filament_cost,
        resin_cost: total_resin_cost,
        total_cost: total_filament_cost + total_resin_cost
      }
    end

    # Material cost breakdown over time
    def material_costs_by_day
      @material_costs_by_day ||= begin
        costs_by_date = Hash.new { |h, k| h[k] = { filament: 0, resin: 0 } }

        current_period_pricings.each do |pricing|
          date = pricing.created_at.to_date

          pricing.plates.each do |plate|
            # Filament costs
            plate.plate_filaments.each do |pf|
              cost = (pf.filament_weight / 1000.0) * pf.filament.price_per_kg * pricing.times_printed
              costs_by_date[date][:filament] += cost
            end

            # Resin costs
            plate.plate_resins.each do |pr|
              cost = (pr.resin_volume_ml / 1000.0) * pr.resin.price_per_liter * pricing.times_printed
              costs_by_date[date][:resin] += cost
            end
          end
        end

        costs_by_date
      end
    end

    # Average cost per print (materials only)
    def average_material_cost_per_print
      total_prints = current_period_pricings.sum(:times_printed)
      return 0 if total_prints.zero?

      total_cost = total_material_costs[:total_cost]
      (total_cost / total_prints.to_f).round(2)
    end

    # Material waste/failure cost
    def estimated_failure_cost
      current_period_pricings.sum do |pricing|
        next 0 unless pricing.failure_rate_percentage && pricing.failure_rate_percentage > 0

        material_cost = pricing.plates.sum do |plate|
          filament_cost = plate.plate_filaments.sum do |pf|
            (pf.filament_weight / 1000.0) * pf.filament.price_per_kg
          end

          resin_cost = plate.plate_resins.sum do |pr|
            (pr.resin_volume_ml / 1000.0) * pr.resin.price_per_liter
          end

          filament_cost + resin_cost
        end

        # Calculate failure cost based on failure rate and times printed
        failure_cost = material_cost * (pricing.failure_rate_percentage / 100.0) * pricing.times_printed
        failure_cost
      end.round(2)
    end

    # Technology split (FDM vs Resin)
    def technology_usage_split
      fdm_prints = 0
      resin_prints = 0

      current_period_pricings.each do |pricing|
        pricing.plates.each do |plate|
          if plate.material_technology == "fdm"
            fdm_prints += pricing.times_printed
          elsif plate.material_technology == "resin"
            resin_prints += pricing.times_printed
          end
        end
      end

      total = fdm_prints + resin_prints
      {
        fdm_prints: fdm_prints,
        resin_prints: resin_prints,
        fdm_percentage: total > 0 ? (fdm_prints.to_f / total * 100).round(1) : 0,
        resin_percentage: total > 0 ? (resin_prints.to_f / total * 100).round(1) : 0
      }
    end

    private

    def current_period_pricings
      @current_period_pricings ||= user.print_pricings
        .includes(plates: [ :plate_filaments, :plate_resins, { plate_filaments: :filament }, { plate_resins: :resin } ])
        .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
    end

    def total_filament_cost
      current_period_pricings.sum do |pricing|
        pricing.plates.sum do |plate|
          plate.plate_filaments.sum do |pf|
            (pf.filament_weight / 1000.0) * pf.filament.price_per_kg * pricing.times_printed
          end
        end
      end.round(2)
    end

    def total_resin_cost
      current_period_pricings.sum do |pricing|
        pricing.plates.sum do |plate|
          plate.plate_resins.sum do |pr|
            (pr.resin_volume_ml / 1000.0) * pr.resin.price_per_liter * pricing.times_printed
          end
        end
      end.round(2)
    end
  end
end
