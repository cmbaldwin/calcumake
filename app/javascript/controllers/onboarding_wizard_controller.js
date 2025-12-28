import { Controller } from "@hotwired/stimulus"

// Manages the onboarding wizard progress and navigation
export default class extends Controller {
  static values = {
    currentStep: String,
    totalSteps: Number
  }

  connect() {
    this.updateProgress()
  }

  updateProgress() {
    const stepIndex = this.getStepIndex(this.currentStepValue)
    const percentage = (stepIndex / (this.totalStepsValue - 1)) * 100

    const progressBar = this.element.querySelector('.progress-bar')
    if (progressBar) {
      progressBar.style.width = `${percentage}%`
      progressBar.setAttribute('aria-valuenow', stepIndex)
    }
  }

  getStepIndex(stepName) {
    const steps = ['welcome', 'profile', 'company', 'printer', 'filament', 'complete']
    return steps.indexOf(stepName)
  }
}
