import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="three-mf-upload"
export default class extends Controller {
  handleFileSelect(event) {
    const file = event.target.files[0]

    if (!file) {
      return
    }

    // Validate file extension
    if (!file.name.toLowerCase().endsWith('.3mf')) {
      alert('Please select a valid 3MF file')
      event.target.value = ''
      return
    }

    // Validate file size (e.g., max 100MB)
    const maxSize = 100 * 1024 * 1024 // 100MB
    if (file.size > maxSize) {
      alert('File is too large. Maximum size is 100MB')
      event.target.value = ''
      return
    }

    // Show file info to user
    console.log('Selected 3MF file:', file.name, 'Size:', this.formatFileSize(file.size))
  }

  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
  }
}
