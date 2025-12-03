/**
 * @jest-environment jsdom
 */

import { useStorage } from '../../../../app/javascript/controllers/mixins/storage_mixin.js'

describe('Storage Mixin', () => {
  // Helper to create a mock controller with the mixin applied
  function createMockController(props = {}) {
    const controller = {
      element: document.createElement('div'),
      hasJobNameTarget: false,
      getPlates: jest.fn(() => []),
      getPlateData: jest.fn((plate) => ({
        printTime: 2.5,
        filaments: [{ weight: 100, pricePerKg: 25 }]
      })),
      getGlobalSettings: jest.fn(() => ({
        powerConsumption: 200,
        machineCost: 500,
        payoffYears: 3,
        prepTime: 15,
        postTime: 15,
        prepRate: 20,
        postRate: 20
      })),
      calculate: jest.fn(),
      addPlate: jest.fn(),
      addFilamentToPlate: jest.fn(),
      restoreGlobalSettings: jest.fn(),
      restorePlates: jest.fn(),
      restorePlateData: jest.fn(),
      ...props
    }
    useStorage(controller)
    return controller
  }

  beforeEach(() => {
    // Clear localStorage before each test
    localStorage.clear()
    jest.clearAllMocks()
  })

  describe('saveToStorage', () => {
    test('saves calculator data to localStorage', () => {
      const jobNameTarget = document.createElement('input')
      jobNameTarget.value = 'Test Job'

      const controller = createMockController({
        hasJobNameTarget: true,
        jobNameTarget,
        getPlates: jest.fn(() => [document.createElement('div')])
      })

      // Add required input fields to the element
      const failureRateInput = document.createElement('input')
      failureRateInput.name = 'failure_rate'
      failureRateInput.value = '5'
      controller.element.appendChild(failureRateInput)

      const shippingInput = document.createElement('input')
      shippingInput.name = 'shipping_cost'
      shippingInput.value = '10.50'
      controller.element.appendChild(shippingInput)

      const otherInput = document.createElement('input')
      otherInput.name = 'other_cost'
      otherInput.value = '7.25'
      controller.element.appendChild(otherInput)

      const unitsInput = document.createElement('input')
      unitsInput.name = 'units'
      unitsInput.value = '5'
      controller.element.appendChild(unitsInput)

      controller.saveToStorage()

      const allCalculations = JSON.parse(localStorage.getItem('calcumake_calculations'))

      expect(allCalculations).toBeDefined()
      expect(allCalculations.default).toBeDefined()
      expect(allCalculations.default.jobName).toBe('Test Job')
      expect(allCalculations.default.failureRate).toBe(5)
      expect(allCalculations.default.shippingCost).toBe(10.50)
      expect(allCalculations.default.otherCost).toBe(7.25)
      expect(allCalculations.default.units).toBe(5)
      expect(allCalculations.default.plates).toHaveLength(1)
      expect(allCalculations.default.timestamp).toBeDefined()
      expect(allCalculations.default.globalSettings).toBeDefined()
    })

    test('handles missing job name target', () => {
      const controller = createMockController({
        hasJobNameTarget: false
      })

      expect(() => controller.saveToStorage()).not.toThrow()

      const allCalculations = JSON.parse(localStorage.getItem('calcumake_calculations'))
      expect(allCalculations.default.jobName).toBe('')
    })

    test('handles localStorage errors gracefully', () => {
      const controller = createMockController()

      // Mock localStorage to throw an error
      const setItemSpy = jest.spyOn(Storage.prototype, 'setItem')
      setItemSpy.mockImplementation(() => {
        throw new Error('Quota exceeded')
      })

      // Should not throw
      expect(() => controller.saveToStorage()).not.toThrow()

      setItemSpy.mockRestore()
    })
  })

  describe('loadFromStorage', () => {
    test('migrates legacy single calculation to new format', () => {
      const legacyData = {
        jobName: 'Legacy Job',
        plates: [],
        failureRate: 3,
        shippingCost: 15.00,
        otherCost: 5.50,
        units: 10,
        timestamp: new Date().toISOString()
      }

      localStorage.setItem('calcumake_advanced_calculator', JSON.stringify(legacyData))

      const controller = createMockController({
        loadCalculation: jest.fn(() => true)
      })

      controller.loadFromStorage()

      // Legacy data should be removed
      expect(localStorage.getItem('calcumake_advanced_calculator')).toBeNull()

      // New format should exist
      const allCalculations = JSON.parse(localStorage.getItem('calcumake_calculations'))
      expect(allCalculations.default).toBeDefined()
      expect(allCalculations.default.jobName).toBe('Legacy Job')
    })

    test('handles missing localStorage data', () => {
      const controller = createMockController()

      expect(() => controller.loadFromStorage()).not.toThrow()
    })

    test('handles invalid JSON in localStorage', () => {
      localStorage.setItem('calcumake_advanced_calculator', 'invalid json {')

      const controller = createMockController()

      expect(() => controller.loadFromStorage()).not.toThrow()
    })
  })

  describe('loadCalculation', () => {
    test('loads specific calculation by ID', () => {
      const allCalculations = {
        'test_123': {
          id: 'test_123',
          name: 'Test Calculation',
          jobName: 'Test Job',
          plates: [],  // Empty plates to avoid DOM errors
          globalSettings: { powerConsumption: 200 },
          failureRate: 5,
          shippingCost: 10,
          otherCost: 5,
          units: 3,
          timestamp: new Date().toISOString()
        }
      }

      localStorage.setItem('calcumake_calculations', JSON.stringify(allCalculations))

      const jobNameTarget = document.createElement('input')

      const controller = createMockController({
        hasJobNameTarget: true,
        jobNameTarget
      })

      // Add input fields to element
      const failureRateInput = document.createElement('input')
      failureRateInput.name = 'failure_rate'
      controller.element.appendChild(failureRateInput)

      const shippingInput = document.createElement('input')
      shippingInput.name = 'shipping_cost'
      controller.element.appendChild(shippingInput)

      const otherInput = document.createElement('input')
      otherInput.name = 'other_cost'
      controller.element.appendChild(otherInput)

      const unitsInput = document.createElement('input')
      unitsInput.name = 'units'
      controller.element.appendChild(unitsInput)

      const result = controller.loadCalculation('test_123')

      expect(result).toBe(true)
      expect(jobNameTarget.value).toBe('Test Job')
      expect(failureRateInput.value).toBe('5')
      expect(shippingInput.value).toBe('10')
      expect(otherInput.value).toBe('5')
      expect(unitsInput.value).toBe('3')
    })

    test('returns false for non-existent calculation', () => {
      const controller = createMockController()

      const result = controller.loadCalculation('non_existent')

      expect(result).toBe(false)
    })
  })

  describe('saveCalculationAs', () => {
    test('saves calculation with new name', () => {
      window.prompt = jest.fn(() => 'New Calculation')

      const jobNameTarget = document.createElement('input')
      jobNameTarget.value = 'New Calculation'

      const controller = createMockController({
        hasJobNameTarget: true,
        jobNameTarget
      })

      controller.saveCalculationAs()

      const allCalculations = JSON.parse(localStorage.getItem('calcumake_calculations'))
      const calcIds = Object.keys(allCalculations)

      expect(calcIds.length).toBe(1)
      expect(calcIds[0]).toContain('new_calculation_')
      expect(allCalculations[calcIds[0]].name).toBe('New Calculation')
    })

    test('saves with untitled name if job name is empty', () => {
      const controller = createMockController({
        hasJobNameTarget: false
      })

      controller.saveCalculationAs()

      const allCalculations = JSON.parse(localStorage.getItem('calcumake_calculations'))
      const calcIds = Object.keys(allCalculations)

      expect(calcIds.length).toBe(1)
      expect(calcIds[0]).toContain('untitled_calculation_')
      // When no job name, the ID is used as the name
      expect(allCalculations[calcIds[0]].name).toContain('untitled_calculation_')
    })
  })

  describe('deleteCalculation', () => {
    test('deletes calculation and reloads', () => {
      const allCalculations = {
        'default': { id: 'default', name: 'Default', plates: [], globalSettings: {} },
        'test_123': { id: 'test_123', name: 'Test', plates: [], globalSettings: {} }
      }

      localStorage.setItem('calcumake_calculations', JSON.stringify(allCalculations))

      window.confirm = jest.fn(() => true)
      delete window.location
      window.location = { reload: jest.fn() }

      const controller = createMockController()

      controller.setCurrentCalculationId('test_123')

      controller.deleteCalculation()

      const updatedCalculations = JSON.parse(localStorage.getItem('calcumake_calculations'))
      expect(updatedCalculations.test_123).toBeUndefined()
      expect(updatedCalculations.default).toBeDefined()
      expect(window.location.reload).toHaveBeenCalled()
      expect(window.confirm).toHaveBeenCalledWith('Are you sure you want to delete "Test"?')
    })

    test('does not delete if user cancels', () => {
      const allCalculations = {
        'test_123': { id: 'test_123', name: 'Test', plates: [], globalSettings: {} }
      }

      localStorage.setItem('calcumake_calculations', JSON.stringify(allCalculations))

      window.confirm = jest.fn(() => false)

      const controller = createMockController()
      controller.setCurrentCalculationId('test_123')

      controller.deleteCalculation()

      const updatedCalculations = JSON.parse(localStorage.getItem('calcumake_calculations'))
      expect(updatedCalculations.test_123).toBeDefined()
    })

    test('shows alert if no calculation to delete', () => {
      window.alert = jest.fn()

      const controller = createMockController()
      controller.setCurrentCalculationId('non_existent')

      controller.deleteCalculation()

      expect(window.alert).toHaveBeenCalledWith("No calculation to delete.")
    })
  })

  describe('setupAutoSave', () => {
    test('sets up auto-save interval', () => {
      jest.useFakeTimers()

      const controller = createMockController()
      const saveToStorageSpy = jest.spyOn(controller, 'saveToStorage')

      controller.setupAutoSave()

      expect(controller.autoSaveInterval).toBeDefined()

      // Fast-forward 10 seconds
      jest.advanceTimersByTime(10000)

      expect(saveToStorageSpy).toHaveBeenCalledTimes(1)

      // Fast-forward another 10 seconds
      jest.advanceTimersByTime(10000)

      expect(saveToStorageSpy).toHaveBeenCalledTimes(2)

      clearInterval(controller.autoSaveInterval)
      jest.useRealTimers()
    })
  })

  describe('clearStorage', () => {
    test('clears all calculations when confirmed', () => {
      localStorage.setItem('calcumake_calculations', JSON.stringify({ test: 'data' }))
      localStorage.setItem('calcumake_advanced_calculator', JSON.stringify({ legacy: 'data' }))

      const controller = createMockController()

      // Mock window.confirm to return true
      window.confirm = jest.fn(() => true)
      // Mock window.location.reload
      delete window.location
      window.location = { reload: jest.fn() }

      controller.clearStorage()

      expect(window.confirm).toHaveBeenCalledWith('Are you sure you want to clear ALL saved calculations? This cannot be undone.')
      expect(localStorage.getItem('calcumake_calculations')).toBeNull()
      expect(localStorage.getItem('calcumake_advanced_calculator')).toBeNull()
      expect(window.location.reload).toHaveBeenCalled()
    })

    test('does not clear storage when canceled', () => {
      localStorage.setItem('calcumake_calculations', JSON.stringify({ test: 'data' }))

      const controller = createMockController()

      // Mock window.confirm to return false
      window.confirm = jest.fn(() => false)

      controller.clearStorage()

      expect(window.confirm).toHaveBeenCalled()
      expect(localStorage.getItem('calcumake_calculations')).not.toBeNull()
    })
  })

  describe('getPlateDataForStorage', () => {
    test('returns plate data with filaments', () => {
      const plateDiv = document.createElement('div')
      const controller = createMockController({
        getPlateData: jest.fn(() => ({
          printTime: 3.5,
          filaments: [
            { weight: 150, pricePerKg: 30 },
            { weight: 75, pricePerKg: 25 }
          ]
        }))
      })

      const plateData = controller.getPlateDataForStorage(plateDiv)

      expect(plateData.printTime).toBe(3.5)
      expect(plateData.filaments).toHaveLength(2)
      expect(plateData.filaments[0].weight).toBe(150)
      expect(controller.getPlateData).toHaveBeenCalledWith(plateDiv)
    })
  })

  describe('generateCalculationId', () => {
    test('generates unique ID from name', () => {
      const controller = createMockController()

      const id = controller.generateCalculationId('Test Calculation')

      expect(id).toContain('test_calculation_')
      expect(id.length).toBeGreaterThan('test_calculation_'.length)
    })
  })
})
