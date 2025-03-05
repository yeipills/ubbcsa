// app/javascript/controllers/quiz_preguntas_controller.js
import { Controller } from "@hotwired/stimulus"

/**
 * Controlador para la gestión de preguntas de quiz
 * 
 * Este controlador maneja las siguientes funcionalidades:
 * - Reordenamiento de preguntas mediante drag and drop
 * - Filtrado de preguntas por tipo
 * - Visualización previa de preguntas
 * - Apertura/cierre de paneles de preguntas
 */
export default class extends Controller {
  static targets = ["pregunta", "listado", "filtro", "tipoBadge", "contador"]
  
  connect() {
    console.log("Quiz Preguntas controller conectado")
    this.initializeSortable()
    this.updateContador()
  }
  
  /**
   * Configura la funcionalidad drag and drop para reordenar preguntas
   * Utiliza una API de bajo nivel para evitar dependencias adicionales
   */
  initializeSortable() {
    if (!this.hasListadoTarget) return
    
    // Almacenar el estado inicial de orden
    this.preguntaTargets.forEach((el, index) => {
      el.setAttribute('data-initial-order', index)
      
      // Configurar eventos drag and drop
      el.setAttribute('draggable', 'true')
      el.addEventListener('dragstart', this.handleDragStart.bind(this))
      el.addEventListener('dragover', this.handleDragOver.bind(this))
      el.addEventListener('dragenter', this.handleDragEnter.bind(this))
      el.addEventListener('dragleave', this.handleDragLeave.bind(this))
      el.addEventListener('drop', this.handleDrop.bind(this))
      el.addEventListener('dragend', this.handleDragEnd.bind(this))
    })
  }
  
  // Handlers para drag and drop
  handleDragStart(e) {
    e.dataTransfer.effectAllowed = 'move'
    e.dataTransfer.setData('text/plain', e.target.getAttribute('data-pregunta-id'))
    e.target.classList.add('opacity-50', 'border-blue-500', 'border-2')
    this.draggedItem = e.target
  }
  
  handleDragOver(e) {
    if (e.preventDefault) {
      e.preventDefault() // Permite el drop
    }
    e.dataTransfer.dropEffect = 'move'
    return false
  }
  
  handleDragEnter(e) {
    e.target.closest('[data-quiz-preguntas-target="pregunta"]')?.classList.add('bg-gray-900')
  }
  
  handleDragLeave(e) {
    e.target.closest('[data-quiz-preguntas-target="pregunta"]')?.classList.remove('bg-gray-900')
  }
  
  handleDrop(e) {
    e.stopPropagation()
    e.preventDefault()
    
    // Prevenir drop en sí mismo
    const targetItem = e.target.closest('[data-quiz-preguntas-target="pregunta"]')
    if (this.draggedItem === targetItem) return false
    
    // Reordenar en DOM
    if (this.hasListadoTarget && targetItem) {
      targetItem.classList.remove('bg-gray-900')
      
      const draggingId = this.draggedItem.getAttribute('data-pregunta-id')
      const targetId = targetItem.getAttribute('data-pregunta-id')
      
      // Determinar posición relativa
      const draggingRect = this.draggedItem.getBoundingClientRect()
      const targetRect = targetItem.getBoundingClientRect()
      const dropAfter = draggingRect.top < targetRect.top
      
      // Reordenar
      if (dropAfter) {
        this.listadoTarget.insertBefore(this.draggedItem, targetItem.nextElementSibling)
      } else {
        this.listadoTarget.insertBefore(this.draggedItem, targetItem)
      }
      
      // Guardar nuevo orden vía AJAX
      this.saveNewOrder()
    }
    
    return false
  }
  
  handleDragEnd(e) {
    // Limpiar estilos
    this.preguntaTargets.forEach(item => {
      item.classList.remove('opacity-50', 'border-blue-500', 'border-2', 'bg-gray-900')
    })
  }
  
  /**
   * Envía el nuevo orden al servidor
   * Realiza una petición AJAX para guardar el orden sin recargar la página
   */
  saveNewOrder() {
    const quizId = this.element.getAttribute('data-quiz-id')
    const ordenData = {}
    
    // Construir objeto con orden {pregunta_id: posición}
    this.preguntaTargets.forEach((el, index) => {
      const preguntaId = el.getAttribute('data-pregunta-id')
      ordenData[preguntaId] = index + 1
    })
    
    // Enviar petición AJAX
    fetch(`/quizzes/${quizId}/preguntas/reordenar`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ orden: ordenData })
    })
    .then(response => {
      if (response.ok) {
        this.showNotification('Orden actualizado correctamente', 'success')
      } else {
        this.showNotification('Error al actualizar el orden', 'error')
      }
    })
    .catch(error => {
      console.error('Error:', error)
      this.showNotification('Error de conexión', 'error')
    })
  }
  
  /**
   * Filtra preguntas por tipo
   * @param {Event} event - Evento de cambio del filtro
   */
  filtrarPorTipo(event) {
    const tipoSeleccionado = event.target.value
    
    this.preguntaTargets.forEach(pregunta => {
      const tipoPregunta = pregunta.getAttribute('data-tipo')
      
      if (tipoSeleccionado === 'todos' || tipoPregunta === tipoSeleccionado) {
        pregunta.classList.remove('hidden')
      } else {
        pregunta.classList.add('hidden')
      }
    })
    
    this.updateContador()
  }
  
  /**
   * Actualiza contador de preguntas visibles
   */
  updateContador() {
    if (this.hasContadorTarget) {
      const preguntasVisibles = this.preguntaTargets.filter(p => !p.classList.contains('hidden')).length
      const total = this.preguntaTargets.length
      this.contadorTarget.textContent = `${preguntasVisibles} de ${total} preguntas`
    }
  }
  
  /**
   * Muestra una notificación temporal
   * @param {string} mensaje - Texto de la notificación
   * @param {string} tipo - Tipo de notificación (success, error, info)
   */
  showNotification(mensaje, tipo = 'info') {
    // Crear elemento de notificación
    const notification = document.createElement('div')
    notification.className = `fixed bottom-4 right-4 px-4 py-2 rounded-lg shadow-lg z-50 ${
      tipo === 'success' ? 'bg-green-600 text-white' :
      tipo === 'error' ? 'bg-red-600 text-white' :
      'bg-blue-600 text-white'
    }`
    notification.innerHTML = mensaje
    
    // Añadir al DOM
    document.body.appendChild(notification)
    
    // Eliminar después de 3 segundos
    setTimeout(() => {
      notification.classList.add('opacity-0', 'transition-opacity', 'duration-500')
      setTimeout(() => notification.remove(), 500)
    }, 3000)
  }
}