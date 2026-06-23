import { Controller } from "@hotwired/stimulus"

// Renders spinning procedural wireframe 3D models using Three.js.
// Fades between different geometries every 5 seconds.
export default class extends Controller {
  static targets = ["renderCanvas", "modelLabel"]

  async connect() {
    try {
      const THREE = await import("three")
      this.THREE = THREE
      this.initScene()
      this.createModels()
      this.showModel(0)
      this.animate()
      this.startCycling()
      this.setupResize()
    } catch (e) {
      console.warn("Three.js not available, showing fallback:", e.message)
      this.showFallback()
    }
  }

  disconnect() {
    if (this.animationId) cancelAnimationFrame(this.animationId)
    if (this.cycleTimer) clearInterval(this.cycleTimer)
    if (this.resizeObserver) this.resizeObserver.disconnect()
    if (this.renderer) {
      this.renderer.dispose()
      this.renderer.forceContextLoss()
    }
  }

  initScene() {
    const THREE = this.THREE
    const canvas = this.renderCanvasTarget
    const container = canvas.parentElement

    this.scene = new THREE.Scene()

    const width = container.clientWidth
    const height = container.clientHeight

    this.camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 100)
    this.camera.position.set(0, 1, 4)
    this.camera.lookAt(0, 0, 0)

    this.renderer = new THREE.WebGLRenderer({
      canvas: canvas,
      antialias: true,
      alpha: true
    })
    this.renderer.setSize(width, height)
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
    this.renderer.setClearColor(0x000000, 0)
  }

  createModels() {
    const THREE = this.THREE
    this.models = []
    this.modelNames = []

    const lineMaterial = new THREE.LineBasicMaterial({
      color: 0x444444,
      transparent: true,
      opacity: 0
    })

    // 1. Boat hull (Benchy-like)
    const boatProfile = []
    for (let i = 0; i <= 20; i++) {
      const t = i / 20
      const x = 0.3 + 0.7 * Math.sin(t * Math.PI) * (1 - t * 0.3)
      const y = t * 2 - 1
      boatProfile.push(new THREE.Vector2(x, y))
    }
    const boatGeo = new THREE.LatheGeometry(boatProfile, 24)
    const boatEdges = new THREE.EdgesGeometry(boatGeo, 15)
    const boat = new THREE.LineSegments(boatEdges, lineMaterial.clone())
    this.models.push(boat)
    this.modelNames.push("boat")

    // 2. Vase
    const vaseProfile = []
    for (let i = 0; i <= 30; i++) {
      const t = i / 30
      const r = 0.3 + 0.5 * Math.sin(t * Math.PI * 1.5) * (0.5 + 0.5 * t)
      const y = t * 2 - 1
      vaseProfile.push(new THREE.Vector2(r, y))
    }
    const vaseGeo = new THREE.LatheGeometry(vaseProfile, 32)
    const vaseEdges = new THREE.EdgesGeometry(vaseGeo, 15)
    const vase = new THREE.LineSegments(vaseEdges, lineMaterial.clone())
    this.models.push(vase)
    this.modelNames.push("vase")

    // 3. Gear / Torus
    const torusGeo = new THREE.TorusGeometry(0.7, 0.25, 12, 36)
    const torusEdges = new THREE.EdgesGeometry(torusGeo, 15)
    const torus = new THREE.LineSegments(torusEdges, lineMaterial.clone())
    this.models.push(torus)
    this.modelNames.push("gear")

    // 4. Layered cube
    const boxGeo = new THREE.BoxGeometry(1.2, 1.2, 1.2, 4, 4, 4)
    const boxEdges = new THREE.EdgesGeometry(boxGeo, 1)
    const cube = new THREE.LineSegments(boxEdges, lineMaterial.clone())
    this.models.push(cube)
    this.modelNames.push("cube")

    // 5. Organic (icosahedron)
    const icoGeo = new THREE.IcosahedronGeometry(1, 1)
    const icoEdges = new THREE.EdgesGeometry(icoGeo, 1)
    const organic = new THREE.LineSegments(icoEdges, lineMaterial.clone())
    this.models.push(organic)
    this.modelNames.push("organic")

    // Add all to scene but hide them
    this.models.forEach(m => {
      m.visible = false
      this.scene.add(m)
    })

    this.currentIndex = 0
    this.transitioning = false
  }

  showModel(index) {
    const model = this.models[index]
    model.visible = true
    model.material.opacity = 1

    if (this.hasModelLabelTarget) {
      const key = this.modelNames[index]
      this.modelLabelTarget.textContent = key
    }
  }

  animate() {
    this.animationId = requestAnimationFrame(() => this.animate())

    const active = this.models[this.currentIndex]
    if (active && active.visible) {
      active.rotation.y += 0.005
      active.rotation.x += 0.001
    }

    this.renderer.render(this.scene, this.camera)
  }

  startCycling() {
    this.cycleTimer = setInterval(() => this.fadeToNext(), 5000)
  }

  fadeToNext() {
    if (this.transitioning) return
    this.transitioning = true

    const current = this.models[this.currentIndex]
    const nextIndex = (this.currentIndex + 1) % this.models.length
    const next = this.models[nextIndex]

    // Fade out current
    const fadeOut = () => {
      current.material.opacity -= 0.05
      if (current.material.opacity > 0) {
        requestAnimationFrame(fadeOut)
      } else {
        current.visible = false
        current.material.opacity = 0
        this.currentIndex = nextIndex

        // Reset rotation for variety
        next.rotation.y = 0
        next.rotation.x = 0
        next.visible = true
        next.material.opacity = 0

        if (this.hasModelLabelTarget) {
          this.modelLabelTarget.textContent = this.modelNames[nextIndex]
        }

        // Fade in next
        const fadeIn = () => {
          next.material.opacity += 0.05
          if (next.material.opacity < 1) {
            requestAnimationFrame(fadeIn)
          } else {
            next.material.opacity = 1
            this.transitioning = false
          }
        }
        fadeIn()
      }
    }
    fadeOut()
  }

  setupResize() {
    this.resizeObserver = new ResizeObserver(entries => {
      for (const entry of entries) {
        const { width, height } = entry.contentRect
        if (width > 0 && height > 0) {
          this.camera.aspect = width / height
          this.camera.updateProjectionMatrix()
          this.renderer.setSize(width, height)
        }
      }
    })
    this.resizeObserver.observe(this.renderCanvasTarget.parentElement)
  }

  showFallback() {
    const container = this.renderCanvasTarget.parentElement
    this.renderCanvasTarget.style.display = "none"
    container.innerHTML = `
      <div class="model-fallback">
        <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
          <polygon points="50,10 90,35 90,75 50,100 10,75 10,35" fill="none" stroke="#333" stroke-width="0.5"/>
          <line x1="50" y1="10" x2="50" y2="100" stroke="#333" stroke-width="0.5"/>
          <line x1="10" y1="35" x2="90" y2="75" stroke="#333" stroke-width="0.5"/>
          <line x1="90" y1="35" x2="10" y2="75" stroke="#333" stroke-width="0.5"/>
        </svg>
      </div>
    `
  }
}
