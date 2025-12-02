// Storage Mixin - LocalStorage persistence
// Following Better Stimulus pattern: https://betterstimulus.com/architecture/mixins
export const useStorage = controller => {
  Object.assign(controller, {
    setupAutoSave() {
      // Auto-save to localStorage every 10 seconds
      this.autoSaveInterval = setInterval(() => {
        this.saveToStorage()
      }, 10000)
    },

    saveToStorage() {
      const data = {
        jobName: this.hasJobNameTarget ? this.jobNameTarget.value : '',
        plates: this.getPlates().map(plate => this.getPlateDataForStorage(plate)),
        failureRate: parseFloat(this.element.querySelector('[name="failure_rate"]')?.value || 0),
        shippingCost: parseFloat(this.element.querySelector('[name="shipping_cost"]')?.value || 0),
        otherCost: parseFloat(this.element.querySelector('[name="other_cost"]')?.value || 0),
        units: parseInt(this.element.querySelector('[name="units"]')?.value || 1),
        timestamp: new Date().toISOString()
      }

      try {
        localStorage.setItem('calcumake_advanced_calculator', JSON.stringify(data))
      } catch (e) {
        console.error("Failed to save to localStorage:", e)
      }
    },

    loadFromStorage() {
      try {
        const saved = localStorage.getItem('calcumake_advanced_calculator')
        if (!saved) return

        const data = JSON.parse(saved)

        // Restore job name
        if (this.hasJobNameTarget && data.jobName) {
          this.jobNameTarget.value = data.jobName
        }

        // Restore other fields
        if (data.failureRate !== undefined) {
          const failureField = this.element.querySelector('[name="failure_rate"]')
          if (failureField) failureField.value = data.failureRate
        }
        if (data.shippingCost !== undefined) {
          const shippingField = this.element.querySelector('[name="shipping_cost"]')
          if (shippingField) shippingField.value = data.shippingCost
        }
        if (data.otherCost !== undefined) {
          const otherField = this.element.querySelector('[name="other_cost"]')
          if (otherField) otherField.value = data.otherCost
        }
        if (data.units !== undefined) {
          const unitsField = this.element.querySelector('[name="units"]')
          if (unitsField) unitsField.value = data.units
        }

        // Note: Plates will be restored after they're added in connect()
        // This is a simplified version - full implementation would restore all plate data

      } catch (e) {
        console.error("Failed to load from localStorage:", e)
      }
    },

    getPlateDataForStorage(plateDiv) {
      const plateData = this.getPlateData(plateDiv)
      return {
        ...plateData,
        filaments: plateData.filaments
      }
    },

    clearStorage() {
      if (confirm("Are you sure you want to clear all saved data?")) {
        localStorage.removeItem('calcumake_advanced_calculator')
        window.location.reload()
      }
    }
  })
}
