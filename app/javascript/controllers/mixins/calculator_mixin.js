// Calculator Mixin - Cost calculation logic
// Following Better Stimulus pattern: https://betterstimulus.com/architecture/mixins
export const useCalculator = controller => {
  Object.assign(controller, {
    // Main calculation method
    calculate() {
      const plates = this.getPlates()
      if (!plates || plates.length === 0) return

      // Get global settings (shared across all plates)
      const globalSettings = this.getGlobalSettings()

      let totalFilamentCost = 0
      let totalElectricityCost = 0
      let totalPrintTime = 0

      plates.forEach(plate => {
        const plateData = this.getPlateData(plate)
        if (!plateData) return // Skip invalid plate data

        // Filament costs (per plate)
        totalFilamentCost += this.calculateFilamentCost(plateData)

        // Accumulate print time for electricity and machine costs
        totalPrintTime += plateData.printTime || 0
      })

      // Calculate electricity cost using total print time and global power settings
      totalElectricityCost = this.calculateElectricityCost(totalPrintTime, globalSettings)

      // Calculate labor cost (once per job, not per plate)
      const totalLaborCost = this.calculateLaborCost(globalSettings)

      // Calculate machine cost using total print time
      const totalMachineCost = this.calculateMachineCost(totalPrintTime, globalSettings)

      // Other costs
      const failureRate = parseFloat(this.hasFailureRateTarget ? this.failureRateTarget.value : (this.element.querySelector('[name="failure_rate"]')?.value || 0))
      const shippingCost = parseFloat(this.hasShippingCostTarget ? this.shippingCostTarget.value : (this.element.querySelector('[name="shipping_cost"]')?.value || 0))
      const otherCost = parseFloat(this.hasOtherCostTarget ? this.otherCostTarget.value : (this.element.querySelector('[name="other_cost"]')?.value || 0))
      // Ensure units is at least 1
      const units = Math.max(1, parseInt(this.hasUnitsTarget ? this.unitsTarget.value : (this.element.querySelector('[name="units"]')?.value || 1)) || 1)

      const totalOtherCosts = shippingCost + otherCost

      // Calculate subtotal before failure rate
      const subtotal = totalFilamentCost + totalElectricityCost + totalLaborCost + totalMachineCost + totalOtherCosts

      // Apply failure rate
      const failureCost = subtotal * (failureRate / 100)

      // Grand total
      const grandTotal = subtotal + failureCost

      // Per unit price (always calculate, display only when units > 1)
      const perUnitPrice = grandTotal / units

      // Update display
      if (this.hasTotalFilamentCostTarget) {
        this.totalFilamentCostTarget.textContent = this.formatCurrency(totalFilamentCost)
      }
      if (this.hasTotalElectricityCostTarget) {
        this.totalElectricityCostTarget.textContent = this.formatCurrency(totalElectricityCost)
      }
      if (this.hasTotalLaborCostTarget) {
        this.totalLaborCostTarget.textContent = this.formatCurrency(totalLaborCost)
      }
      if (this.hasTotalMachineCostTarget) {
        this.totalMachineCostTarget.textContent = this.formatCurrency(totalMachineCost)
      }
      if (this.hasTotalOtherCostsTarget) {
        this.totalOtherCostsTarget.textContent = this.formatCurrency(totalOtherCosts + failureCost)
      }
      if (this.hasGrandTotalTarget) {
        this.grandTotalTarget.textContent = this.formatCurrency(grandTotal)
      }

      // Update per-unit price display
      if (this.hasPerUnitPriceTarget) {
        this.perUnitPriceTarget.textContent = this.formatCurrency(perUnitPrice)
      }
      if (this.hasPerUnitSectionTarget) {
        // Show per-unit section when units > 1
        this.perUnitSectionTarget.style.display = units > 1 ? 'flex' : 'none'
      }

      // Animate results (only if not already animating)
      if (this.hasResultsSectionTarget && !this.isAnimating) {
        this.isAnimating = true
        this.resultsSectionTarget.style.transform = "scale(1.01)"
        this._animationTimeout = setTimeout(() => {
          if (this.hasResultsSectionTarget) {
            this.resultsSectionTarget.style.transform = "scale(1)"
          }
          this.isAnimating = false
        }, 150)
      }

      // Save to storage after calculating (if storage mixin is present)
      if (typeof this.saveToStorage === 'function') {
        this.saveToStorage()
      }
    },

    // Individual calculation methods
    calculateFilamentCost(plateData) {
      // Handle FDM (filament) plates
      if (plateData?.technology === 'fdm' || (!plateData?.technology && plateData?.filaments)) {
        if (!plateData?.filaments || !Array.isArray(plateData.filaments)) return 0
        return plateData.filaments.reduce((total, filament) => {
          const weightKg = (filament?.weight || 0) / 1000
          return total + (weightKg * (filament?.pricePerKg || 0))
        }, 0)
      }

      // Handle Resin plates
      if (plateData?.technology === 'resin' && plateData?.resin) {
        const volumeLiters = (plateData.resin.volume || 0) / 1000
        return volumeLiters * (plateData.resin.pricePerLiter || 0)
      }

      return 0
    },

    calculateElectricityCost(totalPrintTime, globalSettings) {
      if (!totalPrintTime || !globalSettings?.powerConsumption) return 0
      const powerKw = globalSettings.powerConsumption / 1000
      return totalPrintTime * powerKw * (this.energyCostValue || 0.12)
    },

    calculateLaborCost(globalSettings) {
      if (!globalSettings) return 0
      // Convert minutes to hours (prepTime and postTime are now in minutes)
      const prepHours = globalSettings.prepTime / 60
      const postHours = globalSettings.postTime / 60

      const prepCost = (globalSettings.prepTime && globalSettings.prepRate) ?
        (prepHours * globalSettings.prepRate) : 0
      const postCost = (globalSettings.postTime && globalSettings.postRate) ?
        (postHours * globalSettings.postRate) : 0
      return prepCost + postCost
    },

    calculateMachineCost(totalPrintTime, globalSettings) {
      if (!totalPrintTime || !globalSettings?.machineCost || !globalSettings?.payoffYears) return 0

      const totalHoursPerYear = 365 * 8 // Assuming 8 hours/day usage
      const totalHoursPayoff = totalHoursPerYear * globalSettings.payoffYears
      const costPerHour = globalSettings.machineCost / totalHoursPayoff
      return totalPrintTime * costPerHour
    }
  })
}
