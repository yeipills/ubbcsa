// app/javascript/controllers/quiz_preguntas_controller.js
import { Controller } from "@hotwired/stimulus"

/**
 * Controlador para la gestión de preguntas de quiz
 * 
 * Este controlador maneja las siguientes funcionalidades:
 * - Reordenamiento de preguntas mediante drag and drop
 * - Filtrado de preguntas por tipo
 * - Búsqueda de preguntas por contenido
 * - Visualización previa de preguntas
 * - Apertura/cierre de paneles de preguntas
 */
export default class extends Controller {
  static targets = ["pregunta", "listado", "filtro", "tipoBadge", "contador", "busqueda", "modalPreview", "previewContenido"]
  
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
    
    // Mejorar la visualización del elemento que se arrastra
    e.target.classList.add('opacity-70', 'border-2', 'border-indigo-500', 'bg-gray-700', 'shadow-lg')
    // Efecto de escala sutil
    e.target.style.transform = 'scale(1.02)'
    
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
    const targetItem = e.target.closest('[data-quiz-preguntas-target="pregunta"]')
    if (targetItem && this.draggedItem !== targetItem) {
      // Efecto visual al entrar en zona donde se puede soltar
      targetItem.classList.add('bg-gray-700')
      // Línea indicadora para mostrar dónde se colocará
      const rect = targetItem.getBoundingClientRect()
      const dropAfter = e.clientY > rect.top + rect.height / 2
      
      if (dropAfter) {
        targetItem.classList.add('border-b-2', 'border-indigo-500')
        targetItem.classList.remove('border-t-2')
      } else {
        targetItem.classList.add('border-t-2', 'border-indigo-500')
        targetItem.classList.remove('border-b-2')
      }
    }
  }
  
  handleDragLeave(e) {
    const targetItem = e.target.closest('[data-quiz-preguntas-target="pregunta"]')
    if (targetItem) {
      targetItem.classList.remove('bg-gray-700', 'border-t-2', 'border-b-2', 'border-indigo-500')
    }
  }
  
  handleDrop(e) {
    e.stopPropagation()
    e.preventDefault()
    
    // Prevenir drop en sí mismo
    const targetItem = e.target.closest('[data-quiz-preguntas-target="pregunta"]')
    if (this.draggedItem === targetItem) return false
    
    // Reordenar en DOM
    if (this.hasListadoTarget && targetItem) {
      // Eliminar efectos visuales
      targetItem.classList.remove('bg-gray-700', 'border-t-2', 'border-b-2', 'border-indigo-500')
      
      // Determinar posición relativa
      const rect = targetItem.getBoundingClientRect()
      const dropAfter = e.clientY > rect.top + rect.height / 2
      
      // Reordenar
      if (dropAfter) {
        this.listadoTarget.insertBefore(this.draggedItem, targetItem.nextElementSibling)
      } else {
        this.listadoTarget.insertBefore(this.draggedItem, targetItem)
      }
      
      // Añadir efecto de destello para indicar cambio exitoso
      this.draggedItem.classList.add('bg-indigo-800')
      setTimeout(() => {
        this.draggedItem.classList.remove('bg-indigo-800')
      }, 300)
      
      // Guardar nuevo orden vía AJAX
      this.saveNewOrder()
    }
    
    return false
  }
  
  handleDragEnd(e) {
    // Limpiar estilos de todos los elementos
    this.preguntaTargets.forEach(item => {
      item.classList.remove(
        'opacity-70', 'border-2', 'border-indigo-500', 'bg-gray-700', 
        'shadow-lg', 'border-t-2', 'border-b-2'
      )
      item.style.transform = ''
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
    
    // Aplicar filtro combinado (tipo y búsqueda)
    this.aplicarFiltrosCombinados(tipoSeleccionado, this.hasBusquedaTarget ? this.busquedaTarget.value : '')
  }
  
  /**
   * Busca preguntas por contenido
   * @param {Event} event - Evento de entrada en el campo de búsqueda
   */
  buscarPreguntas(event) {
    const busqueda = event.target.value.toLowerCase()
    
    // Aplicar filtro combinado (tipo y búsqueda)
    this.aplicarFiltrosCombinados(this.hasFiltroTarget ? this.filtroTarget.value : 'todos', busqueda)
  }
  
  /**
   * Aplica filtros combinados (tipo y búsqueda) a las preguntas
   * @param {string} tipo - Tipo de pregunta seleccionado
   * @param {string} busqueda - Texto de búsqueda
   */
  aplicarFiltrosCombinados(tipo, busqueda) {
    this.preguntaTargets.forEach(pregunta => {
      const tipoPregunta = pregunta.getAttribute('data-tipo')
      const contenido = pregunta.querySelector('h3').textContent.toLowerCase()
      
      // Comprobar si cumple ambos filtros
      const coincideTipo = tipo === 'todos' || tipoPregunta === tipo
      const coincideBusqueda = !busqueda || contenido.includes(busqueda)
      
      // Mostrar u ocultar según coincidencia
      if (coincideTipo && coincideBusqueda) {
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
      this.contadorTarget.textContent = `Visible: ${preguntasVisibles} de ${total} preguntas`
    }
  }
  
  /**
   * Muestra una vista previa de la pregunta
   * @param {Event} event - Evento de clic en el botón de vista previa
   */
  mostrarVistaPrevia(event) {
    const preguntaId = event.currentTarget.getAttribute('data-pregunta-id')
    const quizId = this.element.getAttribute('data-quiz-id')
    
    // Mostrar el modal con animación de carga
    this.modalPreviewTarget.classList.remove('hidden')
    
    // Cargar la vista previa desde el servidor
    fetch(`/quizzes/${quizId}/preguntas/${preguntaId}/preview`)
      .then(response => {
        if (!response.ok) {
          throw new Error('Error al cargar la vista previa')
        }
        return response.text()
      })
      .then(html => {
        this.previewContenidoTarget.innerHTML = html
      })
      .catch(error => {
        console.error('Error:', error)
        this.previewContenidoTarget.innerHTML = `
          <div class="p-4 bg-red-900/50 border border-red-800 rounded-lg">
            <p class="text-red-300">Error al cargar la vista previa: ${error.message}</p>
            <p class="text-red-300 mt-2">Intenta de nuevo más tarde o contacta al administrador.</p>
          </div>
        `
      })
  }
  
  /**
   * Cierra el modal de vista previa
   */
  cerrarVistaPrevia() {
    this.modalPreviewTarget.classList.add('hidden')
    // Limpiar contenido después de cerrar
    setTimeout(() => {
      this.previewContenidoTarget.innerHTML = `
        <div class="animate-pulse">
          <div class="h-6 bg-gray-700 rounded mb-4 w-3/4"></div>
          <div class="h-4 bg-gray-700 rounded mb-2 w-full"></div>
          <div class="h-4 bg-gray-700 rounded mb-2 w-5/6"></div>
          <div class="h-10 bg-gray-700 rounded mb-4"></div>
          <div class="h-10 bg-gray-700 rounded mb-4"></div>
          <div class="h-10 bg-gray-700 rounded mb-4"></div>
          <div class="h-10 bg-gray-700 rounded"></div>
        </div>
      `
    }, 300)
  }

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