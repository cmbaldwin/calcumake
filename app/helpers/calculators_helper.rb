module CalculatorsHelper
  def demo_calculator(energy_cost: 0.12, **options)
    render "shared/components/calculators/calculator_base",
           mode: 'demo',
           stimulus_controller: 'demo-calculator',
           energy_cost: energy_cost,
           show_detailed_results: true,
           show_features: true,
           **options
  end

  def quick_calculator(energy_cost: 0.12, **options)
    # Calculate average labor cost from user's prep and post-processing defaults
    user_prep_cost = current_user&.default_prep_cost_per_hour || 20.0
    user_post_cost = current_user&.default_postprocessing_cost_per_hour || 20.0
    average_labor_cost = (user_prep_cost + user_post_cost) / 2.0

    render "shared/components/calculators/calculator_base",
           mode: 'quick',
           stimulus_controller: 'quick-calculator',
           energy_cost: energy_cost,
           show_detailed_results: false,
           show_features: false,
           user_currency: current_user&.default_currency || 'USD',
           user_locale: I18n.locale.to_s.gsub('_', '-'),
           filament_price_per_kg: 25.0, # Keep this as a reasonable average for quick estimates
           labor_rate_per_hour: average_labor_cost,
           **options
  end

  def calculator_input_field(stimulus_controller:, target:, label:, value:, options: {})
    content_tag :div, class: options[:wrapper_class] do
      concat(label_tag nil, label, class: options[:label_class])
      concat(number_field_tag nil, value, {
        class: options[:input_class],
        data: {
          "#{stimulus_controller.gsub('-', '_')}_target": target,
          action: "input->#{stimulus_controller}#calculate"
        },
        min: options[:min],
        step: options[:step]
      }.compact)
    end
  end
end