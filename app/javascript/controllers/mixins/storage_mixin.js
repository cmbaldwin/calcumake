// Storage Mixin - LocalStorage persistence with multiple saved calculations
// Following Better Stimulus pattern: https://betterstimulus.com/architecture/mixins
export const useStorage = controller => {
  Object.assign(controller, {
    // Get the current calculation ID from selector or default
    getCurrentCalculationId() {
      return this._currentCalculationId || 'default'
    },

    setCurrentCalculationId(id) {
      this._currentCalculationId = id
    },

    setupAutoSave() {
      // Auto-save to localStorage every 10 seconds
      this.autoSaveInterval = setInterval(() => {
        this.saveToStorage()
      }, 10000)
    },

    // Get all saved calculations from localStorage
    getAllSavedCalculations() {
      try {
        const saved = localStorage.getItem('calcumake_calculations')
        return saved ? JSON.parse(saved) : {}
      } catch (e) {
        console.error("Failed to load calculations from localStorage:", e)
        return {}
      }
    },

    // Save current calculation to localStorage
    saveToStorage(calculationName = null) {
      const calculationId = calculationName || this.getCurrentCalculationId()

      const data = {
        id: calculationId,
        name: this.hasJobNameTarget ? this.jobNameTarget.value : calculationId,
        jobName: this.hasJobNameTarget ? this.jobNameTarget.value : '',
        plates: this.getPlates().map(plate => this.getPlateDataForStorage(plate)),
        globalSettings: this.getGlobalSettings(),
        failureRate: parseFloat(this.element.querySelector('[name="failure_rate"]')?.value || 0),
        shippingCost: parseFloat(this.element.querySelector('[name="shipping_cost"]')?.value || 0),
        otherCost: parseFloat(this.element.querySelector('[name="other_cost"]')?.value || 0),
        units: parseInt(this.element.querySelector('[name="units"]')?.value || 1),
        timestamp: new Date().toISOString()
      }

      try {
        const allCalculations = this.getAllSavedCalculations()
        allCalculations[calculationId] = data
        localStorage.setItem('calcumake_calculations', JSON.stringify(allCalculations))

        // Dispatch event to update selector UI
        this.element.dispatchEvent(new CustomEvent('calculation-saved', {
          detail: { id: calculationId, name: data.name },
          bubbles: true
        }))
      } catch (e) {
        console.error("Failed to save to localStorage:", e)
      }
    },

    // Save current calculation with a new name
    saveCalculationAs(event) {
      if (event) event.preventDefault()

      // Use the job name from the form instead of prompting
      const name = this.hasJobNameTarget && this.jobNameTarget.value
        ? this.jobNameTarget.value
        : 'Untitled Calculation'

      const calculationId = this.generateCalculationId(name)
      this.setCurrentCalculationId(calculationId)
      this.saveToStorage(calculationId)

      // Update selector
      this.updateCalculationSelector()

      // Show confirmation
      const notification = document.createElement('div')
      notification.className = 'alert alert-success alert-dismissible fade show position-fixed top-0 start-50 translate-middle-x mt-3'
      notification.style.zIndex = '9999'
      notification.innerHTML = `
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        <i class="bi bi-check-circle me-2"></i>
        Saved as "${name}"
      `
      document.body.appendChild(notification)

      setTimeout(() => {
        notification.remove()
      }, 2000)
    },

    // Load a specific calculation by ID
    loadCalculation(calculationId) {
      try {
        const allCalculations = this.getAllSavedCalculations()
        const data = allCalculations[calculationId]

        if (!data) {
          console.warn(`Calculation ${calculationId} not found`)
          return false
        }

        this.setCurrentCalculationId(calculationId)

        // Restore job name
        if (this.hasJobNameTarget && data.jobName) {
          this.jobNameTarget.value = data.jobName
        }

        // Restore global settings
        if (data.globalSettings) {
          this.restoreGlobalSettings(data.globalSettings)
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

        // Restore plates
        if (data.plates && data.plates.length > 0) {
          this.restorePlates(data.plates)
        }

        // Recalculate
        this.calculate()

        return true
      } catch (e) {
        console.error("Failed to load calculation:", e)
        return false
      }
    },

    // Load from storage (default calculation or last used)
    loadFromStorage() {
      try {
        // First check if there's a legacy single calculation
        const legacySaved = localStorage.getItem('calcumake_advanced_calculator')
        if (legacySaved) {
          // Migrate legacy data to new format
          this.migrateLegacyData(legacySaved)
          localStorage.removeItem('calcumake_advanced_calculator')
        }

        // Load the default or last-used calculation
        const calculationId = this.getCurrentCalculationId()
        this.loadCalculation(calculationId)

        // Update calculation selector UI
        this.updateCalculationSelector()

      } catch (e) {
        console.error("Failed to load from localStorage:", e)
      }
    },

    // Migrate legacy single calculation to new multi-calculation format
    migrateLegacyData(legacyJson) {
      try {
        const legacyData = JSON.parse(legacyJson)
        const allCalculations = this.getAllSavedCalculations()

        allCalculations['default'] = {
          id: 'default',
          name: legacyData.jobName || 'Default Calculation',
          ...legacyData
        }

        localStorage.setItem('calcumake_calculations', JSON.stringify(allCalculations))
      } catch (e) {
        console.error("Failed to migrate legacy data:", e)
      }
    },

    // Restore global machine/labor settings
    restoreGlobalSettings(settings) {
      const fields = {
        powerConsumption: 'power_consumption',
        machineCost: 'machine_cost',
        payoffYears: 'payoff_years',
        prepTime: 'prep_time',
        postTime: 'post_time',
        prepRate: 'prep_rate',
        postRate: 'post_rate'
      }

      Object.entries(fields).forEach(([key, fieldName]) => {
        if (settings[key] !== undefined) {
          const field = this.element.querySelector(`[name="${fieldName}"]`)
          if (field) field.value = settings[key]
        }
      })
    },

    // Restore plates from saved data
    restorePlates(platesData) {
      // Clear existing plates except the first one
      const existingPlates = this.getPlates()
      existingPlates.slice(1).forEach(plate => plate.remove())

      // Restore each plate
      platesData.forEach((plateData, index) => {
        let plateDiv

        if (index === 0) {
          // Use the first existing plate
          plateDiv = existingPlates[0]
        } else {
          // Add a new plate
          this.addPlate()
          const plates = this.getPlates()
          plateDiv = plates[plates.length - 1]
        }

        // Restore plate data
        this.restorePlateData(plateDiv, plateData)
      })
    },

    // Restore individual plate data
    restorePlateData(plateDiv, plateData) {
      // Restore print time
      const printTimeField = plateDiv.querySelector('[name*="print_time"]')
      if (printTimeField && plateData.printTime !== undefined) {
        printTimeField.value = plateData.printTime
      }

      // Restore filaments
      if (plateData.filaments && plateData.filaments.length > 0) {
        const filamentsContainer = plateDiv.querySelector('[data-filaments-container]')
        const existingFilaments = filamentsContainer.querySelectorAll('[data-filament-index]')

        // Clear existing filaments except the first one
        Array.from(existingFilaments).slice(1).forEach(fil => fil.remove())

        // Restore each filament
        plateData.filaments.forEach((filamentData, filIndex) => {
          let filamentDiv

          if (filIndex === 0) {
            // Use the first existing filament
            filamentDiv = existingFilaments[0]
          } else {
            // Add a new filament
            this.addFilamentToPlate(plateDiv)
            const filaments = filamentsContainer.querySelectorAll('[data-filament-index]')
            filamentDiv = filaments[filaments.length - 1]
          }

          // Restore filament data
          const weightField = filamentDiv.querySelector('[name*="filament_weight"]')
          const priceField = filamentDiv.querySelector('[name*="filament_price"]')

          if (weightField && filamentData.weight !== undefined) {
            weightField.value = filamentData.weight
          }
          if (priceField && filamentData.pricePerKg !== undefined) {
            priceField.value = filamentData.pricePerKg
          }
        })
      }
    },

    getPlateDataForStorage(plateDiv) {
      const plateData = this.getPlateData(plateDiv)
      return {
        ...plateData,
        filaments: plateData.filaments
      }
    },

    // Generate a unique calculation ID from name
    generateCalculationId(name) {
      const timestamp = Date.now()
      const sanitized = name.toLowerCase().replace(/[^a-z0-9]/g, '_')
      return `${sanitized}_${timestamp}`
    },

    // Update the calculation selector dropdown
    updateCalculationSelector() {
      const selector = this.element.querySelector('[data-calculation-selector]')
      if (!selector) return

      const allCalculations = this.getAllSavedCalculations()
      const currentId = this.getCurrentCalculationId()

      // Clear existing options
      selector.innerHTML = ''

      // Add calculations as options
      Object.values(allCalculations).forEach(calc => {
        const option = document.createElement('option')
        option.value = calc.id
        option.textContent = calc.name || calc.id
        option.selected = calc.id === currentId
        selector.appendChild(option)
      })

      // If no calculations exist, add a default option
      if (Object.keys(allCalculations).length === 0) {
        const option = document.createElement('option')
        option.value = 'default'
        option.textContent = 'Default Calculation'
        option.selected = true
        selector.appendChild(option)
      }
    },

    // Switch to a different calculation
    switchCalculation(event) {
      const selector = event.target
      const calculationId = selector.value

      if (calculationId) {
        this.loadCalculation(calculationId)
      }
    },

    // Delete a calculation
    deleteCalculation(event) {
      if (event) event.preventDefault()

      const currentId = this.getCurrentCalculationId()
      const allCalculations = this.getAllSavedCalculations()
      const currentCalc = allCalculations[currentId]

      if (!currentCalc) {
        alert("No calculation to delete.")
        return
      }

      const calcName = currentCalc.name || currentId

      if (!confirm(`Are you sure you want to delete "${calcName}"?`)) {
        return
      }

      try {
        delete allCalculations[currentId]
        localStorage.setItem('calcumake_calculations', JSON.stringify(allCalculations))

        // Reset the form to a fresh state
        window.location.reload()
      } catch (e) {
        console.error("Failed to delete calculation:", e)
      }
    },

    // Reset current calculation to defaults
    resetCalculation() {
      if (confirm("Are you sure you want to reset the calculator? All unsaved data will be lost.")) {
        window.location.reload()
      }
    },

    // Clear all saved calculations
    clearStorage() {
      if (confirm("Are you sure you want to clear ALL saved calculations? This cannot be undone.")) {
        localStorage.removeItem('calcumake_calculations')
        localStorage.removeItem('calcumake_advanced_calculator') // Legacy cleanup
        window.location.reload()
      }
    }
  })
}
