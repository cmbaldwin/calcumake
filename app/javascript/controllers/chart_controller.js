import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chart"
export default class extends Controller {
  static values = {
    type: { type: String, default: "line" },
    data: Object,
    options: { type: Object, default: {} }
  }

  async connect() {
    // Dynamically import Chart.js (lazy-loaded)
    const ChartModule = await import("chart.js")
    this.Chart = ChartModule.default || ChartModule.Chart

    // Register required components
    const {
      CategoryScale,
      LinearScale,
      PointElement,
      LineElement,
      BarElement,
      Title,
      Tooltip,
      Legend,
      Filler
    } = ChartModule

    this.Chart.register(
      CategoryScale,
      LinearScale,
      PointElement,
      LineElement,
      BarElement,
      Title,
      Tooltip,
      Legend,
      Filler
    )

    this.renderChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  renderChart() {
    const ctx = this.element.getContext("2d")

    const defaultOptions = {
      responsive: true,
      maintainAspectRatio: true,
      interaction: {
        mode: "index",
        intersect: false
      },
      plugins: {
        legend: {
          display: true,
          position: "top"
        },
        tooltip: {
          enabled: true,
          backgroundColor: "rgba(0, 0, 0, 0.8)",
          padding: 12,
          titleColor: "#fff",
          bodyColor: "#fff",
          borderColor: "rgba(255, 255, 255, 0.2)",
          borderWidth: 1
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          grid: {
            color: "rgba(0, 0, 0, 0.05)"
          }
        },
        x: {
          grid: {
            display: false
          }
        }
      }
    }

    // Merge custom options with defaults
    const mergedOptions = this.deepMerge(defaultOptions, this.optionsValue)

    this.chart = new this.Chart(ctx, {
      type: this.typeValue,
      data: this.dataValue,
      options: mergedOptions
    })
  }

  // Deep merge utility function
  deepMerge(target, source) {
    const output = Object.assign({}, target)
    if (this.isObject(target) && this.isObject(source)) {
      Object.keys(source).forEach(key => {
        if (this.isObject(source[key])) {
          if (!(key in target))
            Object.assign(output, { [key]: source[key] })
          else
            output[key] = this.deepMerge(target[key], source[key])
        } else {
          Object.assign(output, { [key]: source[key] })
        }
      })
    }
    return output
  }

  isObject(item) {
    return item && typeof item === "object" && !Array.isArray(item)
  }
}
