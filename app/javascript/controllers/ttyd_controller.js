import { Controller } from "@hotwired/stimulus"

/**
 * Controlador para la interfaz de ttyd
 * 
 * Este controlador maneja la interacción con el iframe de la terminal ttyd,
 * incluyendo el ajuste de tamaño y la coordinación con el servidor.
 */
export default class extends Controller {
  static targets = ["terminal"]
  static values = {
    sessionId: String,
    containerId: String,
    labId: String
  }

  connect() {
    this.setupResizeHandler()
    this.setupHealthCheck()
  }

  /**
   * Configura el observador de cambios de tamaño para el iframe
   */
  setupResizeHandler() {
    this.resizeObserver = new ResizeObserver(() => {
      this.adjustIframeSize()
    })
    
    this.resizeObserver.observe(this.element)
    
    // Ajuste inicial
    this.adjustIframeSize()
    
    // Ajustar también al cambiar el tamaño de la ventana
    window.addEventListener('resize', this.adjustIframeSize.bind(this))
  }
  
  /**
   * Configura la verificación periódica del estado del contenedor
   */
  setupHealthCheck() {
    if (!this.hasSessionIdValue || !this.hasContainerIdValue) return
    
    // Verificar estado cada 30 segundos
    this.healthCheckInterval = setInterval(() => {
      this.checkContainerHealth()
    }, 30000)
    
    // Verificación inicial después de 5 segundos
    setTimeout(() => this.checkContainerHealth(), 5000)
  }
  
  /**
   * Verifica el estado del contenedor a través de la API
   */
  checkContainerHealth() {
    if (!this.hasSessionIdValue) return
    
    fetch(`/api/terminal/metrics?session_id=${this.sessionIdValue}`)
      .then(response => {
        if (!response.ok) {
          throw new Error(`Error HTTP: ${response.status}`)
        }
        return response.json()
      })
      .then(data => {
        // Verificar que hay métricas válidas
        if (data && typeof data.cpu_usage !== 'undefined') {
          console.log('Contenedor activo:', data)
        } else {
          console.warn('Datos de contenedor no disponibles')
        }
      })
      .catch(error => {
        console.error('Error verificando estado del contenedor:', error)
      })
  }

  /**
   * Ajusta el tamaño del iframe para que ocupe todo el contenedor
   */
  adjustIframeSize() {
    if (!this.hasTerminalTarget) return
    
    const iframe = this.terminalTarget
    const container = this.element.querySelector('.terminal-content') || this.element
    
    if (!container) return
    
    // Establecer dimensiones
    iframe.style.height = `${container.offsetHeight}px`
    iframe.style.width = `${container.offsetWidth}px`
    
    // Forzar un refresco después de un momento para asegurar que los cambios se apliquen
    setTimeout(() => {
      iframe.style.height = `${container.offsetHeight}px`
      iframe.style.width = `${container.offsetWidth}px`
    }, 100)
  }
  
  /**
   * Recarga el iframe con la terminal
   */
  refreshTerminal() {
    if (!this.hasTerminalTarget) return
    
    const iframe = this.terminalTarget
    const currentSrc = iframe.src
    
    // Añadir un parámetro temporal para evitar cache
    iframe.src = currentSrc.includes('?') 
      ? `${currentSrc}&t=${Date.now()}` 
      : `${currentSrc}?t=${Date.now()}`
  }
  
  /**
   * Activa el modo de pantalla completa para la terminal
   */
  toggleFullscreen() {
    if (!document.fullscreenElement) {
      this.element.requestFullscreen().catch(err => {
        console.error(`Error al intentar modo pantalla completa: ${err.message}`)
      })
    } else {
      document.exitFullscreen()
    }
  }

  disconnect() {
    // Limpieza de observadores y temporizadores
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
    }
    
    if (this.healthCheckInterval) {
      clearInterval(this.healthCheckInterval)
    }
    
    // Eliminar listeners
    window.removeEventListener('resize', this.adjustIframeSize.bind(this))
  }
}