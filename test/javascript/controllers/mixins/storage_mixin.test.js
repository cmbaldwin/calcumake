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

      const saved = JSON.parse(localStorage.getItem('calcumake_advanced_calculator'))

      expect(saved).toBeDefined()
      expect(saved.jobName).toBe('Test Job')
      expect(saved.failureRate).toBe(5)
      expect(saved.shippingCost).toBe(10.50)
      expect(saved.otherCost).toBe(7.25)
      expect(saved.units).toBe(5)
      expect(saved.plates).toHaveLength(1)
      expect(saved.timestamp).toBeDefined()
    })

    test('handles missing job name target', () => {
      const controller = createMockController({
        hasJobNameTarget: false
      })

      expect(() => controller.saveToStorage()).not.toThrow()

      const saved = JSON.parse(localStorage.getItem('calcumake_advanced_calculator'))
      expect(saved.jobName).toBe('')
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
    test('loads calculator data from localStorage', () => {
      const savedData = {
        jobName: 'Loaded Job',
        plates: [],
        failureRate: 3,
        shippingCost: 15.00,
        otherCost: 5.50,
        units: 10,
        timestamp: new Date().toISOString()
      }

      localStorage.setItem('calcumake_advanced_calculator', JSON.stringify(savedData))

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

      controller.loadFromStorage()

      expect(jobNameTarget.value).toBe('Loaded Job')
      expect(failureRateInput.value).toBe('3')
      expect(shippingInput.value).toBe('15')
      expect(otherInput.value).toBe('5.5')
      expect(unitsInput.value).toBe('10')
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
    test('clears localStorage and reloads page when confirmed', () => {
      localStorage.setItem('calcumake_advanced_calculator', JSON.stringify({ test: 'data' }))

      const controller = createMockController()

      // Mock window.confirm to return true
      window.confirm = jest.fn(() => true)
      // Mock window.location.reload
      delete window.location
      window.location = { reload: jest.fn() }

      controller.clearStorage()

      expect(window.confirm).toHaveBeenCalledWith('Are you sure you want to clear all saved data?')
      expect(localStorage.getItem('calcumake_advanced_calculator')).toBeNull()
      expect(window.location.reload).toHaveBeenCalled()
    })

    test('does not clear localStorage when canceled', () => {
      localStorage.setItem('calcumake_advanced_calculator', JSON.stringify({ test: 'data' }))

      const controller = createMockController()

      // Mock window.confirm to return false
      window.confirm = jest.fn(() => false)

      controller.clearStorage()

      expect(window.confirm).toHaveBeenCalled()
      expect(localStorage.getItem('calcumake_advanced_calculator')).not.toBeNull()
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
})
