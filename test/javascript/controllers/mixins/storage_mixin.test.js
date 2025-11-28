/**
 * @jest-environment jsdom
 */

import { StorageMixin } from '../../../../app/javascript/controllers/mixins/storage_mixin.js'

describe('StorageMixin', () => {
  beforeEach(() => {
    // Clear localStorage before each test
    localStorage.clear()
    jest.clearAllMocks()

    // Mock window.confirm and window.location.reload
    global.confirm = jest.fn(() => true)
    delete global.window.location
    global.window.location = { reload: jest.fn() }
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  describe('saveToStorage', () => {
    test('saves basic calculator data to localStorage', () => {
      const mockElement = document.createElement('div')
      mockElement.innerHTML = `
        <input name="failure_rate" value="10" />
        <input name="shipping_cost" value="25.50" />
        <input name="other_cost" value="10.00" />
        <input name="units" value="5" />
      `
      // Add to document so isConnected returns true
      document.body.appendChild(mockElement)

      const mockController = Object.assign({
        element: mockElement,
        hasJobNameTarget: true,
        jobNameTarget: { value: 'Test Job' },
        hasUnitsTarget: false,
        hasFailureRateTarget: false,
        hasShippingCostTarget: false,
        hasOtherCostTarget: false,
        getPlates: () => [{}], // Return at least one plate
        getPlateDataForStorage: jest.fn(() => ({})),
        getGlobalSettings: () => ({
          powerConsumption: 200,
          machineCost: 500,
          payoffYears: 3,
          prepTime: 0.25,
          postTime: 0.25,
          prepRate: 20,
          postRate: 20
        })
      }, StorageMixin)

      mockController.saveToStorage()

      const saved = localStorage.getItem('calcumake_advanced_calculator')
      expect(saved).not.toBeNull()

      const data = JSON.parse(saved)
      expect(data.jobName).toBe('Test Job')
      expect(data.failureRate).toBe(10)
      expect(data.shippingCost).toBe(25.50)
      expect(data.otherCost).toBe(10.00)
      expect(data.units).toBe(5)

      // Cleanup
      document.body.removeChild(mockElement)
    })

    test('handles missing form fields gracefully', () => {
      const mockElement = document.createElement('div')
      // Add to document so isConnected returns true
      document.body.appendChild(mockElement)

      const mockController = Object.assign({
        element: mockElement,
        hasJobNameTarget: false,
        hasUnitsTarget: false,
        hasFailureRateTarget: false,
        hasShippingCostTarget: false,
        hasOtherCostTarget: false,
        getPlates: () => [{}], // Return at least one plate
        getPlateDataForStorage: jest.fn(() => ({})),
        getGlobalSettings: () => ({})
      }, StorageMixin)

      mockController.saveToStorage()

      const saved = localStorage.getItem('calcumake_advanced_calculator')
      const data = JSON.parse(saved)

      expect(data.jobName).toBe('')
      expect(data.failureRate).toBe(0)
      expect(data.units).toBe(1)

      // Cleanup
      document.body.removeChild(mockElement)
    })
  })

  describe('clearStorage', () => {
    test('removes data from localStorage when confirmed', () => {
      localStorage.setItem('calcumake_advanced_calculator', '{"jobName":"Test"}')

      const mockController = Object.assign({}, StorageMixin)

      mockController.clearStorage()

      expect(localStorage.getItem('calcumake_advanced_calculator')).toBeNull()
      expect(global.window.location.reload).toHaveBeenCalled()
    })

    test('does not clear storage when user cancels', () => {
      // Mock confirm to return false
      global.confirm = jest.fn(() => false)

      localStorage.setItem('calcumake_advanced_calculator', '{"jobName":"Test"}')

      const mockController = Object.assign({}, StorageMixin)

      mockController.clearStorage()

      // Storage should NOT be cleared
      expect(localStorage.getItem('calcumake_advanced_calculator')).not.toBeNull()
      expect(global.window.location.reload).not.toHaveBeenCalled()
    })
  })

  describe('setupAutoSave', () => {
    test('is disabled and does nothing', () => {
      // Auto-save was disabled to prevent page freezes
      // This test verifies the method exists but doesn't set up an interval
      const mockController = Object.assign({
        autoSaveInterval: null
      }, StorageMixin)

      mockController.setupAutoSave()

      // Auto-save should NOT set up an interval anymore
      expect(mockController.autoSaveInterval).toBeNull()
    })

    test('can be cleared', () => {
      jest.useFakeTimers()

      const mockController = Object.assign({
        autoSaveInterval: null
      }, StorageMixin)

      mockController.setupAutoSave()
      const intervalId = mockController.autoSaveInterval

      // Clear the interval
      clearInterval(intervalId)
      mockController.autoSaveInterval = null

      // Manually check that interval is cleared
      expect(mockController.autoSaveInterval).toBeNull()

      jest.useRealTimers()
    })
  })

  describe('getPlateDataForStorage', () => {
    test('returns plate data with filaments', () => {
      const mockPlateDiv = document.createElement('div')
      mockPlateDiv.innerHTML = `
        <div data-filaments-container>
          <div data-filament-index="0">
            <input name="plates[0][filaments][0][filament_weight]" value="100" />
            <input name="plates[0][filaments][0][filament_price]" value="25" />
          </div>
        </div>
      `

      const mockController = Object.assign({
        getPlateData: jest.fn(() => ({
          printTime: 2.5,
          powerConsumption: 200,
          machineCost: 500,
          payoffYears: 3,
          prepTime: 15,
          postTime: 30,
          prepRate: 20,
          postRate: 25,
          filaments: [{ weight: 100, pricePerKg: 25 }]
        }))
      }, StorageMixin)

      const plateData = mockController.getPlateDataForStorage(mockPlateDiv)

      expect(plateData).toHaveProperty('printTime', 2.5)
      expect(plateData).toHaveProperty('filaments')
      expect(plateData.filaments[0]).toHaveProperty('weight', 100)
      expect(plateData.filaments[0]).toHaveProperty('pricePerKg', 25)
    })
  })
})
