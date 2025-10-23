import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "placeholder", "progress", "error"]
  static values = { maxSize: Number }

  connect() {
    this.maxSizeValue = this.maxSizeValue || 5 * 1024 * 1024 // 5MB default
  }

  change(event) {
    const file = event.target.files[0]
    this.clearError()

    if (!file) {
      this.hidePreview()
      return
    }

    if (!this.isValidFile(file)) {
      return
    }

    this.showPreview(file)
  }

  drop(event) {
    event.preventDefault()
    event.stopPropagation()

    const file = event.dataTransfer.files[0]
    if (!file) return

    this.clearError()

    if (!this.isValidFile(file)) {
      return
    }

    // Update the file input
    const dataTransfer = new DataTransfer()
    dataTransfer.items.add(file)
    this.inputTarget.files = dataTransfer.files

    this.showPreview(file)
  }

  dragover(event) {
    event.preventDefault()
    event.stopPropagation()
    this.element.classList.add("drag-over")
  }

  dragleave(event) {
    event.preventDefault()
    event.stopPropagation()
    this.element.classList.remove("drag-over")
  }

  remove(event) {
    event.preventDefault()
    this.inputTarget.value = ""
    this.hidePreview()
    this.clearError()
  }

  isValidFile(file) {
    // Check file type - only allow specific image formats
    const allowedTypes = ['image/png', 'image/jpg', 'image/jpeg', 'image/gif', 'image/webp']
    if (!allowedTypes.includes(file.type)) {
      this.showError("Please select a PNG, JPG, GIF, or WebP image file")
      return false
    }

    // Check file size
    if (file.size > this.maxSizeValue) {
      const maxSizeMB = Math.round(this.maxSizeValue / (1024 * 1024))
      this.showError(`File size must be less than ${maxSizeMB}MB`)
      return false
    }

    return true
  }

  showPreview(file) {
    const reader = new FileReader()
    reader.onload = (e) => {
      if (this.hasPreviewTarget) {
        this.previewTarget.src = e.target.result
        this.previewTarget.style.display = "block"
      }
      if (this.hasPlaceholderTarget) {
        this.placeholderTarget.style.display = "none"
      }
    }
    reader.readAsDataURL(file)
  }

  hidePreview() {
    if (this.hasPreviewTarget) {
      this.previewTarget.style.display = "none"
    }
    if (this.hasPlaceholderTarget) {
      this.placeholderTarget.style.display = "block"
    }
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.style.display = "block"
    }
  }

  clearError() {
    if (this.hasErrorTarget) {
      this.errorTarget.style.display = "none"
    }
  }
}