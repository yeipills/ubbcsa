import { Controller } from "@hotwired/stimulus"

/**
 * Quiz Timer Controller
 * 
 * Controla el temporizador para quizzes con tiempo límite.
 * Características:
 * - Cuenta regresiva visual
 * - Alertas visuales y sonoras
 * - Finalización automática al expirar
 * - Protección contra manipulación del temporizador
 */
export default class extends Controller {
  static targets = ["display", "progressBar", "timeText"]
  
  static values = {
    tiempoLimite: Number, // en minutos
    iniciadoEn: Number,   // timestamp UNIX
    intentoId: Number,
    quizId: Number,
    finalizable: { type: Boolean, default: true }
  }
  
  connect() {
    // Valores iniciales
    this.segundosTranscurridos = Math.floor((Date.now() / 1000) - this.iniciadoEnValue)
    this.segundosTotales = this.tiempoLimiteValue * 60
    this.segundosRestantes = Math.max(0, this.segundosTotales - this.segundosTranscurridos)
    
    // Verificar si el tiempo ya expiró
    if (this.segundosRestantes <= 0 && this.finalizableValue) {
      this.tiempoExpirado()
      return
    }
    
    // Iniciar temporizador
    this.actualizarInterfaz()
    this.iniciarTemporizador()
    
    // Validación de seguridad
    this.validarTiempoServidor()
    
    // Almacenar tiempo en sesión para validación contra manipulación
    sessionStorage.setItem('quiz_timer_start', this.iniciadoEnValue.toString())
    sessionStorage.setItem('quiz_timer_client_start', Math.floor(Date.now() / 1000).toString())
  }
  
  disconnect() {
    this.detenerTemporizador()
  }
  
  iniciarTemporizador() {
    this.temporizador = setInterval(() => {
      this.segundosTranscurridos += 1
      this.segundosRestantes = Math.max(0, this.segundosTotales - this.segundosTranscurridos)
      
      this.actualizarInterfaz()
      
      // Verificar alertas y expiración
      this.verificarAlertas()
      
      if (this.segundosRestantes <= 0 && this.finalizableValue) {
        this.tiempoExpirado()
      }
    }, 1000)
  }
  
  detenerTemporizador() {
    if (this.temporizador) {
      clearInterval(this.temporizador)
    }
    
    if (this.validacionTimer) {
      clearInterval(this.validacionTimer)
    }
  }
  
  actualizarInterfaz() {
    // Actualizar texto de tiempo
    if (this.hasTimeTextTarget) {
      const minutos = Math.floor(this.segundosRestantes / 60)
      const segundos = this.segundosRestantes % 60
      this.timeTextTarget.textContent = `${minutos}:${segundos.toString().padStart(2, '0')}`
    }
    
    // Actualizar barra de progreso
    if (this.hasProgressBarTarget) {
      const porcentaje = (this.segundosRestantes / this.segundosTotales) * 100
      this.progressBarTarget.style.width = `${porcentaje}%`
      
      // Cambiar clases de color según tiempo restante
      this.progressBarTarget.classList.remove('bg-red-500', 'bg-yellow-500', 'bg-green-500')
      
      if (porcentaje < 25) {
        this.progressBarTarget.classList.add('bg-red-500')
      } else if (porcentaje < 50) {
        this.progressBarTarget.classList.add('bg-yellow-500')
      } else {
        this.progressBarTarget.classList.add('bg-green-500')
      }
    }
    
    // Actualizar contenedor principal
    if (this.segundosRestantes < 60) {
      // Último minuto - animación de pulso
      this.element.classList.add('animate-pulse', 'text-red-500', 'font-bold')
    } else if (this.segundosRestantes < 300) {
      // Últimos 5 minutos - alerta visual
      this.element.classList.add('text-red-500', 'font-bold')
      this.element.classList.remove('animate-pulse')
    } else {
      this.element.classList.remove('animate-pulse', 'text-red-500', 'font-bold')
    }
  }
  
  verificarAlertas() {
    // Alertas en momentos específicos
    const alertPoints = [
      { tiempo: 300, mensaje: '¡Quedan 5 minutos!' },
      { tiempo: 60, mensaje: '¡Queda 1 minuto!' },
      { tiempo: 30, mensaje: '¡Quedan 30 segundos!' },
      { tiempo: 10, mensaje: '¡Quedan 10 segundos!' }
    ]
    
    // Verificar cada punto de alerta
    alertPoints.forEach(point => {
      if (this.segundosRestantes === point.tiempo) {
        this.mostrarAlerta(point.mensaje)
      }
    })
  }
  
  mostrarAlerta(mensaje) {
    // Crear elemento de alerta
    const alerta = document.createElement('div')
    alerta.classList.add(
      'fixed', 'top-4', 'left-1/2', 'transform', '-translate-x-1/2',
      'bg-red-600', 'text-white', 'py-2', 'px-4', 'rounded-lg',
      'shadow-lg', 'z-50', 'animate-bounce', 'text-center', 'font-bold'
    )
    alerta.textContent = mensaje
    document.body.appendChild(alerta)
    
    // Reproducir sonido de alerta
    try {
      const audio = new Audio('/sounds/alert.mp3')
      audio.play().catch(e => console.log('No se pudo reproducir el audio'))
    } catch (e) {
      console.log('Error reproduciendo audio', e)
    }
    
    // Eliminar alerta después de 3 segundos
    setTimeout(() => {
      alerta.classList.add('opacity-0', 'transition-opacity', 'duration-500')
      setTimeout(() => {
        document.body.removeChild(alerta)
      }, 500)
    }, 3000)
  }
  
  tiempoExpirado() {
    // Detener temporizador
    this.detenerTemporizador()
    
    // Actualizar interfaz
    if (this.hasTimeTextTarget) {
      this.timeTextTarget.textContent = '0:00'
      this.timeTextTarget.classList.add('text-red-500', 'font-bold')
    }
    
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = '0%'
      this.progressBarTarget.classList.add('bg-red-500')
    }
    
    // Mostrar alerta principal
    this.mostrarAlerta('¡TIEMPO AGOTADO!')
    
    // Finalizar intento automáticamente
    if (this.finalizableValue) {
      this.finalizarIntentoExpirado()
    }
  }
  
  finalizarIntentoExpirado() {
    // Mostrar modal de finalización
    const modal = document.createElement('div')
    modal.classList.add(
      'fixed', 'inset-0', 'bg-gray-900', 'bg-opacity-90', 'z-50',
      'flex', 'items-center', 'justify-center', 'p-4'
    )
    
    modal.innerHTML = `
      <div class="bg-gray-800 rounded-lg p-6 max-w-md w-full text-center shadow-xl border border-red-500">
        <h2 class="text-xl font-bold text-white mb-4">¡Tiempo agotado!</h2>
        <p class="text-gray-300 mb-6">El tiempo límite para completar este quiz ha terminado. Estamos finalizando tu intento automáticamente.</p>
        <div class="flex justify-center">
          <div class="loader animate-spin h-8 w-8 border-4 border-red-500 border-t-transparent rounded-full"></div>
        </div>
        <p class="text-gray-400 mt-4">Por favor espera mientras se guardan tus respuestas...</p>
      </div>
    `
    
    document.body.appendChild(modal)
    
    // Enviar finalización al servidor
    fetch(`/quizzes/${this.quizIdValue}/intentos/${this.intentoIdValue}/finalizar`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        tiempo_expirado: true
      })
    })
    .then(response => {
      if (response.redirected) {
        window.location.href = response.url
      } else {
        return response.json().then(data => {
          if (data.redirect_url) {
            window.location.href = data.redirect_url
          } else {
            console.error('No se recibió URL de redirección')
            window.location.reload()
          }
        })
      }
    })
    .catch(error => {
      console.error('Error finalizando intento:', error)
      alert('Ocurrió un error al finalizar el intento. La página se recargará.')
      window.location.reload()
    })
  }
  
  // Validación de seguridad para evitar manipulación del temporizador
  validarTiempoServidor() {
    // Verificar cada 30 segundos que el cliente no manipule el tiempo
    this.validacionTimer = setInterval(() => {
      fetch(`/quizzes/${this.quizIdValue}/intentos/${this.intentoIdValue}/verificar_tiempo`, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          cliente_tiempo_restante: this.segundosRestantes,
          cliente_inicio: sessionStorage.getItem('quiz_timer_client_start'),
          servidor_inicio: this.iniciadoEnValue
        })
      })
      .then(response => response.json())
      .then(data => {
        // Si hay una diferencia de más de 10 segundos, sincronizar con el servidor
        if (data.servidor_tiempo_restante && 
            Math.abs(data.servidor_tiempo_restante - this.segundosRestantes) > 10) {
          
          console.log('Sincronizando tiempo con servidor')
          this.segundosRestantes = data.servidor_tiempo_restante
          this.segundosTranscurridos = this.segundosTotales - this.segundosRestantes
          this.actualizarInterfaz()
        }
        
        // Si el servidor indica que el tiempo expiró
        if (data.expirado && this.finalizableValue) {
          this.tiempoExpirado()
        }
      })
      .catch(error => {
        console.error('Error validando tiempo:', error)
      })
    }, 30000) // Cada 30 segundos
  }
}