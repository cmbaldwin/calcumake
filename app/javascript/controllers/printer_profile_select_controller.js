import { Controller } from "@hotwired/stimulus"

// Searchable printer profile dropdown with form auto-population
// Connects to data-controller="printer-profile-select"
export default class extends Controller {
  static targets = ["input", "dropdown", "list", "clear"]
  static values = {
    profiles: Array,
    placeholder: { type: String, default: "Search printers..." }
  }

  connect() {
    this.selectedIndex = -1
    this.filteredProfiles = this.profilesValue
    this.isOpen = false

    // Close dropdown when clicking outside
    this.boundClickOutside = this.clickOutside.bind(this)
    document.addEventListener("click", this.boundClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
  }

  // Handle input changes with debouncing
  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()

    if (query === "") {
      this.filteredProfiles = this.profilesValue
    } else {
      this.filteredProfiles = this.profilesValue.filter(p =>
        p.display_name.toLowerCase().includes(query) ||
        p.manufacturer.toLowerCase().includes(query) ||
        (p.category && p.category.toLowerCase().includes(query))
      )
    }

    this.selectedIndex = -1
    this.renderList()
    this.showDropdown()
    this.updateClearButton()
  }

  // Select a profile from the dropdown
  select(event) {
    event.preventDefault()
    const profileId = event.currentTarget.dataset.profileId
    const profile = this.profilesValue.find(p => p.id == profileId)

    if (profile) {
      this.inputTarget.value = profile.display_name
      this.hideDropdown()
      this.updateClearButton()

      // Dispatch event for form auto-population
      this.dispatch("selected", { detail: { profile } })
    }
  }

  // Clear the selection
  clear() {
    this.inputTarget.value = ""
    this.filteredProfiles = this.profilesValue
    this.renderList()
    this.updateClearButton()
    this.inputTarget.focus()

    // Dispatch clear event
    this.dispatch("cleared")
  }

  // Keyboard navigation
  keydown(event) {
    if (!this.isOpen) {
      if (event.key === "ArrowDown" || event.key === "Enter") {
        this.showDropdown()
        event.preventDefault()
      }
      return
    }

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.moveSelection(1)
        break
      case "ArrowUp":
        event.preventDefault()
        this.moveSelection(-1)
        break
      case "Enter":
        event.preventDefault()
        this.selectCurrentItem()
        break
      case "Escape":
        this.hideDropdown()
        break
    }
  }

  // Move selection up or down
  moveSelection(direction) {
    const items = this.listTarget.querySelectorAll(".dropdown-item")
    if (items.length === 0) return

    this.selectedIndex = Math.max(
      -1,
      Math.min(this.selectedIndex + direction, items.length - 1)
    )

    items.forEach((item, index) => {
      item.classList.toggle("active", index === this.selectedIndex)
    })

    if (this.selectedIndex >= 0 && items[this.selectedIndex]) {
      items[this.selectedIndex].scrollIntoView({ block: "nearest" })
    }
  }

  // Select the currently highlighted item
  selectCurrentItem() {
    const items = this.listTarget.querySelectorAll(".dropdown-item")
    if (this.selectedIndex >= 0 && items[this.selectedIndex]) {
      items[this.selectedIndex].click()
    }
  }

  // Render the filtered list
  renderList() {
    if (this.filteredProfiles.length === 0) {
      this.listTarget.innerHTML = `
        <div class="dropdown-item-text text-muted py-2 px-3">
          No printers found
        </div>
      `
      return
    }

    // Group profiles by category
    const grouped = this.groupByCategory(this.filteredProfiles)
    let html = ""

    for (const [category, profiles] of Object.entries(grouped)) {
      if (category && category !== "null") {
        html += `<h6 class="dropdown-header">${category}</h6>`
      }

      for (const profile of profiles) {
        html += `
          <a href="#" class="dropdown-item"
             data-action="click->printer-profile-select#select"
             data-profile-id="${profile.id}">
            <div class="fw-medium">${this.escapeHtml(profile.display_name)}</div>
            <small class="text-muted">
              ${profile.power_consumption_avg_watts ? `${profile.power_consumption_avg_watts}W` : ""}
              ${profile.cost_usd ? ` / $${profile.cost_usd}` : ""}
            </small>
          </a>
        `
      }
    }

    this.listTarget.innerHTML = html
  }

  // Group profiles by category
  groupByCategory(profiles) {
    return profiles.reduce((groups, profile) => {
      const category = profile.category || "Other"
      if (!groups[category]) {
        groups[category] = []
      }
      groups[category].push(profile)
      return groups
    }, {})
  }

  // Show the dropdown
  showDropdown() {
    if (this.filteredProfiles.length > 0 || this.inputTarget.value.trim() !== "") {
      this.dropdownTarget.classList.add("show")
      this.isOpen = true
    }
  }

  // Hide the dropdown
  hideDropdown() {
    this.dropdownTarget.classList.remove("show")
    this.isOpen = false
    this.selectedIndex = -1
  }

  // Handle focus
  focus() {
    this.renderList()
    this.showDropdown()
  }

  // Handle blur - delay to allow click events
  blur() {
    setTimeout(() => {
      this.hideDropdown()
    }, 200)
  }

  // Click outside handler
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideDropdown()
    }
  }

  // Update clear button visibility
  updateClearButton() {
    if (this.hasClearTarget) {
      this.clearTarget.classList.toggle("d-none", this.inputTarget.value === "")
    }
  }

  // Escape HTML to prevent XSS
  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
