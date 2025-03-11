// app/javascript/controllers/quiz_timer_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "progress"]
  static values = { 
    duration: Number,
    warningThreshold: { type: Number, default: 300 }, // 5 minutos
    criticalThreshold: { type: Number, default: 60 },  // 1 minuto
    autoSaveInterval: { type: Number, default: 30 }    // 30 segundos
  }

  connect() {
    // Inicializar tiempo restante
    this.remaining = this.durationValue
    
    // Iniciar temporizador
    this.startTimer()
    
    // Configurar autoguardado
    this.setupAutoSave()
    
    // Registrar evento para finalización automática
    this.handleFormSubmit = this.handleFormSubmit.bind(this)
    document.addEventListener("submit", this.handleFormSubmit)
    
    // Agregar detección de cambio de foco
    this.visibilityHandler = this.handleVisibilityChange.bind(this)
    document.addEventListener("visibilitychange", this.visibilityHandler)
  }

  startTimer() {
    this.timer = setInterval(() => {
      this.remaining -= 1
      this.updateDisplay()
      this.updateProgress()
      this.checkThresholds()
      
      if (this.remaining <= 0) {
        this.timeUp()
      }
    }, 1000)
  }
  
  updateDisplay() {
    const minutes = Math.floor(this.remaining / 60)
    const seconds = this.remaining % 60
    this.displayTarget.textContent = `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`
  }
  
  updateProgress() {
    const percentage = (this.remaining / this.durationValue) * 100
    this.progressTarget.style.width = `${percentage}%`
  }
  
  checkThresholds() {
    // Comprobar umbral de advertencia
    if (this.remaining <= this.warningThresholdValue && !this.warningState) {
      this.setWarningState()
    }
    
    // Comprobar umbral crítico
    if (this.remaining <= this.criticalThresholdValue && !this.criticalState) {
      this.setCriticalState()
    }
  }
  
  setWarningState() {
    this.warningState = true
    this.progressTarget.classList.remove('bg-blue-500')
    this.progressTarget.classList.add('bg-yellow-500')
    this.displayTarget.classList.add('text-yellow-400')
    
    // Notificar al usuario
    this.showNotification("Advertencia", `Quedan ${Math.floor(this.remaining / 60)} minutos.`)
  }
  
  setCriticalState() {
    this.criticalState = true
    this.progressTarget.classList.remove('bg-yellow-500')
    this.progressTarget.classList.add('bg-red-500')
    this.displayTarget.classList.add('text-red-400', 'animate-pulse')
    
    // Notificar al usuario
    this.showNotification("¡Tiempo crítico!", "Menos de un minuto restante.")
  }
  
  timeUp() {
    clearInterval(this.timer)
    clearInterval(this.autoSaveTimer)
    
    // Notificar al usuario
    this.showNotification("¡Tiempo agotado!", "El intento se finalizará automáticamente.")
    
    // Finalizar intento automáticamente
    this.finalizeAttempt()
  }
  
  showNotification(title, message) {
    if ('Notification' in window && Notification.permission === 'granted') {
      new Notification(title, { body: message })
    } else {
      // Mostrar notificación en la interfaz
      const notification = document.createElement('div')
      notification.className = 'fixed bottom-4 right-4 bg-gray-800 border border-gray-700 p-4 rounded-lg shadow-lg z-50'
      notification.innerHTML = `
        <h4 class="font-bold text-white">${title}</h4>
        <p class="text-gray-300">${message}</p>
      `
      document.body.appendChild(notification)
      
      // Eliminar notificación después de 5 segundos
      setTimeout(() => {
        notification.remove()
      }, 5000)
    }
  }
  
  setupAutoSave() {
    this.autoSaveTimer = setInterval(() => {
      this.autoSave()
    }, this.autoSaveIntervalValue * 1000)
  }
  
  autoSave() {
    const form = document.querySelector('form')
    if (form) {
      // Disparar evento personalizado para autoguardado
      const event = new CustomEvent('quiz:autosave')
      form.dispatchEvent(event)
      
      // Añadir mensaje temporal de autoguardado
      const autoSaveMessage = document.createElement('div')
      autoSaveMessage.className = 'fixed bottom-4 left-4 bg-green-900/80 text-green-300 px-3 py-1 rounded-lg text-sm z-50'
      autoSaveMessage.textContent = 'Guardando respuesta...'
      document.body.appendChild(autoSaveMessage)
      
      // Desaparecer mensaje después de 2 segundos
      setTimeout(() => {
        autoSaveMessage.remove()
      }, 2000)
    }
  }
  
  finalizeAttempt() {
    // Buscar formulario de finalización o crear uno
    const existingForm = document.querySelector('form[action*="finalizar"]')
    
    if (existingForm) {
      existingForm.submit()
    } else {
      // Crear formulario dinámicamente
      const form = document.createElement('form')
      form.method = 'POST'
      
      // Extraer quiz_id e intento_id de la URL
      const pathParts = window.location.pathname.split('/')
      const quizId = pathParts[2]
      const intentoId = pathParts[4]
      
      form.action = `/quizzes/${quizId}/intentos/${intentoId}/finalizar`
      
      // Añadir token CSRF
      const csrfToken = document.querySelector('meta[name="csrf-token"]').content
      const csrfInput = document.createElement('input')
      csrfInput.type = 'hidden'
      csrfInput.name = 'authenticity_token'
      csrfInput.value = csrfToken
      
      form.appendChild(csrfInput)
      document.body.appendChild(form)
      form.submit()
    }
  }
  
  handleFormSubmit(event) {
    // Guardar tiempo restante en sessionStorage al enviar formulario
    if (event.target.closest('form')) {
      sessionStorage.setItem('quiz_remaining_time', this.remaining)
    }
  }
  
  // Nuevo método para detectar cambio de foco
  handleVisibilityChange(e) {
    if (document.hidden) {
      // Registrar evento de cambio de foco
      this.registrarEvento('cambio_foco', { 
        timestamp: new Date().toISOString(),
        tiempo_restante: this.remaining 
      })
      
      // Opcional: Mostrar advertencia al volver
      document.addEventListener('visibilitychange', () => {
        if (!document.hidden) {
          this.showNotification('Advertencia', 'Se ha detectado que abandonaste la ventana del quiz. Esta acción ha quedado registrada.')
        }
      }, { once: true })
    }
  }
  
  // Método para registrar eventos de seguridad
  registrarEvento(tipo, datos) {
    // Extraer IDs del elemento o de data attributes
    const intentoId = this.element.dataset.intentoId
    const quizId = this.element.dataset.quizId
    
    if (!intentoId || !quizId) {
      console.error('No se pudo determinar el ID del intento o quiz')
      return
    }
    
    fetch(`/quizzes/${quizId}/intentos/${intentoId}/registrar_evento`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        tipo: tipo,
        datos: datos
      })
    })
    .then(response => {
      if (!response.ok) {
        console.error('Error al registrar evento de seguridad')
      }
    })
    .catch(error => {
      console.error('Error de conexión al registrar evento:', error)
    })
  }

  disconnect() {
    if (this.timer) {
      clearInterval(this.timer)
    }
    
    if (this.autoSaveTimer) {
      clearInterval(this.autoSaveTimer)
    }
    
    document.removeEventListener("submit", this.handleFormSubmit)
    document.removeEventListener("visibilitychange", this.visibilityHandler)
  }
}