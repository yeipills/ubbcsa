import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["terminal"]

  connect() {
    this.setupResizeHandler()
  }

  setupResizeHandler() {
    const resizeObserver = new ResizeObserver(() => {
      this.adjustIframeSize()
    })
    
    resizeObserver.observe(this.element)
  }

  adjustIframeSize() {
    const iframe = this.terminalTarget
    const container = this.element
    iframe.style.height = `${container.offsetHeight}px`
    iframe.style.width = `${container.offsetWidth}px`
  }

  disconnect() {
    // Limpieza si es necesaria
  }
}