import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="pwa-install"
export default class extends Controller {
  static targets = ["button"]

  connect() {
    // Listen for the beforeinstallprompt event
    window.addEventListener('beforeinstallprompt', (e) => {
      // Prevent the mini-infobar from appearing on mobile
      e.preventDefault()
      // Stash the event so it can be triggered later
      this.deferredPrompt = e
      // Show the install button
      if (this.hasButtonTarget) {
        this.buttonTarget.style.display = 'block'
      }
    })

    // Hide button if already installed
    if (window.matchMedia('(display-mode: standalone)').matches) {
      if (this.hasButtonTarget) {
        this.buttonTarget.style.display = 'none'
      }
    }

    // Listen for successful installation
    window.addEventListener('appinstalled', () => {
      console.log('CalcuMake has been installed')
      if (this.hasButtonTarget) {
        this.buttonTarget.style.display = 'none'
      }
      this.deferredPrompt = null
    })
  }

  install() {
    if (!this.deferredPrompt) {
      return
    }

    // Show the install prompt
    this.deferredPrompt.prompt()

    // Wait for the user to respond to the prompt
    this.deferredPrompt.userChoice.then((choiceResult) => {
      if (choiceResult.outcome === 'accepted') {
        console.log('User accepted the install prompt')
      } else {
        console.log('User dismissed the install prompt')
      }
      this.deferredPrompt = null
    })
  }
}
