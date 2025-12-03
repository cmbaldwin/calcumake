/**
 * @jest-environment jsdom
 */

import { useCalculator } from '../../../../app/javascript/controllers/mixins/calculator_mixin.js'

describe('Calculator Mixin', () => {
  // Helper to create a mock controller with the mixin applied
  function createMockController(props = {}) {
    const controller = {
      energyCostValue: 0.12,
      ...props
    }
    useCalculator(controller)
    return controller
  }

  describe('calculateFilamentCost', () => {
    test('calculates cost for single filament', () => {
      const controller = createMockController()
      const plateData = {
        filaments: [
          { weight: 100, pricePerKg: 25 }
        ]
      }

      const cost = controller.calculateFilamentCost(plateData)

      expect(cost).toBeCloseTo(2.5) // 100g / 1000 * 25
    })

    test('calculates cost for multiple filaments', () => {
      const controller = createMockController()
      const plateData = {
        filaments: [
          { weight: 100, pricePerKg: 25 },
          { weight: 50, pricePerKg: 30 },
          { weight: 75, pricePerKg: 20 }
        ]
      }

      const cost = controller.calculateFilamentCost(plateData)

      // (100/1000 * 25) + (50/1000 * 30) + (75/1000 * 20) = 2.5 + 1.5 + 1.5 = 5.5
      expect(cost).toBeCloseTo(5.5)
    })

    test('handles zero weight', () => {
      const controller = createMockController()
      const plateData = {
        filaments: [
          { weight: 0, pricePerKg: 25 }
        ]
      }

      const cost = controller.calculateFilamentCost(plateData)

      expect(cost).toBe(0)
    })

    test('handles empty filaments array', () => {
      const controller = createMockController()
      const plateData = {
        filaments: []
      }

      const cost = controller.calculateFilamentCost(plateData)

      expect(cost).toBe(0)
    })

    test('handles null/undefined plateData', () => {
      const controller = createMockController()

      expect(controller.calculateFilamentCost(null)).toBe(0)
      expect(controller.calculateFilamentCost(undefined)).toBe(0)
      expect(controller.calculateFilamentCost({})).toBe(0)
    })

    test('handles missing filament properties', () => {
      const controller = createMockController()
      const plateData = {
        filaments: [
          { weight: null, pricePerKg: 25 },
          { weight: 100, pricePerKg: null }
        ]
      }

      const cost = controller.calculateFilamentCost(plateData)

      expect(cost).toBe(0) // Both should result in 0 due to null values
    })
  })

  describe('calculateElectricityCost', () => {
    test('calculates electricity cost correctly', () => {
      const controller = createMockController({ energyCostValue: 0.12 })

      const totalPrintTime = 2.5
      const globalSettings = {
        powerConsumption: 200
      }

      const cost = controller.calculateElectricityCost(totalPrintTime, globalSettings)

      // 2.5 hours * 200W / 1000 * $0.12/kWh = 0.06
      expect(cost).toBeCloseTo(0.06)
    })

    test('handles zero print time', () => {
      const controller = createMockController({ energyCostValue: 0.12 })

      const totalPrintTime = 0
      const globalSettings = {
        powerConsumption: 200
      }

      const cost = controller.calculateElectricityCost(totalPrintTime, globalSettings)

      expect(cost).toBe(0)
    })

    test('uses different energy cost values', () => {
      const controller = createMockController({ energyCostValue: 0.20 })

      const totalPrintTime = 5.0
      const globalSettings = {
        powerConsumption: 300
      }

      const cost = controller.calculateElectricityCost(totalPrintTime, globalSettings)

      // 5 hours * 300W / 1000 * $0.20/kWh = 0.30
      expect(cost).toBeCloseTo(0.30)
    })

    test('handles missing power consumption', () => {
      const controller = createMockController({ energyCostValue: 0.12 })

      const totalPrintTime = 5.0
      const globalSettings = {}

      const cost = controller.calculateElectricityCost(totalPrintTime, globalSettings)

      expect(cost).toBe(0)
    })
  })

  describe('calculateLaborCost', () => {
    test('calculates prep and post labor costs', () => {
      const controller = createMockController()

      const globalSettings = {
        prepTime: 15,    // 15 minutes
        postTime: 30,    // 30 minutes
        prepRate: 20,    // $20/hour
        postRate: 25     // $25/hour
      }

      const cost = controller.calculateLaborCost(globalSettings)

      // (15/60 * 20) + (30/60 * 25) = 5 + 12.5 = 17.5
      expect(cost).toBeCloseTo(17.5)
    })

    test('handles zero labor time', () => {
      const controller = createMockController()

      const globalSettings = {
        prepTime: 0,
        postTime: 0,
        prepRate: 20,
        postRate: 25
      }

      const cost = controller.calculateLaborCost(globalSettings)

      expect(cost).toBe(0)
    })

    test('handles different hourly rates', () => {
      const controller = createMockController()

      const globalSettings = {
        prepTime: 60,  // 60 minutes = 1 hour
        postTime: 60,  // 60 minutes = 1 hour
        prepRate: 50,
        postRate: 75
      }

      const cost = controller.calculateLaborCost(globalSettings)

      expect(cost).toBeCloseTo(125) // (60/60 * 50) + (60/60 * 75) = 50 + 75
    })

    test('handles missing labor settings', () => {
      const controller = createMockController()

      const cost = controller.calculateLaborCost(null)

      expect(cost).toBe(0)
    })
  })

  describe('calculateMachineCost', () => {
    test('calculates machine depreciation cost', () => {
      const controller = createMockController()

      const totalPrintTime = 10  // 10 hours
      const globalSettings = {
        machineCost: 1000,  // $1000 machine
        payoffYears: 2      // 2 year payoff
      }

      const cost = controller.calculateMachineCost(totalPrintTime, globalSettings)

      // 10 hours * (1000 / (2 * 365 * 8)) = 10 * 0.17123 ≈ 1.71
      expect(cost).toBeCloseTo(1.71, 2)
    })

    test('handles longer print times', () => {
      const controller = createMockController()

      const totalPrintTime = 100
      const globalSettings = {
        machineCost: 500,
        payoffYears: 3
      }

      const cost = controller.calculateMachineCost(totalPrintTime, globalSettings)

      // 100 * (500 / (3 * 365 * 8)) = 100 * 0.057077 ≈ 5.71
      expect(cost).toBeCloseTo(5.71, 2)
    })

    test('handles zero print time', () => {
      const controller = createMockController()

      const totalPrintTime = 0
      const globalSettings = {
        machineCost: 500,
        payoffYears: 3
      }

      const cost = controller.calculateMachineCost(totalPrintTime, globalSettings)

      expect(cost).toBe(0)
    })

    test('handles missing machine settings', () => {
      const controller = createMockController()

      const totalPrintTime = 10
      const globalSettings = {}

      const cost = controller.calculateMachineCost(totalPrintTime, globalSettings)

      expect(cost).toBe(0)
    })
  })
})
