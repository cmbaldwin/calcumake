import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["banner"]
  static values = {
    consentUrl: String,
    accepted: Boolean
  }

  connect() {
    // Check if user has already made a choice
    const cookieConsent = this.getCookie("cookie_consent")

    if (!cookieConsent && !this.acceptedValue) {
      this.showBanner()
    }
  }

  showBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.remove("d-none")
      this.bannerTarget.classList.add("show")
    }
  }

  hideBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.remove("show")
      this.bannerTarget.classList.add("d-none")
    }
  }

  accept(event) {
    event.preventDefault()
    this.recordConsent(true)
  }

  reject(event) {
    event.preventDefault()
    this.recordConsent(false)
  }

  recordConsent(accepted) {
    // Set cookie for non-authenticated users
    this.setCookie("cookie_consent", accepted ? "accepted" : "rejected", 365)

    // Send to server if user is authenticated and URL is present
    if (this.hasConsentUrlValue && this.consentUrlValue !== '') {
      const csrfToken = document.querySelector("[name='csrf-token']").content

      fetch(this.consentUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          consent_type: "cookies",
          accepted: accepted
        })
      }).then(response => {
        if (response.ok) {
          this.hideBanner()
        }
      }).catch(error => {
        console.error("Error recording consent:", error)
        // Still hide banner even if server request fails
        this.hideBanner()
      })
    } else {
      // No URL means not authenticated - just hide the banner
      this.hideBanner()
    }
  }

  getCookie(name) {
    const value = `; ${document.cookie}`
    const parts = value.split(`; ${name}=`)
    if (parts.length === 2) return parts.pop().split(";").shift()
  }

  setCookie(name, value, days) {
    const expires = new Date()
    expires.setTime(expires.getTime() + days * 24 * 60 * 60 * 1000)
    document.cookie = `${name}=${value};expires=${expires.toUTCString()};path=/;SameSite=Lax`
  }
}
