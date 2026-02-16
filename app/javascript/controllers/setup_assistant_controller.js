import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggleButton", "panel", "messages", "input", "sendButton", "status"]

  static values = {
    messageUrl: String,
    context: String,
    onboardingStep: String,
    guided: Boolean,
    welcome: String,
    guidedWelcome: String,
    readyHint: String,
    error: String
  }

  connect() {
    this.initialized = false
    this.defaultSendText = this.sendButtonTarget.textContent

    if (this.guidedValue && this.contextValue === "onboarding") {
      this.openPanel()
    }
  }

  toggle() {
    if (this.panelTarget.classList.contains("d-none")) {
      this.openPanel()
    } else {
      this.closePanel()
    }
  }

  openPanel() {
    this.panelTarget.classList.remove("d-none")
    this.initializeMessages()
    this.inputTarget.focus()
  }

  closePanel() {
    this.panelTarget.classList.add("d-none")
  }

  async send(event) {
    event.preventDefault()

    const message = this.inputTarget.value.trim()
    if (!message) return

    this.appendMessage("user", message)
    this.inputTarget.value = ""
    this.setStatus("")
    this.setLoading(true)

    try {
      const response = await fetch(this.messageUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: JSON.stringify({
          message: message,
          context: this.contextValue,
          onboarding_step: this.onboardingStepValue,
          conversation: this.recentConversation()
        })
      })

      const data = await response.json()
      this.appendMessage("assistant", data.message || this.errorValue)

      if (this.contextValue === "onboarding" && data.onboarding_ready) {
        this.setStatus(this.readyHintValue)
      } else if (Array.isArray(data.errors) && data.errors.length > 0) {
        this.setStatus(data.errors.join(" "))
      }
    } catch (_error) {
      this.appendMessage("assistant", this.errorValue)
    } finally {
      this.setLoading(false)
    }
  }

  initializeMessages() {
    if (this.initialized) return
    this.initialized = true

    const intro = this.guidedValue && this.contextValue === "onboarding" ? this.guidedWelcomeValue : this.welcomeValue
    this.appendMessage("assistant", intro)
  }

  appendMessage(role, content) {
    const row = document.createElement("div")
    row.className = `setup-assistant-message setup-assistant-message-${role}`
    row.dataset.role = role
    row.dataset.content = content
    row.textContent = content
    this.messagesTarget.appendChild(row)
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  recentConversation() {
    return Array.from(this.messagesTarget.querySelectorAll(".setup-assistant-message"))
      .slice(-8)
      .map((node) => ({
        role: node.dataset.role,
        content: node.dataset.content
      }))
  }

  setStatus(message) {
    this.statusTarget.textContent = message
  }

  setLoading(isLoading) {
    this.sendButtonTarget.disabled = isLoading
    this.sendButtonTarget.textContent = isLoading ? "..." : this.defaultSendText
    this.inputTarget.disabled = isLoading
  }

  csrfToken() {
    const token = document.querySelector("meta[name='csrf-token']")
    return token ? token.content : ""
  }
}
