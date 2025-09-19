import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    autoDismiss: Number
  }

  connect() {
    console.log("🍞 Toast controller connected!")
    console.log("Toast element:", this.element)
    console.log("Auto dismiss value:", this.autoDismissValue)
    console.log("Has auto dismiss value:", this.hasAutoDismissValue)

    if (this.hasAutoDismissValue && this.autoDismissValue > 0) {
      console.log("Scheduling auto dismiss in", this.autoDismissValue, "ms")
      this.scheduleAutoDismiss()
    }
  }

  scheduleAutoDismiss() {
    const delay = this.autoDismissValue || 5000

    setTimeout(() => {
      this.dismiss()
    }, delay)
  }

  dismiss() {
    if (this.element.parentElement) {
      const animation = window.innerWidth <= 768 ? 'toastFadeOut' : 'toastSlideOut'
      this.element.style.animation = `${animation} 0.3s ease-out forwards`

      setTimeout(() => {
        if (this.element.parentElement) {
          this.element.remove()
        }
      }, 300)
    }
  }

  close() {
    this.dismiss()
  }
}