import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tokenDisplay", "copyButton", "revealSection"]
  static values = { revealed: Boolean }

  connect() {
    // Token display auto-hides after 60 seconds for security
    if (this.revealedValue) {
      this.startAutoHideTimer()
    }
  }

  startAutoHideTimer() {
    this.timeout = setTimeout(() => {
      this.hideToken()
    }, 60000) // 60 seconds
  }

  hideToken() {
    if (this.hasRevealSectionTarget) {
      this.revealSectionTarget.innerHTML = `
        <div class="alert alert-warning mb-0">
          <i class="bi bi-shield-lock me-2"></i>
          Token hidden for security. This token cannot be revealed again.
        </div>
      `
    }
  }

  async copy() {
    if (!this.hasTokenDisplayTarget) return

    const token = this.tokenDisplayTarget.textContent.trim()

    try {
      await navigator.clipboard.writeText(token)
      this.showCopySuccess()
    } catch (err) {
      this.showCopyFallback(token)
    }
  }

  showCopySuccess() {
    if (!this.hasCopyButtonTarget) return

    const originalHTML = this.copyButtonTarget.innerHTML
    this.copyButtonTarget.innerHTML = '<i class="bi bi-check"></i> Copied!'
    this.copyButtonTarget.classList.add("btn-success")
    this.copyButtonTarget.classList.remove("btn-outline-primary")

    setTimeout(() => {
      this.copyButtonTarget.innerHTML = originalHTML
      this.copyButtonTarget.classList.remove("btn-success")
      this.copyButtonTarget.classList.add("btn-outline-primary")
    }, 2000)
  }

  showCopyFallback(token) {
    // Fallback for browsers without clipboard API
    const textArea = document.createElement("textarea")
    textArea.value = token
    textArea.style.position = "fixed"
    textArea.style.opacity = "0"
    document.body.appendChild(textArea)
    textArea.select()
    document.execCommand("copy")
    document.body.removeChild(textArea)
    this.showCopySuccess()
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }
}
