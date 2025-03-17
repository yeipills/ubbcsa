import { Controller } from "@hotwired/stimulus"

/**
 * Quiz Controller
 * 
 * Maneja la funcionalidad principal de los quizzes, incluyendo:
 * - Navegación entre preguntas
 * - Guardado automático de respuestas
 * - Temporizador de quiz
 * - Visualizaciones de progreso
 * - Validación de formularios
 */
export default class extends Controller {
  static targets = [
    "preguntaContainer", "preguntaNav", "navItem", 
    "progressBar", "progressText", "timerDisplay", 
    "formContainer", "saveIndicator", "submitButton",
    "finishButton"
  ]
  
  static values = {
    intentoId: Number,
    quizId: Number,
    tiempoLimite: Number,
    iniciado: Number,
    preguntaActual: Number,
    totalPreguntas: Number,
    respondidas: Number,
    autoSave: { type: Boolean, default: true },
    completado: { type: Boolean, default: false }
  }
  
  connect() {
    // Inicializar estado
    this.ultimaActividad = Date.now()
    this.formCambiado = false
    this.guardarEnProgreso = false
    this.inicializarContador()
    this.inicializarNavegacion()
    
    // Configurar eventos de autoguardado
    if (this.autoSaveValue) {
      this.configurarAutoGuardado()
    }
    
    // Iniciar monitoreo de actividad
    this.actualizarActividad()
    
    // Verificar estado del quiz (si expiró, etc)
    this.verificarEstado()
  }
  
  disconnect() {
    this.detenerContador()
    clearInterval(this.actividadInterval)
    clearInterval(this.autoSaveInterval)
  }
  
  // Métodos de navegación
  
  irAPregunta(event) {
    event.preventDefault()
    const preguntaId = event.currentTarget.dataset.preguntaId
    
    // Verificar si hay cambios sin guardar
    if (this.formCambiado) {
      if (confirm("¿Tienes cambios sin guardar. ¿Deseas continuar sin guardar?")) {
        this.cargarPregunta(preguntaId)
      }
    } else {
      this.cargarPregunta(preguntaId)
    }
  }
  
  cargarPregunta(preguntaId) {
    // Actualizar navegación
    this.navItemTargets.forEach(item => {
      item.classList.remove("activa")
      if (item.dataset.preguntaId === preguntaId) {
        item.classList.add("activa")
      }
    })
    
    // Registrar la vista de la pregunta
    this.registrarVistaPregunta(preguntaId)
    
    // Cargar contenido de la pregunta mediante fetch
    fetch(`/quizzes/${this.quizIdValue}/intentos/${this.intentoIdValue}?pregunta_id=${preguntaId}`, {
      headers: {
        "Accept": "text/html",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    .then(response => response.text())
    .then(html => {
      this.preguntaContainerTarget.innerHTML = html
      this.formCambiado = false
      this.preguntaActualValue = parseInt(preguntaId)
      
      // Actualizar URL sin recargar la página
      history.pushState(
        { preguntaId: preguntaId },
        "",
        `/quizzes/${this.quizIdValue}/intentos/${this.intentoIdValue}?pregunta_id=${preguntaId}`
      )
    })
    .catch(error => {
      console.error("Error cargando pregunta:", error)
    })
  }
  
  // Métodos para el temporizador
  
  inicializarContador() {
    // Obtener tiempo restante inicial
    const tiempoTranscurrido = Math.floor((Date.now() / 1000) - this.iniciadoValue)
    const tiempoLimiteSeg = this.tiempoLimiteValue * 60
    this.tiempoRestante = Math.max(0, tiempoLimiteSeg - tiempoTranscurrido)
    
    // Actualizar display
    this.actualizarDisplayTiempo()
    
    // Iniciar contador
    this.temporizador = setInterval(() => {
      this.tiempoRestante -= 1
      
      if (this.tiempoRestante <= 0) {
        this.tiempoAgotado()
      } else {
        this.actualizarDisplayTiempo()
        
        // Advertencias cuando queda poco tiempo
        if (this.tiempoRestante === 300) { // 5 minutos
          this.advertenciaTiempo("¡Quedan 5 minutos!")
        } else if (this.tiempoRestante === 60) { // 1 minuto
          this.advertenciaTiempo("¡Queda 1 minuto!")
        }
      }
    }, 1000)
  }
  
  actualizarDisplayTiempo() {
    if (!this.hasTimerDisplayTarget) return
    
    const minutos = Math.floor(this.tiempoRestante / 60)
    const segundos = this.tiempoRestante % 60
    
    // Formatear tiempo
    const tiempoFormateado = `${minutos}:${segundos.toString().padStart(2, '0')}`
    this.timerDisplayTarget.textContent = tiempoFormateado
    
    // Clases para advertencias visuales
    this.timerDisplayTarget.classList.remove("text-red-500", "animate-pulse")
    
    if (this.tiempoRestante <= 60) {
      this.timerDisplayTarget.classList.add("text-red-500", "animate-pulse")
    } else if (this.tiempoRestante <= 300) {
      this.timerDisplayTarget.classList.add("text-red-500")
    }
  }
  
  detenerContador() {
    if (this.temporizador) {
      clearInterval(this.temporizador)
    }
  }
  
  advertenciaTiempo(mensaje) {
    // Mostrar alerta visual
    const alerta = document.createElement("div")
    alerta.classList.add("fixed", "top-4", "right-4", "bg-red-600", "text-white", "py-2", "px-4", "rounded-lg", "animate-bounce", "z-50")
    alerta.textContent = mensaje
    document.body.appendChild(alerta)
    
    // Audio de advertencia (opcional)
    const audio = new Audio("/sounds/alert.mp3")
    audio.play().catch(e => console.log("No se pudo reproducir audio de alerta"))
    
    // Eliminar después de 5 segundos
    setTimeout(() => {
      alerta.remove()
    }, 5000)
  }
  
  tiempoAgotado() {
    this.detenerContador()
    
    // Actualizar UI
    if (this.hasTimerDisplayTarget) {
      this.timerDisplayTarget.textContent = "¡Tiempo agotado!"
      this.timerDisplayTarget.classList.add("text-red-500", "font-bold")
    }
    
    // Guardar respuesta actual si hay cambios
    if (this.formCambiado) {
      this.guardarRespuesta()
    }
    
    // Finalizar intento automáticamente
    this.finalizarIntento(true)
  }
  
  // Métodos para autoguardado
  
  configurarAutoGuardado() {
    // Detectar cambios en formularios
    document.addEventListener("change", this.detectarCambiosForm.bind(this))
    document.addEventListener("input", this.detectarCambiosForm.bind(this))
    
    // Autoguardado periódico
    this.autoSaveInterval = setInterval(() => {
      if (this.formCambiado && !this.guardarEnProgreso) {
        this.guardarRespuesta()
      }
    }, 15000) // Cada 15 segundos
  }
  
  detectarCambiosForm(event) {
    // Verificar si el evento proviene de un elemento de formulario dentro del quiz
    if (this.element.contains(event.target)) {
      this.formCambiado = true
      
      // Mostrar indicador de cambios
      if (this.hasSaveIndicatorTarget) {
        this.saveIndicatorTarget.textContent = "Cambios sin guardar"
        this.saveIndicatorTarget.classList.add("text-yellow-500")
        this.saveIndicatorTarget.classList.remove("text-green-500", "hidden")
      }
    }
  }
  
  guardarRespuesta(event) {
    if (event) {
      event.preventDefault()
    }
    
    if (!this.formCambiado || this.guardarEnProgreso || this.completadoValue) {
      return
    }
    
    this.guardarEnProgreso = true
    
    // Actualizar indicador
    if (this.hasSaveIndicatorTarget) {
      this.saveIndicatorTarget.textContent = "Guardando..."
      this.saveIndicatorTarget.classList.remove("text-yellow-500", "text-green-500", "hidden")
      this.saveIndicatorTarget.classList.add("text-blue-500")
    }
    
    // Obtener datos del formulario
    const form = this.element.querySelector("form")
    if (!form) return
    
    const formData = new FormData(form)
    
    // Enviar datos
    fetch(form.action, {
      method: form.method || "POST",
      body: formData,
      headers: {
        "X-Requested-With": "XMLHttpRequest",
        "Accept": "application/json"
      }
    })
    .then(response => response.json())
    .then(data => {
      this.guardarEnProgreso = false
      this.formCambiado = false
      
      // Actualizar indicador
      if (this.hasSaveIndicatorTarget) {
        this.saveIndicatorTarget.textContent = "Guardado correctamente"
        this.saveIndicatorTarget.classList.remove("text-yellow-500", "text-blue-500")
        this.saveIndicatorTarget.classList.add("text-green-500")
        
        // Ocultar después de 3 segundos
        setTimeout(() => {
          this.saveIndicatorTarget.classList.add("hidden")
        }, 3000)
      }
      
      // Actualizar navegación y progreso
      this.actualizarProgreso(data.pregunta_id)
    })
    .catch(error => {
      console.error("Error guardando respuesta:", error)
      this.guardarEnProgreso = false
      
      // Actualizar indicador
      if (this.hasSaveIndicatorTarget) {
        this.saveIndicatorTarget.textContent = "Error al guardar. Reintentar."
        this.saveIndicatorTarget.classList.remove("text-yellow-500", "text-blue-500", "text-green-500")
        this.saveIndicatorTarget.classList.add("text-red-500")
      }
    })
  }
  
  actualizarProgreso(preguntaId) {
    // Actualizar navegación
    this.navItemTargets.forEach(item => {
      if (item.dataset.preguntaId === preguntaId.toString()) {
        item.classList.add("respondida")
      }
    })
    
    // Recalcular número de preguntas respondidas
    const respondidas = this.navItemTargets.filter(item => 
      item.classList.contains("respondida")
    ).length
    
    this.respondidasValue = respondidas
    
    // Actualizar barra de progreso
    if (this.hasProgressBarTarget && this.hasProgressTextTarget) {
      const porcentaje = Math.round((respondidas / this.totalPreguntasValue) * 100)
      this.progressBarTarget.style.width = `${porcentaje}%`
      this.progressTextTarget.textContent = `${porcentaje}%`
    }
    
    // Habilitar botón de finalizar si todas han sido respondidas
    if (this.hasFinishButtonTarget && respondidas === this.totalPreguntasValue) {
      this.finishButtonTarget.disabled = false
      this.finishButtonTarget.classList.remove("opacity-50", "cursor-not-allowed")
      this.finishButtonTarget.classList.add("animate-pulse")
    }
  }
  
  // Métodos para la finalización del intento
  
  finalizarIntento(tiempoExpirado = false) {
    // Confirmar solo si no ha expirado el tiempo
    if (!tiempoExpirado) {
      const preguntasFaltantes = this.totalPreguntasValue - this.respondidasValue
      let mensaje = "¿Estás seguro de que deseas finalizar el intento?"
      
      if (preguntasFaltantes > 0) {
        mensaje += ` Aún tienes ${preguntasFaltantes} pregunta(s) sin responder.`
      }
      
      if (!confirm(mensaje)) {
        return
      }
    }
    
    // Deshabilitar botones para evitar doble envío
    if (this.hasFinishButtonTarget) {
      this.finishButtonTarget.disabled = true
      this.finishButtonTarget.textContent = "Finalizando..."
    }
    
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
    }
    
    // Enviar solicitud para finalizar intento
    fetch(`/quizzes/${this.quizIdValue}/intentos/${this.intentoIdValue}/finalizar`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      body: JSON.stringify({ tiempo_expirado: tiempoExpirado })
    })
    .then(response => {
      if (response.redirected) {
        window.location.href = response.url
      } else {
        return response.json()
          .then(data => {
            if (data.redirect_url) {
              window.location.href = data.redirect_url
            } else {
              console.error("No se recibió URL de redirección")
            }
          })
      }
    })
    .catch(error => {
      console.error("Error finalizando intento:", error)
      alert("Ocurrió un error al finalizar el intento. Por favor, inténtalo de nuevo.")
      
      // Reactivar botones
      if (this.hasFinishButtonTarget) {
        this.finishButtonTarget.disabled = false
        this.finishButtonTarget.textContent = "Finalizar intento"
      }
      
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.disabled = false
      }
    })
  }
  
  // Métodos para monitoreo de actividad
  
  actualizarActividad() {
    this.ultimaActividad = Date.now()
    
    // Configurar monitoreo de actividad
    document.addEventListener("mousemove", () => this.ultimaActividad = Date.now())
    document.addEventListener("keydown", () => this.ultimaActividad = Date.now())
    document.addEventListener("click", () => this.ultimaActividad = Date.now())
    
    // Enviar actualizaciones periódicas al servidor
    this.actividadInterval = setInterval(() => {
      // Verificar si hay actividad reciente (últimos 30 segundos)
      const inactivo = (Date.now() - this.ultimaActividad) > 30000
      
      if (!inactivo && !this.completadoValue) {
        this.enviarActualizacionActividad()
      }
    }, 60000) // Cada minuto
  }
  
  enviarActualizacionActividad() {
    const datos = {
      pregunta_id: this.preguntaActualValue,
      navegador: navigator.userAgent,
      tiempo_restante: this.tiempoRestante
    }
    
    fetch(`/quizzes/${this.quizIdValue}/intentos/${this.intentoIdValue}/registrar_evento`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      body: JSON.stringify({
        tipo: "actividad",
        datos: datos
      })
    }).catch(e => console.log("Error enviando actividad"))
  }
  
  registrarVistaPregunta(preguntaId) {
    fetch(`/quizzes/${this.quizIdValue}/intentos/${this.intentoIdValue}/registrar_evento`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      body: JSON.stringify({
        tipo: "vista_pregunta",
        datos: {
          pregunta_id: preguntaId,
          timestamp: Date.now()
        }
      })
    }).catch(e => console.log("Error registrando vista de pregunta"))
  }
  
  // Métodos para verificación de estado
  
  verificarEstado() {
    // Verificar si el tiempo ha expirado
    if (this.tiempoRestante <= 0 && !this.completadoValue) {
      this.tiempoAgotado()
    }
  }
  
  // Navegación simple entre preguntas
  
  irASiguiente(event) {
    event.preventDefault()
    
    const preguntaActual = this.navItemTargets.findIndex(item => 
      item.classList.contains("activa")
    )
    
    if (preguntaActual < this.navItemTargets.length - 1) {
      const siguientePregunta = this.navItemTargets[preguntaActual + 1]
      const preguntaId = siguientePregunta.dataset.preguntaId
      
      if (this.formCambiado) {
        this.guardarRespuesta()
      }
      
      this.cargarPregunta(preguntaId)
    }
  }
  
  irAAnterior(event) {
    event.preventDefault()
    
    const preguntaActual = this.navItemTargets.findIndex(item => 
      item.classList.contains("activa")
    )
    
    if (preguntaActual > 0) {
      const anteriorPregunta = this.navItemTargets[preguntaActual - 1]
      const preguntaId = anteriorPregunta.dataset.preguntaId
      
      if (this.formCambiado) {
        this.guardarRespuesta()
      }
      
      this.cargarPregunta(preguntaId)
    }
  }
  
  // Inicialización de navegación
  
  inicializarNavegacion() {
    // Marcar pregunta activa
    this.navItemTargets.forEach(item => {
      if (parseInt(item.dataset.preguntaId) === this.preguntaActualValue) {
        item.classList.add("activa")
      }
    })
  }
}