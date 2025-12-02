/**
 * @jest-environment jsdom
 */

import { ExportMixin } from '../../../../app/javascript/controllers/mixins/export_mixin.js'

// Note: These tests focus on the logic that can be tested without actual jsPDF/html2canvas libraries
// Full PDF/CSV export functionality is tested in system tests (test/system/advanced_calculator_test.rb)
//
// jsPDF and html2canvas are browser-only libraries loaded via importmap in production.
// They are not installed as npm dependencies, so we test the testable logic here
// and rely on system tests for end-to-end export verification.

describe('ExportMixin', () => {
  let mockController

  beforeEach(() => {
    jest.clearAllMocks()

    // Create mock controller with minimal required properties for CSV export
    const exportContentDiv = document.createElement('div')
    exportContentDiv.style.display = 'block'

    mockController = Object.assign({
      hasJobNameTarget: true,
      jobNameTarget: { value: 'Test Job' },
      hasGrandTotalTarget: true,
      grandTotalTarget: { textContent: '$125.50' },
      exportContentTarget: exportContentDiv,
      getPlates: jest.fn(() => [
        document.createElement('div'),
        document.createElement('div')
      ]),
      getPlateData: jest.fn(() => ({
        printTime: 5,
        filaments: [
          { weight: 100, pricePerKg: 25 },
          { weight: 50, pricePerKg: 30 }
        ]
      })),
      calculateFilamentCost: jest.fn(() => 2.5),
      calculateElectricityCost: jest.fn(() => 0.5),
      calculateLaborCost: jest.fn(() => 10.0),
      calculateMachineCost: jest.fn(() => 1.5)
    }, ExportMixin)
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  describe('exportToCSV', () => {
    test('prevents default event behavior', () => {
      const event = new Event('click')
      event.preventDefault = jest.fn()

      // Mock DOM methods
      global.URL.createObjectURL = jest.fn(() => 'blob:mock-url')
      const mockLink = {
        setAttribute: jest.fn(),
        click: jest.fn(),
        style: {}
      }
      jest.spyOn(document, 'createElement').mockReturnValue(mockLink)
      jest.spyOn(document.body, 'appendChild').mockImplementation()
      jest.spyOn(document.body, 'removeChild').mockImplementation()

      mockController.exportToCSV(event)

      expect(event.preventDefault).toHaveBeenCalled()
    })

    test('calls getPlates to collect data', () => {
      const event = new Event('click')
      event.preventDefault = jest.fn()

      // Mock DOM methods
      global.URL.createObjectURL = jest.fn(() => 'blob:mock-url')
      const mockLink = {
        setAttribute: jest.fn(),
        click: jest.fn(),
        style: {}
      }
      jest.spyOn(document, 'createElement').mockReturnValue(mockLink)
      jest.spyOn(document.body, 'appendChild').mockImplementation()
      jest.spyOn(document.body, 'removeChild').mockImplementation()

      mockController.exportToCSV(event)

      expect(mockController.getPlates).toHaveBeenCalled()
    })

    test('calculates costs for each plate', () => {
      const event = new Event('click')
      event.preventDefault = jest.fn()

      // Mock DOM methods
      global.URL.createObjectURL = jest.fn(() => 'blob:mock-url')
      const mockLink = {
        setAttribute: jest.fn(),
        click: jest.fn(),
        style: {}
      }
      jest.spyOn(document, 'createElement').mockReturnValue(mockLink)
      jest.spyOn(document.body, 'appendChild').mockImplementation()
      jest.spyOn(document.body, 'removeChild').mockImplementation()

      mockController.exportToCSV(event)

      // Should call calculations for each plate
      expect(mockController.calculateFilamentCost).toHaveBeenCalled()
      expect(mockController.calculateElectricityCost).toHaveBeenCalled()
      expect(mockController.calculateLaborCost).toHaveBeenCalled()
      expect(mockController.calculateMachineCost).toHaveBeenCalled()
    })

    test('generates filename with job name and timestamp', () => {
      const event = new Event('click')
      event.preventDefault = jest.fn()

      mockController.jobNameTarget.value = 'My Special Job'

      global.URL.createObjectURL = jest.fn(() => 'blob:mock-url')
      const mockLink = {
        setAttribute: jest.fn(),
        click: jest.fn(),
        style: {}
      }
      jest.spyOn(document, 'createElement').mockReturnValue(mockLink)
      jest.spyOn(document.body, 'appendChild').mockImplementation()
      jest.spyOn(document.body, 'removeChild').mockImplementation()

      mockController.exportToCSV(event)

      const downloadCall = mockLink.setAttribute.mock.calls.find(call => call[0] === 'download')
      expect(downloadCall).toBeDefined()
      expect(downloadCall[1]).toContain('My_Special_Job')
      expect(downloadCall[1]).toMatch(/\d{4}-\d{2}-\d{2}\.csv$/)
    })

    test('uses "Untitled" when no job name is provided', () => {
      const event = new Event('click')
      event.preventDefault = jest.fn()

      mockController.hasJobNameTarget = false

      global.URL.createObjectURL = jest.fn(() => 'blob:mock-url')
      const mockLink = {
        setAttribute: jest.fn(),
        click: jest.fn(),
        style: {}
      }
      jest.spyOn(document, 'createElement').mockReturnValue(mockLink)
      jest.spyOn(document.body, 'appendChild').mockImplementation()
      jest.spyOn(document.body, 'removeChild').mockImplementation()

      mockController.exportToCSV(event)

      const downloadCall = mockLink.setAttribute.mock.calls.find(call => call[0] === 'download')
      expect(downloadCall[1]).toContain('Untitled')
    })

    test('shows success toast after export', () => {
      const event = new Event('click')
      event.preventDefault = jest.fn()

      global.URL.createObjectURL = jest.fn(() => 'blob:mock-url')
      const mockLink = {
        setAttribute: jest.fn(),
        click: jest.fn(),
        style: {}
      }
      jest.spyOn(document, 'createElement').mockReturnValue(mockLink)
      const appendChildSpy = jest.spyOn(document.body, 'appendChild').mockImplementation()
      jest.spyOn(document.body, 'removeChild').mockImplementation()

      mockController.exportToCSV(event)

      // Verify toast was created (showToast called appendChild)
      expect(appendChildSpy).toHaveBeenCalled()

      // Find the toast element in the calls
      const toastCall = appendChildSpy.mock.calls.find(call =>
        call[0]?.className === 'toast-notification' && call[0]?.textContent.includes('CSV exported successfully!')
      )
      expect(toastCall).toBeDefined()
    })

    test('handles errors gracefully', () => {
      const event = new Event('click')
      event.preventDefault = jest.fn()

      // Force an error by making getPlates throw
      mockController.getPlates = jest.fn(() => {
        throw new Error('Test error')
      })

      global.alert = jest.fn()
      const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation()

      mockController.exportToCSV(event)

      expect(consoleErrorSpy).toHaveBeenCalledWith("Error exporting CSV:", expect.any(Error))
      expect(global.alert).toHaveBeenCalledWith("Error exporting CSV. Please try again.")

      consoleErrorSpy.mockRestore()
    })
  })

  describe('exportToPDF', () => {
    test('is defined and callable', () => {
      expect(typeof mockController.exportToPDF).toBe('function')

      const event = new Event('click')
      event.preventDefault = jest.fn()

      // Should not throw when called (will fail trying to import jsPDF, but that's expected)
      expect(() => {
        mockController.exportToPDF(event)
      }).not.toThrow()

      expect(event.preventDefault).toHaveBeenCalled()
    })

    // Note: Full PDF export testing requires jsPDF library and is tested in system tests
    // We verify the method exists and basic structure here
  })

  describe('showToast', () => {
    test('creates a toast element and adds it to DOM', () => {
      const appendChildSpy = jest.spyOn(document.body, 'appendChild')

      mockController.showToast('Test message')

      expect(appendChildSpy).toHaveBeenCalled()

      const toastElement = appendChildSpy.mock.calls[0][0]
      expect(toastElement.textContent).toBe('Test message')
      expect(toastElement.className).toBe('toast-notification')
    })

    test('displays different messages', () => {
      const appendChildSpy = jest.spyOn(document.body, 'appendChild')

      mockController.showToast('Custom message')

      const toastElement = appendChildSpy.mock.calls[0][0]
      expect(toastElement.textContent).toBe('Custom message')
    })

    test('applies correct styling', () => {
      const appendChildSpy = jest.spyOn(document.body, 'appendChild')

      mockController.showToast('Test')

      const toastElement = appendChildSpy.mock.calls[0][0]
      expect(toastElement.style.position).toBe('fixed')
      expect(toastElement.style.zIndex).toBe('9999')
      // backgroundColor is returned as rgb() in jsdom
      expect(toastElement.style.backgroundColor).toMatch(/rgb\(40,\s*167,\s*69\)|#28a745/)
    })
  })
})
