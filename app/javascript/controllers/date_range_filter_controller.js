import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="date-range-filter"
export default class extends Controller {
  static targets = ["startDate", "endDate", "preset"]
  static values = {
    url: String
  }

  connect() {
    // Load saved date range from localStorage
    const savedRange = this.loadSavedRange()
    if (savedRange) {
      this.applyRange(savedRange.start, savedRange.end, savedRange.preset)
    }
  }

  selectPreset(event) {
    event.preventDefault()
    const preset = event.currentTarget.dataset.preset

    const { start, end } = this.getPresetDates(preset)
    this.applyRange(start, end, preset)
    this.submit()
  }

  applyRange(startDate, endDate, preset = "custom") {
    if (this.hasStartDateTarget) {
      this.startDateTarget.value = startDate
    }
    if (this.hasEndDateTarget) {
      this.endDateTarget.value = endDate
    }

    // Update active state on preset buttons
    this.presetTargets.forEach(button => {
      if (button.dataset.preset === preset) {
        button.classList.add("active")
      } else {
        button.classList.remove("active")
      }
    })

    // Save to localStorage
    this.saveRange(startDate, endDate, preset)
  }

  submit() {
    this.element.requestSubmit()
  }

  clearFilter(event) {
    event.preventDefault()

    if (this.hasStartDateTarget) {
      this.startDateTarget.value = ""
    }
    if (this.hasEndDateTarget) {
      this.endDateTarget.value = ""
    }

    // Clear localStorage
    localStorage.removeItem("dateRangeFilter")

    // Remove active state from all presets
    this.presetTargets.forEach(button => {
      button.classList.remove("active")
    })

    this.submit()
  }

  getPresetDates(preset) {
    const now = new Date()
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    let start, end

    switch(preset) {
      case "last_7_days":
        start = new Date(today)
        start.setDate(start.getDate() - 6)
        end = today
        break
      case "last_30_days":
        start = new Date(today)
        start.setDate(start.getDate() - 29)
        end = today
        break
      case "last_90_days":
        start = new Date(today)
        start.setDate(start.getDate() - 89)
        end = today
        break
      case "this_month":
        start = new Date(now.getFullYear(), now.getMonth(), 1)
        end = today
        break
      case "last_month":
        start = new Date(now.getFullYear(), now.getMonth() - 1, 1)
        end = new Date(now.getFullYear(), now.getMonth(), 0)
        break
      case "this_year":
        start = new Date(now.getFullYear(), 0, 1)
        end = today
        break
      default:
        return { start: "", end: "" }
    }

    return {
      start: this.formatDate(start),
      end: this.formatDate(end)
    }
  }

  formatDate(date) {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, "0")
    const day = String(date.getDate()).padStart(2, "0")
    return `${year}-${month}-${day}`
  }

  saveRange(start, end, preset) {
    localStorage.setItem("dateRangeFilter", JSON.stringify({
      start,
      end,
      preset
    }))
  }

  loadSavedRange() {
    const saved = localStorage.getItem("dateRangeFilter")
    return saved ? JSON.parse(saved) : null
  }
}
