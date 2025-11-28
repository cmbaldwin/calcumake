/**
 * @jest-environment jsdom
 */

import { CalculatorMixin } from '../../../../app/javascript/controllers/mixins/calculator_mixin.js'

describe('CalculatorMixin', () => {
  describe('calculateFilamentCost', () => {
    test('calculates cost for single filament', () => {
      const mockController = Object.assign({}, CalculatorMixin)
      const plateData = {
        filaments: [
          { weight: 100, pricePerKg: 25 }
        ]
      }

      const cost = mockController.calculateFilamentCost(plateData)

      expect(cost).toBeCloseTo(2.5) // 100g / 1000 * 25
    })

    test('calculates cost for multiple filaments', () => {
      const mockController = Object.assign({}, CalculatorMixin)
      const plateData = {
        filaments: [
          { weight: 100, pricePerKg: 25 },
          { weight: 50, pricePerKg: 30 },
          { weight: 75, pricePerKg: 20 }
        ]
      }

      const cost = mockController.calculateFilamentCost(plateData)

      // (100/1000 * 25) + (50/1000 * 30) + (75/1000 * 20) = 2.5 + 1.5 + 1.5 = 5.5
      expect(cost).toBeCloseTo(5.5)
    })

    test('handles zero weight', () => {
      const mockController = Object.assign({}, CalculatorMixin)
      const plateData = {
        filaments: [
          { weight: 0, pricePerKg: 25 }
        ]
      }

      const cost = mockController.calculateFilamentCost(plateData)

      expect(cost).toBe(0)
    })

    test('handles empty filaments array', () => {
      const mockController = Object.assign({}, CalculatorMixin)
      const plateData = {
        filaments: []
      }

      const cost = mockController.calculateFilamentCost(plateData)

      expect(cost).toBe(0)
    })
  })

  describe('calculateElectricityCost', () => {
    test('calculates electricity cost correctly', () => {
      const mockController = Object.assign({
        energyCostValue: 0.12
      }, CalculatorMixin)

      const totalPrintTime = 2.5
      const globalSettings = {
        powerConsumption: 200
      }

      const cost = mockController.calculateElectricityCost(totalPrintTime, globalSettings)

      // 2.5 hours * 200W / 1000 * $0.12/kWh = 0.06
      expect(cost).toBeCloseTo(0.06)
    })

    test('handles zero print time', () => {
      const mockController = Object.assign({
        energyCostValue: 0.12
      }, CalculatorMixin)

      const totalPrintTime = 0
      const globalSettings = {
        powerConsumption: 200
      }

      const cost = mockController.calculateElectricityCost(totalPrintTime, globalSettings)

      expect(cost).toBe(0)
    })

    test('uses different energy cost values', () => {
      const mockController = Object.assign({
        energyCostValue: 0.20 // Higher electricity rate
      }, CalculatorMixin)

      const totalPrintTime = 5.0
      const globalSettings = {
        powerConsumption: 300
      }

      const cost = mockController.calculateElectricityCost(totalPrintTime, globalSettings)

      // 5 hours * 300W / 1000 * $0.20/kWh = 0.30
      expect(cost).toBeCloseTo(0.30)
    })
  })

  describe('calculateLaborCost', () => {
    test('calculates prep and post labor costs', () => {
      const mockController = Object.assign({}, CalculatorMixin)

      // Note: prepTime and postTime are in HOURS in the new implementation
      const globalSettings = {
        prepTime: 0.25,  // 15 minutes = 0.25 hours
        postTime: 0.5,   // 30 minutes = 0.5 hours
        prepRate: 20,    // $20/hour
        postRate: 25     // $25/hour
      }

      const cost = mockController.calculateLaborCost(globalSettings)

      // (0.25 * 20) + (0.5 * 25) = 5 + 12.5 = 17.5
      expect(cost).toBeCloseTo(17.5)
    })

    test('handles zero labor time', () => {
      const mockController = Object.assign({}, CalculatorMixin)

      const globalSettings = {
        prepTime: 0,
        postTime: 0,
        prepRate: 20,
        postRate: 25
      }

      const cost = mockController.calculateLaborCost(globalSettings)

      expect(cost).toBe(0)
    })

    test('handles different hourly rates', () => {
      const mockController = Object.assign({}, CalculatorMixin)

      const globalSettings = {
        prepTime: 1,  // 1 hour
        postTime: 1,  // 1 hour
        prepRate: 50,
        postRate: 75
      }

      const cost = mockController.calculateLaborCost(globalSettings)

      expect(cost).toBeCloseTo(125) // (1 * 50) + (1 * 75) = 50 + 75
    })
  })

  describe('calculateMachineCost', () => {
    test('calculates machine depreciation cost', () => {
      const mockController = Object.assign({}, CalculatorMixin)

      const totalPrintTime = 10  // 10 hours
      const globalSettings = {
        machineCost: 1000,  // $1000 machine
        payoffYears: 2      // 2 year payoff
      }

      const cost = mockController.calculateMachineCost(totalPrintTime, globalSettings)

      // 10 hours * (1000 / (2 * 365 * 8)) = 10 * 0.17123 ≈ 1.71
      expect(cost).toBeCloseTo(1.71, 2)
    })

    test('handles longer print times', () => {
      const mockController = Object.assign({}, CalculatorMixin)

      const totalPrintTime = 100
      const globalSettings = {
        machineCost: 500,
        payoffYears: 3
      }

      const cost = mockController.calculateMachineCost(totalPrintTime, globalSettings)

      // 100 * (500 / (3 * 365 * 8)) = 100 * 0.057077 ≈ 5.71
      expect(cost).toBeCloseTo(5.71, 2)
    })

    test('handles zero print time', () => {
      const mockController = Object.assign({}, CalculatorMixin)

      const totalPrintTime = 0
      const globalSettings = {
        machineCost: 500,
        payoffYears: 3
      }

      const cost = mockController.calculateMachineCost(totalPrintTime, globalSettings)

      expect(cost).toBe(0)
    })
  })
})
