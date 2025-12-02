// Manual mock for jsPDF library
// jsPDF is loaded via importmap in production, not available in Jest environment

export const jsPDF = jest.fn().mockImplementation(() => ({
  addImage: jest.fn(),
  addPage: jest.fn(),
  save: jest.fn()
}))
