import { Controller } from "@hotwired/stimulus"

// Handles STL/3MF file upload on the minimal landing page.
// Parses STL files client-side using Three.js STLLoader.
export default class extends Controller {
  static targets = ["dropZone", "fileInput", "results", "fileName", "resultsGrid"]

  static values = {
    maxSizeMb: { type: Number, default: 50 }
  }

  fileSelected(event) {
    const file = event.target.files[0]
    if (file) this.processFile(file)
  }

  dragover(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "copy"
    this.dropZoneTarget.classList.add("drag-over")
  }

  dragleave(event) {
    event.preventDefault()
    this.dropZoneTarget.classList.remove("drag-over")
  }

  drop(event) {
    event.preventDefault()
    this.dropZoneTarget.classList.remove("drag-over")

    const file = event.dataTransfer.files[0]
    if (file) {
      // Sync file input
      const dt = new DataTransfer()
      dt.items.add(file)
      this.fileInputTarget.files = dt.files
      this.processFile(file)
    }
  }

  async processFile(file) {
    // Validate file type
    const ext = file.name.split(".").pop().toLowerCase()
    if (!["stl", "3mf"].includes(ext)) {
      this.showError("Please upload an STL or 3MF file.")
      return
    }

    // Validate file size
    const maxBytes = this.maxSizeMbValue * 1024 * 1024
    if (file.size > maxBytes) {
      this.showError(`File too large. Maximum size is ${this.maxSizeMbValue}MB.`)
      return
    }

    if (ext === "stl") {
      await this.processSTL(file)
    } else {
      this.process3MF(file)
    }
  }

  async processSTL(file) {
    this.showProcessing(file.name)

    try {
      const THREE = await import("three")
      const { STLLoader } = await import("three/addons/loaders/STLLoader")

      const loader = new STLLoader()
      const arrayBuffer = await file.arrayBuffer()
      const geometry = loader.parse(arrayBuffer)

      geometry.computeBoundingBox()
      const box = geometry.boundingBox
      const size = new THREE.Vector3()
      box.getSize(size)

      const triangleCount = geometry.attributes.position.count / 3

      // Rough volume and weight estimation
      // Using bounding box volume * ~30% fill factor as rough approximation
      const bbVolumeMm3 = size.x * size.y * size.z
      const bbVolumeCm3 = bbVolumeMm3 / 1000
      // Assume ~20% of bounding box is actual model, ~20% infill => ~4% of BB is material
      const estimatedWeightG = bbVolumeCm3 * 1.24 * 0.04 // PLA density * fill estimate

      const results = [
        { label: "Dimensions", value: `${size.x.toFixed(1)} x ${size.y.toFixed(1)} x ${size.z.toFixed(1)} mm` },
        { label: "Triangles", value: triangleCount.toLocaleString() },
        { label: "Est. Weight", value: `~${Math.max(estimatedWeightG, 1).toFixed(1)}g (PLA)` },
        { label: "Est. Cost", value: `~$${(Math.max(estimatedWeightG, 1) / 1000 * 25).toFixed(2)}` }
      ]

      this.showResults(file.name, results)
    } catch (e) {
      console.error("STL parse error:", e)
      this.showError("Could not parse STL file. Try the full calculator.")
    }
  }

  process3MF(file) {
    // 3MF requires server-side ZIP parsing
    this.showResults(file.name, [
      { label: "Format", value: "3MF (compressed)" },
      { label: "File Size", value: this.formatFileSize(file.size) },
      { label: "Note", value: "Use full calculator for 3MF analysis" }
    ])
  }

  showProcessing(fileName) {
    this.fileNameTarget.textContent = fileName
    this.resultsGridTarget.innerHTML = `
      <div class="result-item" style="grid-column: span 2; text-align: center;">
        <div class="thinking-dots">
          <span></span><span></span><span></span>
        </div>
      </div>
    `
    this.resultsTarget.style.display = "block"
  }

  showResults(fileName, results) {
    this.fileNameTarget.textContent = fileName
    this.resultsGridTarget.innerHTML = results.map(r => `
      <div class="result-item">
        <div class="result-label">${this.escapeHtml(r.label)}</div>
        <div class="result-value">${this.escapeHtml(r.value)}</div>
      </div>
    `).join("")
    this.resultsTarget.style.display = "block"
  }

  showError(message) {
    this.fileNameTarget.textContent = "Error"
    this.resultsGridTarget.innerHTML = `
      <div class="result-item" style="grid-column: span 2;">
        <div class="result-value chat-error">${this.escapeHtml(message)}</div>
      </div>
    `
    this.resultsTarget.style.display = "block"
  }

  formatFileSize(bytes) {
    if (bytes < 1024) return bytes + " B"
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB"
    return (bytes / (1024 * 1024)).toFixed(1) + " MB"
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
