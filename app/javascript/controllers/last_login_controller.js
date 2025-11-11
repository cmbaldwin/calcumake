import { Controller } from "@hotwired/stimulus"

// Tracks and displays the last used login method to help users remember how they signed in
export default class extends Controller {
  static targets = ["emailForm", "oauthButton"]
  static values = {
    provider: String  // The current provider being displayed (if any)
  }

  connect() {
    this.showLastLoginMethod()
  }

  // Track when user clicks an OAuth button
  trackOAuthLogin(event) {
    const button = event.currentTarget
    const provider = button.dataset.provider

    if (provider) {
      localStorage.setItem('lastLoginMethod', provider)
      localStorage.setItem('lastLoginTime', new Date().toISOString())
    }
  }

  // Track when user submits email/password form
  trackEmailLogin(event) {
    localStorage.setItem('lastLoginMethod', 'email')
    localStorage.setItem('lastLoginTime', new Date().toISOString())
  }

  // Show indicator for last used login method
  showLastLoginMethod() {
    const lastMethod = localStorage.getItem('lastLoginMethod')
    const lastTime = localStorage.getItem('lastLoginTime')

    if (!lastMethod || !lastTime) return

    // Calculate how long ago the last login was
    const lastLoginDate = new Date(lastTime)
    const now = new Date()
    const daysSince = Math.floor((now - lastLoginDate) / (1000 * 60 * 60 * 24))

    // Only show hint if last login was within 90 days
    if (daysSince > 90) {
      this.clearLastLoginData()
      return
    }

    if (lastMethod === 'email') {
      this.highlightEmailLogin(daysSince)
    } else {
      this.highlightOAuthProvider(lastMethod, daysSince)
    }
  }

  highlightEmailLogin(daysSince) {
    if (!this.hasEmailFormTarget) return

    const hint = document.createElement('div')
    hint.className = 'alert alert-info alert-sm mb-3'
    hint.innerHTML = `
      <i class="bi bi-info-circle"></i>
      <span>${this.getTimeMessage(daysSince)}</span>
    `

    this.emailFormTarget.insertBefore(hint, this.emailFormTarget.firstChild)
  }

  highlightOAuthProvider(provider, daysSince) {
    // Find the OAuth button for this provider
    const providerButton = document.querySelector(`[data-provider="${provider}"]`)

    if (providerButton) {
      // Add visual indicator
      const container = providerButton.closest('.col-12')
      if (container) {
        const hint = document.createElement('div')
        hint.className = 'last-login-badge'
        hint.innerHTML = `<i class="bi bi-clock-history"></i> ${this.getTimeMessage(daysSince)}`

        // Insert hint after the button
        container.appendChild(hint)

        // Add highlight class to button
        providerButton.classList.add('last-used-method')
      }
    }
  }

  getTimeMessage(daysSince) {
    if (daysSince === 0) {
      return 'You signed in with this method earlier today'
    } else if (daysSince === 1) {
      return 'You signed in with this method yesterday'
    } else if (daysSince < 7) {
      return `You signed in with this method ${daysSince} days ago`
    } else if (daysSince < 30) {
      const weeks = Math.floor(daysSince / 7)
      return `You signed in with this method ${weeks} ${weeks === 1 ? 'week' : 'weeks'} ago`
    } else {
      const months = Math.floor(daysSince / 30)
      return `You signed in with this method ${months} ${months === 1 ? 'month' : 'months'} ago`
    }
  }

  clearLastLoginData() {
    localStorage.removeItem('lastLoginMethod')
    localStorage.removeItem('lastLoginTime')
  }
}
