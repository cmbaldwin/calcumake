import { Controller } from "@hotwired/stimulus"

// Handles AI chat input on the minimal landing page.
// Sends messages to /ai-chat and renders responses inline.
export default class extends Controller {
  static targets = ["form", "input", "submitButton", "response"]
  static values = { url: String }

  async submit(event) {
    event.preventDefault()

    const message = this.inputTarget.value.trim()
    if (!message) return

    this.setLoading(true)
    this.showThinking()

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')
      const headers = {
        "Content-Type": "application/json",
        "Accept": "application/json"
      }
      if (csrfToken) {
        headers["X-CSRF-Token"] = csrfToken.content
      }

      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: headers,
        body: JSON.stringify({ message: message })
      })

      const data = await response.json()

      if (response.ok) {
        this.showResponseContent(this.formatMarkdown(data.response))
        this.inputTarget.value = ""
      } else {
        this.showResponseContent(
          `<p class="chat-error">${data.error || "Something went wrong."}</p>`
        )
      }
    } catch (e) {
      this.showResponseContent(
        '<p class="chat-error">Connection error. Please try again.</p>'
      )
    } finally {
      this.setLoading(false)
    }
  }

  setLoading(loading) {
    this.submitButtonTarget.disabled = loading
    this.inputTarget.disabled = loading
  }

  showThinking() {
    this.responseTarget.style.display = "block"
    this.responseTarget.innerHTML = `
      <div class="thinking-dots">
        <span></span><span></span><span></span>
      </div>
    `
  }

  showResponseContent(html) {
    this.responseTarget.style.display = "block"
    this.responseTarget.innerHTML = html
  }

  // Basic markdown to HTML (bold, code, paragraphs, line breaks)
  formatMarkdown(text) {
    if (!text) return ""

    return text
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>")
      .replace(/`(.+?)`/g, "<code>$1</code>")
      .replace(/\n\n/g, "</p><p>")
      .replace(/\n/g, "<br>")
      .replace(/^(.+)$/, "<p>$1</p>")
  }
}
