// app/javascript/controllers/terminal_controller.js
import { Controller } from "@hotwired/stimulus"
import TerminalChannel from "./channels/terminal_channel"

export default class extends Controller {
  static targets = ["terminal", "history", "cpu", "memory", "network"]
  static values = { 
    sessionId: String,
    containerId: String 
  }

  connect() {
    this.setupResizeHandler()
    this.setupTerminalChannel()
    this.updateMetricsInterval = setInterval(() => this.updateMetrics(), 5000)
  }

  setupResizeHandler() {
    this.resizeObserver = new ResizeObserver(() => {
      this.adjustIframeSize()
    })
    
    this.resizeObserver.observe(this.element)
  }

  setupTerminalChannel() {
    if (!this.sessionIdValue) return
    
    this.channel = new TerminalChannel(this.sessionIdValue, ({ event, data }) => {
      if (event === 'message') {
        this.handleChannelMessage(data)
      }
    })
  }

  handleChannelMessage(data) {
    // Manejar mensajes del canal
    if (data.type === 'command' && this.hasHistoryTarget) {
      this.addToHistory(data.content, 'command')
    } else if (data.type === 'output' && this.hasHistoryTarget) {
      this.addToHistory(data.content, 'output')
    } else if (data.type === 'metrics') {
      this.updateMetricsDisplay(data.metrics)
    }
  }

  addToHistory(content, type) {
    const historyEntry = document.createElement('div')
    historyEntry.className = type === 'command' ? 'text-green-400 mt-1' : 'text-gray-400 ml-2'
    historyEntry.textContent = type === 'command' ? `$ ${content}` : content
    
    this.historyTarget.prepend(historyEntry)
    
    // Limitar a 50 entradas
    if (this.historyTarget.children.length > 50) {
      this.historyTarget.removeChild(this.historyTarget.lastChild)
    }
  }

  updateMetrics() {
    if (!this.sessionIdValue || !this.containerId) return

    fetch(`/api/terminal/metrics?session_id=${this.sessionIdValue}`)
      .then(response => response.json())
      .then(data => {
        this.updateMetricsDisplay(data)
      })
      .catch(error => {
        console.error('Error obteniendo métricas:', error)
      })
  }

  updateMetricsDisplay(metrics) {
    if (this.hasCpuTarget) {
      this.cpuTarget.textContent = `${metrics.cpu_usage || 0}%`
    }
    
    if (this.hasMemoryTarget) {
      this.memoryTarget.textContent = `${metrics.memory_usage || 0}%`
    }
    
    if (this.hasNetworkTarget) {
      this.networkTarget.textContent = `↓${metrics.network_received || 0} KB/s ↑${metrics.network_sent || 0} KB/s`
    }
  }

  adjustIframeSize() {
    if (!this.hasTerminalTarget) return
    
    const iframe = this.terminalTarget
    const container = this.element
    
    // Asegurarse de que el iframe ocupe todo el contenedor
    iframe.style.height = `${container.offsetHeight}px`
    iframe.style.width = `${container.offsetWidth}px`
    
    // Forzar un refresco del layout
    setTimeout(() => {
      iframe.style.height = `${container.offsetHeight}px`
      iframe.style.width = `${container.offsetWidth}px`
    }, 100)
  }

  disconnect() {
    if (this.channel) {
      this.channel.disconnect()
    }
    
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
    }
    
    if (this.updateMetricsInterval) {
      clearInterval(this.updateMetricsInterval)
    }
  }
}