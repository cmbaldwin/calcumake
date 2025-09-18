import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  submit(event) {
    event.preventDefault()
    const form = event.target.closest("form")

    fetch(form.action, {
      method: form.method,
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      },
      body: new FormData(form)
    })
    .then(response => response.text())
    .then(html => {
      // Let Turbo process the stream
      Turbo.renderStreamMessage(html)
    })
  }
}