// Storage Mixin - LocalStorage persistence
export const StorageMixin = {
  setupAutoSave() {
    // Auto-save is now disabled - was causing page freezes
    // Data is saved on blur events instead
    // Keep method for compatibility but do nothing
  },

  saveToStorage() {
    // Guard against being called when controller is disconnected
    if (!this.element || !this.element.isConnected) return

    try {
      const plates = this.getPlates()
      if (!plates || plates.length === 0) return

      const data = {
        jobName: this.hasJobNameTarget ? this.jobNameTarget.value : '',
        plates: plates.map(plate => this.getPlateDataForStorage(plate)).filter(Boolean),
        // Global settings
        globalSettings: this.getGlobalSettings(),
        // Other costs
        failureRate: parseFloat(this.element.querySelector('[name="failure_rate"]')?.value || 0),
        shippingCost: parseFloat(this.element.querySelector('[name="shipping_cost"]')?.value || 0),
        otherCost: parseFloat(this.element.querySelector('[name="other_cost"]')?.value || 0),
        units: parseInt(this.element.querySelector('[name="units"]')?.value || 1),
        timestamp: new Date().toISOString()
      }

      localStorage.setItem('calcumake_advanced_calculator', JSON.stringify(data))
    } catch (e) {
      console.error("Failed to save to localStorage:", e)
    }
  },

  // Called on blur to save data
  saveOnBlur() {
    this.saveToStorage()
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

      // Restore global settings
      if (data.globalSettings) {
        const gs = data.globalSettings
        if (this.hasPowerConsumptionTarget && gs.powerConsumption !== undefined) {
          this.powerConsumptionTarget.value = gs.powerConsumption
        }
        if (this.hasMachineCostTarget && gs.machineCost !== undefined) {
          this.machineCostTarget.value = gs.machineCost
        }
        if (this.hasPayoffYearsTarget && gs.payoffYears !== undefined) {
          this.payoffYearsTarget.value = gs.payoffYears
        }
        if (this.hasPrepTimeTarget && gs.prepTime !== undefined) {
          this.prepTimeTarget.value = gs.prepTime
        }
        if (this.hasPostTimeTarget && gs.postTime !== undefined) {
          this.postTimeTarget.value = gs.postTime
        }
        if (this.hasPrepRateTarget && gs.prepRate !== undefined) {
          this.prepRateTarget.value = gs.prepRate
        }
        if (this.hasPostRateTarget && gs.postRate !== undefined) {
          this.postRateTarget.value = gs.postRate
        }
      }

      // Note: Plates will be restored after they're added in connect()
      // This is a simplified version - full implementation would restore all plate data

    } catch (e) {
      console.error("Failed to load from localStorage:", e)
    }
  },

  getPlateDataForStorage(plateDiv) {
    if (!plateDiv) return null
    try {
      const plateData = this.getPlateData(plateDiv)
      if (!plateData) return null
      return {
        ...plateData,
        filaments: plateData.filaments || []
      }
    } catch (e) {
      console.error("Failed to get plate data for storage:", e)
      return null
    }
  },

  clearStorage() {
    if (confirm("Are you sure you want to clear all saved data?")) {
      localStorage.removeItem('calcumake_advanced_calculator')
      window.location.reload()
    }
  }
}
