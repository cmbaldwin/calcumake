/**
 * @jest-environment jsdom
 */

import { useExport } from '../../../../app/javascript/controllers/mixins/export_mixin.js'

describe('Export Mixin', () => {
  // Helper to create a mock controller with the mixin applied
  function createMockController(props = {}) {
    const controller = {
      hasJobNameTarget: false,
      hasExportContentTarget: false,
      hasTotalFilamentCostTarget: false,
      hasTotalElectricityCostTarget: false,
      hasTotalLaborCostTarget: false,
      hasTotalMachineCostTarget: false,
      hasTotalOtherCostsTarget: false,
      hasGrandTotalTarget: false,
      getPlates: jest.fn(() => []),
      getPlateData: jest.fn(() => ({
        printTime: 2.5,
        filaments: [{ weight: 100, pricePerKg: 25 }]
      })),
      getGlobalSettings: jest.fn(() => ({
        powerConsumption: 200,
        machineCost: 500,
        payoffYears: 3,
        prepTime: 0.25,
        postTime: 0.5,
        prepRate: 20,
        postRate: 25
      })),
      calculateFilamentCost: jest.fn(() => 2.5),
      calculateElectricityCost: jest.fn(() => 0.06),
      calculateLaborCost: jest.fn(() => 17.5),
      calculateMachineCost: jest.fn(() => 1.71),
      ...props
    }
    useExport(controller)
    return controller
  }

  describe('updateExportTemplate', () => {
    test('updates job name in export template', () => {
      const jobNameTarget = document.createElement('input')
      jobNameTarget.value = 'Test Export Job'

      const exportContent = document.createElement('div')
      const exportJobName = document.createElement('span')
      exportJobName.setAttribute('data-export-job-name', '')
      exportContent.appendChild(exportJobName)

      const controller = createMockController({
        hasJobNameTarget: true,
        jobNameTarget,
        hasExportContentTarget: true,
        exportContentTarget: exportContent
      })

      controller.updateExportTemplate()

      expect(exportJobName.textContent).toBe('Test Export Job')
    })

    test('updates cost values in export template', () => {
      const exportContent = document.createElement('div')

      const costs = [
        'filament-cost',
        'electricity-cost',
        'labor-cost',
        'machine-cost',
        'other-costs',
        'grand-total'
      ]

      costs.forEach(costId => {
        const element = document.createElement('span')
        element.setAttribute(`data-export-${costId}`, '')
        exportContent.appendChild(element)
      })

      const controller = createMockController({
        hasExportContentTarget: true,
        exportContentTarget: exportContent,
        hasTotalFilamentCostTarget: true,
        totalFilamentCostTarget: { textContent: '$10.50' },
        hasTotalElectricityCostTarget: true,
        totalElectricityCostTarget: { textContent: '$2.25' },
        hasTotalLaborCostTarget: true,
        totalLaborCostTarget: { textContent: '$25.00' },
        hasTotalMachineCostTarget: true,
        totalMachineCostTarget: { textContent: '$5.75' },
        hasTotalOtherCostsTarget: true,
        totalOtherCostsTarget: { textContent: '$8.50' },
        hasGrandTotalTarget: true,
        grandTotalTarget: { textContent: '$52.00' }
      })

      controller.updateExportTemplate()

      expect(exportContent.querySelector('[data-export-filament-cost]').textContent).toBe('$10.50')
      expect(exportContent.querySelector('[data-export-electricity-cost]').textContent).toBe('$2.25')
      expect(exportContent.querySelector('[data-export-labor-cost]').textContent).toBe('$25.00')
      expect(exportContent.querySelector('[data-export-machine-cost]').textContent).toBe('$5.75')
      expect(exportContent.querySelector('[data-export-other-costs]').textContent).toBe('$8.50')
      expect(exportContent.querySelector('[data-export-grand-total]').textContent).toBe('$52.00')
    })

    test('handles missing job name gracefully', () => {
      const exportContent = document.createElement('div')
      const exportJobName = document.createElement('span')
      exportJobName.setAttribute('data-export-job-name', '')
      exportContent.appendChild(exportJobName)

      const controller = createMockController({
        hasJobNameTarget: false,
        hasExportContentTarget: true,
        exportContentTarget: exportContent
      })

      expect(() => controller.updateExportTemplate()).not.toThrow()
      expect(exportJobName.textContent).toBe('Untitled')
    })
  })

  describe('showToast', () => {
    test('creates and displays toast notification', () => {
      jest.useFakeTimers()

      const controller = createMockController()

      controller.showToast('Test message')

      const toast = document.querySelector('.toast-notification')
      expect(toast).toBeDefined()
      expect(toast.textContent).toBe('Test message')
      expect(document.body.contains(toast)).toBe(true)

      // Fast-forward to when toast should be removed
      jest.advanceTimersByTime(3300)

      jest.useRealTimers()
    })

    test('toast contains correct styling', () => {
      const controller = createMockController()

      controller.showToast('Styled message')

      const toast = document.querySelector('.toast-notification')
      expect(toast.style.position).toBe('fixed')
      expect(toast.style.zIndex).toBe('9999')
      // Browser converts hex to rgb, so check for either format
      expect(toast.style.background).toMatch(/(#28a745|rgb\(40,\s*167,\s*69\))/)
    })
  })

  describe('exportToCSV', () => {
    test('generates CSV with correct structure', () => {
      // Mock document.body methods
      const appendChildSpy = jest.spyOn(document.body, 'appendChild')
      const removeChildSpy = jest.spyOn(document.body, 'removeChild')

      // Mock URL.createObjectURL
      global.URL.createObjectURL = jest.fn(() => 'mock-url')

      const jobNameTarget = document.createElement('input')
      jobNameTarget.value = 'CSV Test Job'

      const grandTotalTarget = { textContent: '$52.00' }

      const plateMock = document.createElement('div')

      const controller = createMockController({
        hasJobNameTarget: true,
        jobNameTarget,
        hasGrandTotalTarget: true,
        grandTotalTarget,
        getPlates: jest.fn(() => [plateMock, plateMock])
      })

      const event = { preventDefault: jest.fn() }

      controller.exportToCSV(event)

      expect(event.preventDefault).toHaveBeenCalled()
      expect(appendChildSpy).toHaveBeenCalled()
      expect(removeChildSpy).toHaveBeenCalled()

      const linkElement = appendChildSpy.mock.calls[0][0]
      expect(linkElement.tagName).toBe('A')
      expect(linkElement.download).toContain('CSV_Test_Job')
      expect(linkElement.download).toContain('.csv')

      appendChildSpy.mockRestore()
      removeChildSpy.mockRestore()
    })

    test('handles export errors gracefully', () => {
      const controller = createMockController({
        getPlates: jest.fn(() => { throw new Error('Test error') })
      })

      const event = { preventDefault: jest.fn() }

      // Mock alert
      window.alert = jest.fn()

      controller.exportToCSV(event)

      expect(window.alert).toHaveBeenCalledWith('Error exporting CSV. Please try again.')
    })
  })

  describe('exportToPDF', () => {
    test('prevents default event behavior', async () => {
      const controller = createMockController({
        hasExportContentTarget: true,
        exportContentTarget: document.createElement('div')
      })

      const event = { preventDefault: jest.fn() }

      // Mock the PDF library and html2canvas to avoid actual imports
      const mockPDF = {
        addImage: jest.fn(),
        addPage: jest.fn(),
        save: jest.fn()
      }

      // We can't fully test PDF generation without the actual libraries,
      // but we can test that the event is prevented
      try {
        await controller.exportToPDF(event)
      } catch (error) {
        // Expected to fail due to missing jsPDF import in test
      }

      expect(event.preventDefault).toHaveBeenCalled()
    })
  })
})
