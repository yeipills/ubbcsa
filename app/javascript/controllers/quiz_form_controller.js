import { Controller } from "@hotwired/stimulus"

/**
 * Quiz Form Controller
 * 
 * Controla la creación y edición de quizzes, con funcionalidades como:
 * - Validación de campos
 * - Gestión de fechas
 * - Vista previa
 * - Alertas personalizadas
 */
export default class extends Controller {
  static targets = [
    "fechaInicio", "fechaFin", "titulo", "descripcion", 
    "tiempoLimite", "intentosPermitidos", "preview", 
    "errorContainer", "submitButton", "cancelButton",
    "tipoSelector", "opcionesContainer", "emparejamientoContainer"
  ]
  
  static values = {
    quizId: Number,
    editMode: Boolean
  }
  
  connect() {
    this.setupFechaDefaults()
    this.setupValidaciones()
    
    // Configurar selector de tipo de pregunta si existe
    if (this.hasTipoSelectorTarget) {
      this.tipoSelector()
    }
    
    // Inicializar preview
    if (this.hasPreviewTarget) {
      this.actualizarPreview()
    }
  }
  
  // Configuración de fechas por defecto
  setupFechaDefaults() {
    if (this.hasFechaInicioTarget && this.hasFechaFinTarget) {
      // Si es formulario de creación y no tienen valores
      if (!this.editModeValue) {
        if (!this.fechaInicioTarget.value) {
          // Establecer fecha de inicio a la hora siguiente
          const ahora = new Date()
          ahora.setHours(ahora.getHours() + 1)
          ahora.setMinutes(0)
          ahora.setSeconds(0)
          
          const fechaInicioStr = this.formatearFechaHTML(ahora)
          this.fechaInicioTarget.value = fechaInicioStr
        }
        
        if (!this.fechaFinTarget.value) {
          // Establecer fecha de fin a 1 día después
          const manana = new Date()
          manana.setDate(manana.getDate() + 1)
          manana.setHours(manana.getHours() + 1)
          manana.setMinutes(0)
          manana.setSeconds(0)
          
          const fechaFinStr = this.formatearFechaHTML(manana)
          this.fechaFinTarget.value = fechaFinStr
        }
      }
      
      // Validar fechas al cambiar
      this.fechaInicioTarget.addEventListener('change', this.validarFechas.bind(this))
      this.fechaFinTarget.addEventListener('change', this.validarFechas.bind(this))
    }
  }
  
  // Formatear fecha para input HTML datetime-local
  formatearFechaHTML(fecha) {
    const ano = fecha.getFullYear()
    const mes = (fecha.getMonth() + 1).toString().padStart(2, '0')
    const dia = fecha.getDate().toString().padStart(2, '0')
    const hora = fecha.getHours().toString().padStart(2, '0')
    const minutos = fecha.getMinutes().toString().padStart(2, '0')
    
    return `${ano}-${mes}-${dia}T${hora}:${minutos}`
  }
  
  // Validar fechas
  validarFechas() {
    if (!this.hasFechaInicioTarget || !this.hasFechaFinTarget) return
    
    const fechaInicio = new Date(this.fechaInicioTarget.value)
    const fechaFin = new Date(this.fechaFinTarget.value)
    
    // Validar que fecha fin sea posterior a fecha inicio
    if (fechaFin <= fechaInicio) {
      // Establecer fecha fin a 1 día después de inicio
      fechaFin.setDate(fechaInicio.getDate() + 1)
      this.fechaFinTarget.value = this.formatearFechaHTML(fechaFin)
      
      this.mostrarError('La fecha de finalización debe ser posterior a la fecha de inicio. Se ha ajustado automáticamente.')
    }
    
    // Validar que fecha inicio sea futura o actual
    const ahora = new Date()
    if (this.editModeValue && fechaInicio < ahora) {
      // En modo edición, alertar pero permitir
      this.mostrarError('La fecha de inicio es en el pasado. Los estudiantes podrán acceder al quiz inmediatamente.', 'warning')
    } else if (!this.editModeValue && fechaInicio < ahora) {
      // En modo creación, corregir automáticamente
      fechaInicio.setHours(ahora.getHours() + 1)
      fechaInicio.setMinutes(0)
      this.fechaInicioTarget.value = this.formatearFechaHTML(fechaInicio)
      
      // Asegurar que fecha fin sigue siendo válida
      if (fechaFin <= fechaInicio) {
        fechaFin.setDate(fechaInicio.getDate() + 1)
        this.fechaFinTarget.value = this.formatearFechaHTML(fechaFin)
      }
      
      this.mostrarError('La fecha de inicio se ha ajustado a la próxima hora.', 'info')
    }
    
    // Actualizar preview
    if (this.hasPreviewTarget) {
      this.actualizarPreview()
    }
  }
  
  // Configuración de validaciones
  setupValidaciones() {
    if (this.hasTituloTarget) {
      this.tituloTarget.addEventListener('blur', this.validarTitulo.bind(this))
    }
    
    if (this.hasDescripcionTarget) {
      this.descripcionTarget.addEventListener('blur', this.validarDescripcion.bind(this))
    }
    
    if (this.hasTiempoLimiteTarget) {
      this.tiempoLimiteTarget.addEventListener('blur', this.validarTiempoLimite.bind(this))
    }
    
    if (this.hasIntentosPermitidosTarget) {
      this.intentosPermitidosTarget.addEventListener('blur', this.validarIntentosPermitidos.bind(this))
    }
  }
  
  // Validaciones individuales
  validarTitulo() {
    if (!this.tituloTarget.value.trim()) {
      this.tituloTarget.classList.add('border-red-500')
      return false
    } else {
      this.tituloTarget.classList.remove('border-red-500')
      return true
    }
  }
  
  validarDescripcion() {
    if (!this.descripcionTarget.value.trim()) {
      this.descripcionTarget.classList.add('border-red-500')
      return false
    } else {
      this.descripcionTarget.classList.remove('border-red-500')
      return true
    }
  }
  
  validarTiempoLimite() {
    const tiempo = parseInt(this.tiempoLimiteTarget.value)
    if (isNaN(tiempo) || tiempo < 1) {
      this.tiempoLimiteTarget.value = 30 // Valor por defecto: 30 minutos
      this.mostrarError('El tiempo límite debe ser un número positivo. Se ha establecido a 30 minutos.', 'warning')
      return false
    } else if (tiempo > 180) { // 3 horas máximo
      this.mostrarError('El tiempo límite es muy alto. Considere valores menores a 180 minutos.', 'warning')
    }
    return true
  }
  
  validarIntentosPermitidos() {
    const intentos = parseInt(this.intentosPermitidosTarget.value)
    if (isNaN(intentos) || intentos < 1) {
      this.intentosPermitidosTarget.value = 1 // Valor por defecto: 1 intento
      this.mostrarError('Los intentos permitidos deben ser al menos 1. Se ha corregido automáticamente.', 'warning')
      return false
    } else if (intentos > 10) {
      this.mostrarError('El número de intentos es muy alto. Considere un valor menor.', 'info')
    }
    return true
  }
  
  // Validación de todo el formulario
  validateForm(event) {
    let valido = true
    
    // Validar campos obligatorios
    if (this.hasTituloTarget && !this.validarTitulo()) {
      this.mostrarError('El título es obligatorio.')
      valido = false
    }
    
    if (this.hasDescripcionTarget && !this.validarDescripcion()) {
      this.mostrarError('La descripción es obligatoria.')
      valido = false
    }
    
    if (this.hasTiempoLimiteTarget && !this.validarTiempoLimite()) {
      valido = false
    }
    
    if (this.hasIntentosPermitidosTarget && !this.validarIntentosPermitidos()) {
      valido = false
    }
    
    // Validar fechas
    if (this.hasFechaInicioTarget && this.hasFechaFinTarget) {
      if (!this.fechaInicioTarget.value) {
        this.mostrarError('La fecha de inicio es obligatoria.')
        valido = false
      }
      
      if (!this.fechaFinTarget.value) {
        this.mostrarError('La fecha de finalización es obligatoria.')
        valido = false
      }
      
      const fechaInicio = new Date(this.fechaInicioTarget.value)
      const fechaFin = new Date(this.fechaFinTarget.value)
      
      if (fechaFin <= fechaInicio) {
        this.mostrarError('La fecha de finalización debe ser posterior a la fecha de inicio.')
        valido = false
      }
    }
    
    // Si no es válido, prevenir envío
    if (!valido) {
      event.preventDefault()
      
      // Desplazar a la parte superior para ver errores
      window.scrollTo({ top: 0, behavior: 'smooth' })
    } else if (this.hasSubmitButtonTarget) {
      // Deshabilitar botón para prevenir múltiples envíos
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.textContent = 'Guardando...'
      this.submitButtonTarget.classList.add('opacity-75', 'cursor-wait')
    }
  }
  
  // Mostrar mensaje de error
  mostrarError(mensaje, tipo = 'error') {
    if (!this.hasErrorContainerTarget) {
      console.error(mensaje)
      return
    }
    
    // Limpiar errores anteriores si es el mismo tipo
    const erroresAnteriores = this.errorContainerTarget.querySelectorAll(`.alert-${tipo}`)
    erroresAnteriores.forEach(error => error.remove())
    
    // Crear nuevo mensaje
    const alertElement = document.createElement('div')
    alertElement.classList.add('alert', `alert-${tipo}`, 'mb-4', 'p-3', 'rounded', 'text-sm')
    
    // Estilo según tipo
    switch (tipo) {
      case 'error':
        alertElement.classList.add('bg-red-900/50', 'text-red-300', 'border', 'border-red-800/50')
        break
      case 'warning':
        alertElement.classList.add('bg-amber-900/50', 'text-amber-300', 'border', 'border-amber-800/50')
        break
      case 'info':
        alertElement.classList.add('bg-blue-900/50', 'text-blue-300', 'border', 'border-blue-800/50')
        break
    }
    
    alertElement.textContent = mensaje
    
    // Añadir botón para cerrar
    const closeButton = document.createElement('button')
    closeButton.classList.add('float-right', 'text-sm', 'ml-2')
    closeButton.innerHTML = '&times;'
    closeButton.addEventListener('click', () => alertElement.remove())
    
    alertElement.prepend(closeButton)
    this.errorContainerTarget.appendChild(alertElement)
    
    // Auto-cerrar después de 7 segundos
    setTimeout(() => {
      alertElement.classList.add('opacity-0', 'transition-opacity', 'duration-500')
      setTimeout(() => alertElement.remove(), 500)
    }, 7000)
  }
  
  // Vista previa
  actualizarPreview() {
    if (!this.hasPreviewTarget) return
    
    // Actualizar vista previa con datos del formulario
    const titulo = this.hasTituloTarget ? this.tituloTarget.value : 'Título del Quiz'
    const descripcion = this.hasDescripcionTarget ? this.descripcionTarget.value : 'Descripción del quiz...'
    const tiempoLimite = this.hasTiempoLimiteTarget ? this.tiempoLimiteTarget.value : '30'
    const intentosPermitidos = this.hasIntentosPermitidosTarget ? this.intentosPermitidosTarget.value : '1'
    
    // Verificar opciones adicionales
    const mostrarResultadosInmediatos = document.querySelector('#quiz_mostrar_resultados_inmediatos')?.checked || false
    const aleatorizarPreguntas = document.querySelector('#quiz_aleatorizar_preguntas')?.checked || false
    const aleatorizarOpciones = document.querySelector('#quiz_aleatorizar_opciones')?.checked || false
    const pesoCalificacion = document.querySelector('#quiz_peso_calificacion')?.value || '100'
    const instrucciones = document.querySelector('#quiz_instrucciones')?.value || ''
    const codigoAcceso = document.querySelector('#quiz_codigo_acceso')?.value || 'AUTO'
    
    let fechaInicioStr = 'No definida'
    let fechaFinStr = 'No definida'
    
    if (this.hasFechaInicioTarget && this.fechaInicioTarget.value) {
      const fechaInicio = new Date(this.fechaInicioTarget.value)
      fechaInicioStr = fechaInicio.toLocaleString()
    }
    
    if (this.hasFechaFinTarget && this.fechaFinTarget.value) {
      const fechaFin = new Date(this.fechaFinTarget.value)
      fechaFinStr = fechaFin.toLocaleString()
    }
    
    // Construir instrucciones HTML
    const instruccionesHTML = instrucciones ? 
      `<div class="mt-4 p-3 bg-gray-800/40 rounded border border-gray-700">
         <h4 class="text-gray-300 text-sm font-medium mb-2">Instrucciones:</h4>
         <p class="text-gray-400 text-sm">${instrucciones}</p>
       </div>` : '';
    
    this.previewTarget.innerHTML = `
      <h3 class="text-xl font-semibold mb-2">${titulo}</h3>
      <div class="flex items-center mb-3">
        <span class="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-indigo-900/50 text-indigo-300 mr-2">
          Código: ${codigoAcceso}
        </span>
        <span class="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-blue-900/50 text-blue-300">
          Peso: ${pesoCalificacion}%
        </span>
      </div>
      <p class="text-gray-400 mb-4">${descripcion}</p>
      ${instruccionesHTML}
      <div class="space-y-2 text-sm mt-4">
        <p><span class="text-gray-500">Tiempo límite:</span> ${tiempoLimite} minutos</p>
        <p><span class="text-gray-500">Intentos permitidos:</span> ${intentosPermitidos}</p>
        <p><span class="text-gray-500">Disponible desde:</span> ${fechaInicioStr}</p>
        <p><span class="text-gray-500">Hasta:</span> ${fechaFinStr}</p>
        
        <div class="border-t border-gray-700 my-3 pt-3">
          <h4 class="text-gray-300 text-sm font-medium mb-2">Configuración adicional:</h4>
          <ul class="space-y-1">
            <li class="flex items-center">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2 ${mostrarResultadosInmediatos ? 'text-green-500' : 'text-gray-600'}" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="${mostrarResultadosInmediatos ? 
                  'M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z' : 
                  'M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z'}" clip-rule="evenodd" />
              </svg>
              Mostrar resultados inmediatos
            </li>
            <li class="flex items-center">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2 ${aleatorizarPreguntas ? 'text-green-500' : 'text-gray-600'}" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="${aleatorizarPreguntas ? 
                  'M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z' : 
                  'M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z'}" clip-rule="evenodd" />
              </svg>
              Aleatorizar preguntas
            </li>
            <li class="flex items-center">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2 ${aleatorizarOpciones ? 'text-green-500' : 'text-gray-600'}" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="${aleatorizarOpciones ? 
                  'M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z' : 
                  'M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z'}" clip-rule="evenodd" />
              </svg>
              Aleatorizar opciones
            </li>
          </ul>
        </div>
      </div>
    `
  }
  
  // Cambios en formulario
  handleInputChange() {
    if (this.hasPreviewTarget) {
      this.actualizarPreview()
    }
  }
  
  // Gestión de tipo de pregunta
  tipoSelector() {
    this.tipoSelectorTarget.addEventListener('change', this.cambiarTipoPregunta.bind(this))
    this.cambiarTipoPregunta() // Inicializar estado
  }
  
  cambiarTipoPregunta() {
    const tipoSeleccionado = this.tipoSelectorTarget.value
    
    // Ocultar todos los contenedores específicos de tipo
    const contenedoresTipo = [
      'opcion-multiple-container',
      'verdadero-falso-container',
      'respuesta-corta-container',
      'emparejamiento-container',
      'multiple-respuesta-container'
    ]
    
    contenedoresTipo.forEach(selector => {
      const contenedor = document.getElementById(selector)
      if (contenedor) {
        contenedor.classList.add('hidden')
      }
    })
    
    // Mostrar contenedor específico para el tipo seleccionado
    const contenedorActivo = document.getElementById(`${tipoSeleccionado}-container`)
    if (contenedorActivo) {
      contenedorActivo.classList.remove('hidden')
    }
    
    // Ajustar validaciones según tipo
    if (tipoSeleccionado === 'respuesta_corta') {
      const respuestaCorrectaInput = document.getElementById('respuesta_correcta')
      if (respuestaCorrectaInput) {
        respuestaCorrectaInput.required = true
      }
    } else if (tipoSeleccionado === 'emparejamiento' && this.hasEmparejamientoContainerTarget) {
      this.inicializarEmparejamiento()
    }
  }
  
  // Gestión de emparejamiento
  inicializarEmparejamiento() {
    // Implementar lógica para términos pareados
    console.log('Inicializando interfaz de emparejamiento')
  }
  
  // Añadir opción a pregunta de opción múltiple
  agregarOpcion(event) {
    event.preventDefault()
    
    if (!this.hasOpcionesContainerTarget) return
    
    const tipoSeleccionado = this.tipoSelectorTarget.value
    const opcionesContainer = this.opcionesContainerTarget
    const cantidadOpciones = opcionesContainer.querySelectorAll('.opcion-item').length
    const nuevaOpcionId = Date.now() // ID único para nueva opción
    
    // Crear template para nueva opción
    let template = `
      <div class="opcion-item bg-gray-800 p-3 rounded-md mb-2 border border-gray-700">
        <div class="flex items-center">
          <div class="flex-1">
            <input type="text" 
                  name="quiz_pregunta[opciones_attributes][${nuevaOpcionId}][contenido]" 
                  class="mt-1 block w-full rounded-md border-gray-600 bg-gray-800 text-white focus:border-blue-500 focus:ring-blue-500" 
                  placeholder="Texto de la opción" required>
          </div>
          <div class="ml-3 flex items-center">
    `
    
    // Añadir checkbox/radio según tipo de pregunta
    if (tipoSeleccionado === 'opcion_multiple' || tipoSeleccionado === 'verdadero_falso') {
      template += `
            <div class="mr-2">
              <input type="radio" 
                    name="quiz_pregunta[opciones_attributes][correcta]" 
                    value="${nuevaOpcionId}" 
                    class="h-4 w-4 rounded-full border-gray-600 bg-gray-800 text-indigo-600 focus:ring-indigo-500">
              <input type="hidden" 
                    name="quiz_pregunta[opciones_attributes][${nuevaOpcionId}][es_correcta]" 
                    value="0" 
                    class="correcta-value">
            </div>
      `
    } else if (tipoSeleccionado === 'multiple_respuesta') {
      template += `
            <div class="mr-2">
              <input type="checkbox" 
                    name="quiz_pregunta[opciones_attributes][${nuevaOpcionId}][es_correcta]" 
                    value="1" 
                    class="h-4 w-4 rounded border-gray-600 bg-gray-800 text-indigo-600 focus:ring-indigo-500">
              <input type="hidden" 
                    name="quiz_pregunta[opciones_attributes][${nuevaOpcionId}][es_correcta]" 
                    value="0" 
                    class="correcta-value">
            </div>
      `
    }
    
    // Añadir botón para eliminar opción
    template += `
            <button type="button" 
                   class="text-red-400 hover:text-red-500" 
                   data-action="click->quiz-form#eliminarOpcion">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clip-rule="evenodd" />
              </svg>
            </button>
          </div>
        </div>
        <input type="hidden" name="quiz_pregunta[opciones_attributes][${nuevaOpcionId}][orden]" value="${cantidadOpciones + 1}">
        <input type="hidden" name="quiz_pregunta[opciones_attributes][${nuevaOpcionId}][_destroy]" value="0" class="destroy-flag">
      </div>
    `
    
    // Insertar nueva opción
    opcionesContainer.insertAdjacentHTML('beforeend', template)
    
    // Conectar eventos para nueva opción
    const nuevaOpcion = opcionesContainer.lastElementChild
    const radioInput = nuevaOpcion.querySelector('input[type="radio"]')
    if (radioInput) {
      radioInput.addEventListener('change', this.actualizarOpcionCorrectaRadio.bind(this))
    }
    
    const checkboxInput = nuevaOpcion.querySelector('input[type="checkbox"]')
    if (checkboxInput) {
      checkboxInput.addEventListener('change', this.actualizarOpcionCorrectaCheckbox.bind(this))
    }
  }
  
  // Eliminar opción
  eliminarOpcion(event) {
    const opcionItem = event.target.closest('.opcion-item')
    if (!opcionItem) return
    
    // Si es opción existente, marcar para destruir
    const destroyFlag = opcionItem.querySelector('.destroy-flag')
    if (destroyFlag) {
      destroyFlag.value = "1"
      opcionItem.classList.add('hidden')
    } else {
      // Si es opción nueva, eliminar directamente
      opcionItem.remove()
    }
    
    // Reordenar opciones restantes
    this.reordenarOpciones()
  }
  
  // Reordenar opciones
  reordenarOpciones() {
    const opcionesContainer = this.opcionesContainerTarget
    const opciones = opcionesContainer.querySelectorAll('.opcion-item:not(.hidden)')
    
    opciones.forEach((opcion, index) => {
      const ordenInput = opcion.querySelector('input[name$="[orden]"]')
      if (ordenInput) {
        ordenInput.value = index + 1
      }
    })
  }
  
  // Actualizar opción correcta para radio buttons
  actualizarOpcionCorrectaRadio(event) {
    const radioSeleccionado = event.target
    const opcionesContainer = this.opcionesContainerTarget
    const todasOpciones = opcionesContainer.querySelectorAll('.opcion-item')
    
    todasOpciones.forEach(opcion => {
      const correctaValue = opcion.querySelector('.correcta-value')
      const radio = opcion.querySelector('input[type="radio"]')
      
      if (correctaValue && radio) {
        correctaValue.value = radio === radioSeleccionado ? "1" : "0"
      }
    })
  }
  
  // Actualizar opción correcta para checkboxes
  actualizarOpcionCorrectaCheckbox(event) {
    const checkbox = event.target
    const opcionItem = checkbox.closest('.opcion-item')
    const correctaValue = opcionItem.querySelector('.correcta-value')
    
    if (correctaValue) {
      correctaValue.value = checkbox.checked ? "1" : "0"
    }
  }
  
  // Cancelar formulario
  cancelar(event) {
    event.preventDefault()
    
    if (confirm('¿Estás seguro de que deseas cancelar? Los cambios no guardados se perderán.')) {
      const cancelURL = this.cancelButtonTarget.getAttribute('href')
      window.location.href = cancelURL
    }
  }
}