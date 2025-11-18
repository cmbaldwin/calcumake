import { Controller } from "@hotwired/stimulus"

// Handles toggling between URL and text input modes in the filament import form
export default class extends Controller {
  static targets = ["urlInput", "textInput", "urlField", "textField"]

  connect() {
    // Ensure correct initial state
    this.toggleSourceType()
  }

  toggleSourceType() {
    const urlRadio = document.getElementById("source_type_url")
    const isUrlMode = urlRadio && urlRadio.checked

    if (isUrlMode) {
      // Show URL input, hide text input
      this.urlInputTarget.classList.remove("d-none")
      this.textInputTarget.classList.add("d-none")

      // Enable URL field, disable text field
      this.urlFieldTarget.disabled = false
      this.textFieldTarget.disabled = true

      // Clear text field value
      this.textFieldTarget.value = ""

      // Set the name attribute correctly
      this.urlFieldTarget.name = "source_content"
      this.textFieldTarget.name = ""
    } else {
      // Show text input, hide URL input
      this.urlInputTarget.classList.add("d-none")
      this.textInputTarget.classList.remove("d-none")

      // Enable text field, disable URL field
      this.textFieldTarget.disabled = false
      this.urlFieldTarget.disabled = true

      // Clear URL field value
      this.urlFieldTarget.value = ""

      // Set the name attribute correctly
      this.textFieldTarget.name = "source_content"
      this.urlFieldTarget.name = ""
    }
  }
}
