class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_completed, except: [:complete, :skip_walkthrough]

  STEPS = %w[welcome profile company printer filament complete].freeze

  def show
    @step = params[:step] || current_step_name
    redirect_to onboarding_path(step: current_step_name) unless valid_step?(@step)
  end

  def update
    case params[:step]
    when "profile"
      update_profile
    when "company"
      update_company
    when "printer"
      create_printer
    when "filament"
      create_filaments
    end
  end

  def skip_step
    advance_to_next_step
    redirect_to onboarding_path(step: current_step_name)
  end

  def skip_walkthrough
    complete_onboarding
    redirect_to print_pricings_path, notice: t("onboarding.skipped_notice")
  end

  def complete
    complete_onboarding
    redirect_to new_print_pricing_path, notice: t("onboarding.completed_notice")
  end

  private

  def redirect_if_completed
    redirect_to root_path if current_user.onboarding_completed?
  end

  def current_step_name
    STEPS[current_user.onboarding_current_step]
  end

  def valid_step?(step)
    STEPS.include?(step)
  end

  def advance_to_next_step
    current_user.increment!(:onboarding_current_step)
  end

  def complete_onboarding
    current_user.update!(
      onboarding_completed_at: Time.current,
      onboarding_current_step: STEPS.length - 1
    )
  end

  def update_profile
    if current_user.update(profile_params)
      advance_to_next_step
      redirect_to onboarding_path(step: current_step_name)
    else
      @step = "profile"
      render :show, status: :unprocessable_entity
    end
  end

  def update_company
    if current_user.update(company_params)
      advance_to_next_step
      redirect_to onboarding_path(step: current_step_name)
    else
      @step = "company"
      render :show, status: :unprocessable_entity
    end
  end

  def create_printer
    printer_model = params[:printer_model]
    defaults = Printer::COMMON_DEFAULTS[printer_model]

    if defaults
      printer = current_user.printers.build(
        name: printer_model,
        manufacturer: defaults[:manufacturer],
        power_consumption: defaults[:power_consumption],
        cost: defaults[:cost],
        daily_usage_hours: defaults[:daily_usage_hours],
        payoff_goal_years: defaults[:payoff_goal_years],
        material_technology: defaults[:material_technology],
        repair_cost_percentage: 0
      )

      if printer.save
        advance_to_next_step
        redirect_to onboarding_path(step: current_step_name)
      else
        @step = "printer"
        flash.now[:alert] = t("onboarding.printer.error")
        render :show, status: :unprocessable_entity
      end
    else
      @step = "printer"
      flash.now[:alert] = t("onboarding.printer.select_required")
      render :show, status: :unprocessable_entity
    end
  end

  def create_filaments
    filament_types = params[:filament_types] || []

    if filament_types.empty?
      @step = "filament"
      flash.now[:alert] = t("onboarding.filament.select_required")
      render :show, status: :unprocessable_entity
      return
    end

    filament_types.each do |filament_type|
      next if filament_type.blank?

      preset = Filament::STARTER_PRESETS[filament_type]
      next unless preset

      current_user.filaments.create!(
        name: filament_type,
        **preset
      )
    end

    advance_to_next_step
    redirect_to onboarding_path(step: current_step_name)
  end

  def profile_params
    params.require(:user).permit(:default_currency, :default_energy_cost_per_kwh)
  end

  def company_params
    params.require(:user).permit(:company_name, :company_logo)
  end
end
