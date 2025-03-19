import { Controller } from "@hotwired/stimulus"
import { subscribeToNotificaciones } from "../channels/notificaciones_channel"

export default class extends Controller {
  static targets = [
    "contador", 
    "dropdown", 
    "lista", 
    "toggleButton", 
    "toast",
    "notificacion"
  ]
  
  static values = {
    usuarioId: Number,
    soundEnabled: { type: Boolean, default: true }
  }

  connect() {
    this.isOpen = false
    this.setupChannel()
    this.actualizarContador()
    
    // Comprobar notificaciones cada minuto
    this.reloadInterval = setInterval(() => {
      this.reloadNotifications()
    }, 60000)
    
    // Iniciar inmediatamente
    this.reloadNotifications()
  }
  
  disconnect() {
    if (this.reloadInterval) {
      clearInterval(this.reloadInterval)
    }
  }
  
  setupChannel() {
    // Configurar canal de notificaciones en tiempo real
    subscribeToNotificaciones(this.usuarioIdValue, {
      onReceived: (data) => {
        // Mostrar notificacin toast
        this.mostrarToast(data)
        
        // Actualizar contador y lista si est abierta
        this.reloadNotifications()
        
        // Reproducir sonido si est habilitado
        if (this.soundEnabledValue) {
          this.playNotificationSound()
        }
      }
    })
  }
  
  toggle(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    
    console.log("Toggle notificaciones dropdown")
    
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }
  
  open() {
    console.log("Abriendo dropdown de notificaciones")
    // Abrir dropdown
    this.dropdownTarget.classList.remove('hidden')
    this.isOpen = true
    
    // Actualizar notificaciones al abrir
    this.reloadNotifications()
    
    // Añadir listener para cerrar al hacer clic fuera
    document.addEventListener('click', this.closeOnClickOutside)
  }
  
  close() {
    this.dropdownTarget.classList.add('hidden')
    this.isOpen = false
    
    // Eliminar listener
    document.removeEventListener('click', this.closeOnClickOutside)
  }
  
  closeOnClickOutside = (event) => {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
  
  reloadNotifications() {
    fetch('/notificaciones/no_leidas')
      .then(response => response.json())
      .then(data => {
        this.actualizarContador(data.count)
        this.actualizarLista(data.notificaciones)
      })
      .catch(error => console.error('Error cargando notificaciones:', error))
  }
  
  actualizarContador(count) {
    if (this.hasContadorTarget) {
      const contador = count || 0
      
      // Actualizar nmero
      this.contadorTarget.textContent = contador
      
      // Mostrar/ocultar segn haya notificaciones
      if (contador > 0) {
        this.contadorTarget.classList.remove('hidden')
      } else {
        this.contadorTarget.classList.add('hidden')
      }
    }
  }
  
  actualizarLista(notificaciones) {
    if (this.hasListaTarget && notificaciones) {
      // Limpiar lista actual
      this.listaTarget.innerHTML = ''
      
      if (notificaciones.length === 0) {
        // Mostrar mensaje de no hay notificaciones
        const emptyItem = document.createElement('div')
        emptyItem.className = 'py-4 px-4 text-center text-gray-400'
        emptyItem.textContent = 'No tienes notificaciones sin leer'
        this.listaTarget.appendChild(emptyItem)
      } else {
        // Aadir cada notificacin
        notificaciones.forEach(notif => {
          const item = this.crearItemNotificacion(notif)
          this.listaTarget.appendChild(item)
        })
      }
    }
  }
  
  crearItemNotificacion(notif) {
    const item = document.createElement('div')
    item.className = 'border-b border-gray-700 hover:bg-gray-800'
    item.setAttribute('data-notificacion-id', notif.id)
    
    // Determinar el icono segn el tipo y nivel
    let iconClass = ''
    switch (notif.tipo) {
      case 'laboratorio':
        iconClass = 'fas fa-flask text-blue-500'
        break
      case 'curso':
        iconClass = 'fas fa-book text-green-500'
        break
      case 'quiz':
        iconClass = 'fas fa-question-circle text-yellow-500'
        break
      case 'logro':
        iconClass = 'fas fa-trophy text-purple-500'
        break
      case 'alerta_seguridad':
        iconClass = 'fas fa-exclamation-triangle text-red-500'
        break
      default:
        iconClass = 'fas fa-bell text-gray-400'
    }
    
    item.innerHTML = `
      <a href="/notificaciones/${notif.id}" class="block p-4">
        <div class="flex items-start">
          <div class="flex-shrink-0">
            <i class="${iconClass} text-lg"></i>
          </div>
          <div class="ml-3 flex-1">
            <p class="text-sm font-medium text-white">${notif.titulo}</p>
            <p class="text-sm text-gray-400 truncate">${notif.contenido}</p>
            <p class="text-xs text-gray-500 mt-1">${notif.tiempo_transcurrido}</p>
          </div>
          <button class="ml-2 text-gray-400 hover:text-white" data-action="notificaciones#marcarLeida" data-notificacion-id="${notif.id}">
            <i class="fas fa-check"></i>
          </button>
        </div>
      </a>
    `
    
    return item
  }
  
  marcarLeida(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const id = event.currentTarget.dataset.notificacionId
    
    fetch(`/notificaciones/${id}/marcar_como_leida`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Eliminar de la lista
        const item = this.element.querySelector(`[data-notificacion-id="${id}"]`)
        if (item) {
          item.remove()
        }
        
        // Actualizar contador
        this.reloadNotifications()
      }
    })
  }
  
  marcarTodasLeidas(event) {
    event.preventDefault()
    
    fetch('/notificaciones/marcar_todas_como_leidas', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Actualizar interfaz
        this.actualizarContador(0)
        this.actualizarLista([])
      }
    })
  }
  
  mostrarToast(notificacion) {
    if (!this.hasToastTarget) return
    
    const toastId = 'toast-' + Date.now()
    
    // Crear elemento de toast
    const toast = document.createElement('div')
    toast.id = toastId
    toast.className = 'fixed bottom-4 right-4 bg-gray-800 text-white p-4 rounded-lg shadow-lg z-50 opacity-0 transform translate-y-16'
    toast.style.transition = 'opacity 0.3s ease, transform 0.3s ease'
    
    // Determinar color según nivel
    let borderColor = 'border-blue-500'
    switch (notificacion.nivel) {
      case 'error':
        borderColor = 'border-red-500'
        break
      case 'advertencia':
        borderColor = 'border-yellow-500'
        break
      case 'exito':
        borderColor = 'border-green-500'
        break
    }
    
    // Añadir borde de color
    toast.classList.add('border-l-4', borderColor)
    
    // Contenido del toast
    toast.innerHTML = `
      <div class="flex items-start">
        <div class="flex-shrink-0">
          <i class="${this.getIconForType(notificacion.tipo)} mr-2"></i>
        </div>
        <div class="flex-1">
          <h4 class="font-bold">${notificacion.titulo}</h4>
          <p class="text-sm text-gray-300">${notificacion.contenido}</p>
        </div>
        <button class="ml-4 text-gray-400 hover:text-white" onclick="cerrarToastNotificacion('${toastId}')">
          <i class="fas fa-times"></i>
        </button>
      </div>
    `
    
    // Añadir a la página
    this.toastTarget.appendChild(toast)
    
    // Script para cerrar toast
    if (!window.cerrarToastNotificacion) {
      const script = document.createElement('script')
      script.textContent = `
        window.cerrarToastNotificacion = function(id) {
          const toast = document.getElementById(id);
          if (toast) {
            toast.style.opacity = '0';
            toast.style.transform = 'translateY(16px)';
            
            setTimeout(() => {
              if (toast && toast.parentNode) {
                toast.parentNode.removeChild(toast);
              }
            }, 300);
          }
        }
      `
      document.body.appendChild(script);
    }
    
    // Mostrar con animación
    setTimeout(() => {
      toast.style.opacity = '1';
      toast.style.transform = 'translateY(0)';
    }, 10)
    
    // Auto cerrar después de 5 segundos
    setTimeout(() => {
      if (document.getElementById(toastId)) {
        window.cerrarToastNotificacion(toastId);
      }
    }, 5000)
  }
  
  playNotificationSound() {
    // Crear elemento de audio si no existe
    if (!this.notificationSound) {
      this.notificationSound = new Audio('/sounds/notification.mp3')
    }
    
    // Reproducir sonido
    this.notificationSound.play().catch(e => {
      // Ignorar errores de reproduccin (navegadores pueden bloquear)
      console.info('No se pudo reproducir sonido de notificacin', e)
    })
  }
  
  toggleSound() {
    this.soundEnabledValue = !this.soundEnabledValue
    
    // Guardar preferencia en localStorage
    localStorage.setItem('notificationSoundEnabled', this.soundEnabledValue)
    
    // Actualizar interfaz
    this.updateSoundToggleUI()
  }
  
  updateSoundToggleUI() {
    // Actualizar icono o texto segn estado
    const soundToggle = this.element.querySelector('[data-sound-toggle]')
    if (soundToggle) {
      if (this.soundEnabledValue) {
        soundToggle.innerHTML = '<i class="fas fa-volume-up"></i>'
        soundToggle.title = 'Desactivar sonido'
      } else {
        soundToggle.innerHTML = '<i class="fas fa-volume-mute"></i>'
        soundToggle.title = 'Activar sonido'
      }
    }
  }
  
  // Utilidad para obtener icono segn tipo
  getIconForType(tipo) {
    switch (tipo) {
      case 'laboratorio':
        return 'fas fa-flask text-blue-500'
      case 'curso':
        return 'fas fa-book text-green-500'
      case 'quiz':
        return 'fas fa-question-circle text-yellow-500'
      case 'logro':
        return 'fas fa-trophy text-purple-500'
      case 'ejercicio':
        return 'fas fa-tasks text-indigo-500'
      case 'mensaje':
        return 'fas fa-envelope text-teal-500'
      case 'alerta_seguridad':
        return 'fas fa-exclamation-triangle text-red-500'
      default:
        return 'fas fa-bell text-gray-400'
    }
  }
}