import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="pwa-registration"
export default class extends Controller {
  connect() {
    this.registerServiceWorker()
  }

  registerServiceWorker() {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register(this.data.get("serviceWorkerPath"))
        .then((registration) => {
          console.log('Service Worker registered with scope:', registration.scope)
        })
        .catch((error) => {
          console.error('Service Worker registration failed:', error)
        })
    }
  }
}