// Calculator Mixin - Cost calculation logic
export const CalculatorMixin = {
  calculate() {
    const plates = this.getPlates()

    let totalFilamentCost = 0
    let totalElectricityCost = 0
    let totalLaborCost = 0
    let totalMachineCost = 0

    plates.forEach(plate => {
      const plateData = this.getPlateData(plate)

      // Filament costs
      totalFilamentCost += this.calculateFilamentCost(plateData)

      // Electricity cost
      totalElectricityCost += this.calculateElectricityCost(plateData)

      // Labor cost
      totalLaborCost += this.calculateLaborCost(plateData)

      // Machine cost (depreciation)
      totalMachineCost += this.calculateMachineCost(plateData)
    })

    // Other costs
    const failureRate = parseFloat(this.hasFailureRateTarget ? this.failureRateTarget.value : (this.element.querySelector('[name="failure_rate"]')?.value || 0))
    const shippingCost = parseFloat(this.hasShippingCostTarget ? this.shippingCostTarget.value : (this.element.querySelector('[name="shipping_cost"]')?.value || 0))
    const otherCost = parseFloat(this.hasOtherCostTarget ? this.otherCostTarget.value : (this.element.querySelector('[name="other_cost"]')?.value || 0))
    const units = parseInt(this.hasUnitsTarget ? this.unitsTarget.value : (this.element.querySelector('[name="units"]')?.value || 1))

    const totalOtherCosts = shippingCost + otherCost

    // Calculate subtotal before failure rate
    const subtotal = totalFilamentCost + totalElectricityCost + totalLaborCost + totalMachineCost + totalOtherCosts

    // Apply failure rate
    const failureCost = subtotal * (failureRate / 100)

    // Grand total
    const grandTotal = subtotal + failureCost

    // Per unit price
    const perUnitPrice = units > 1 ? grandTotal / units : 0

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
    if (this.hasPerUnitPriceTarget && this.hasPerUnitSectionTarget) {
      if (units > 1) {
        this.perUnitPriceTarget.textContent = this.formatCurrency(perUnitPrice)
        this.perUnitSectionTarget.style.display = 'flex'
      } else {
        this.perUnitSectionTarget.style.display = 'none'
      }
    }

    // Animate results
    if (this.hasResultsSectionTarget) {
      this.resultsSectionTarget.style.transform = "scale(1.01)"
      setTimeout(() => {
        this.resultsSectionTarget.style.transform = "scale(1)"
      }, 150)
    }

    // Save to storage after calculating
    this.saveToStorage()
  },

  calculateFilamentCost(plateData) {
    return plateData.filaments.reduce((total, filament) => {
      const weightKg = filament.weight / 1000
      return total + (weightKg * filament.pricePerKg)
    }, 0)
  },

  calculateElectricityCost(plateData) {
    if (!plateData.printTime || !plateData.powerConsumption) return 0
    const powerKw = plateData.powerConsumption / 1000
    return plateData.printTime * powerKw * this.energyCostValue
  },

  calculateLaborCost(plateData) {
    const prepCost = (plateData.prepTime && plateData.prepRate) ?
      (plateData.prepTime * plateData.prepRate / 60) : 0
    const postCost = (plateData.postTime && plateData.postRate) ?
      (plateData.postTime * plateData.postRate / 60) : 0
    return prepCost + postCost
  },

  calculateMachineCost(plateData) {
    if (!plateData.printTime || !plateData.machineCost || !plateData.payoffYears) return 0

    const totalHoursPerYear = 365 * 8 // Assuming 8 hours/day usage
    const totalHoursPayoff = totalHoursPerYear * plateData.payoffYears
    const costPerHour = plateData.machineCost / totalHoursPayoff
    return plateData.printTime * costPerHour
  }
}
