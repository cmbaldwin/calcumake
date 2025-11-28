import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="pwa-registration"
export default class extends Controller {
  static values = { serviceWorkerPath: String }

  connect() {
    this.registerServiceWorker()
  }

  registerServiceWorker() {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register(this.serviceWorkerPathValue)
        .then((registration) => {
          // console.log('Service Worker registered with scope:', registration.scope)
        })
        .catch((error) => {
          // console.error('Service Worker registration failed:', error)
        })
    }
  }
}