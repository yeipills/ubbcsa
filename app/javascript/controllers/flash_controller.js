// app/javascript/controllers/flash_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    autoClose: { type: Boolean, default: true },
    duration: { type: Number, default: 5000 }
  }

  connect() {
    console.log("Flash controller connected!")
    
    if (this.autoCloseValue !== false) {
      this.timeout = setTimeout(() => {
        console.log("Attempting auto-close...")
        this.close()
      }, this.durationValue || 5000)
    }
  }

  close(event) {
    console.log("Close method called!")
    if (event) event.preventDefault()
    
    // Cancelar el timeout si existe
    if (this.timeout) {
      clearTimeout(this.timeout)
      this.timeout = null
    }
    
    // Añadir clase para animación de salida
    this.element.classList.add('animate-fade-out')
    
    // Remover después de que termine la animación
    setTimeout(() => {
      console.log("Removing element...")
      if (this.element && document.body.contains(this.element)) {
        this.element.remove()
      }
    }, 300)
  }

  disconnect() {
    console.log("Flash controller disconnected!")
    if (this.timeout) {
      clearTimeout(this.timeout)
      this.timeout = null
    }
  }
}