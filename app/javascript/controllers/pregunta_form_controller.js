// app/javascript/controllers/pregunta_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tipoSelect", "respuestaCorta", "emparejamiento", "imagePreview", "previewImage", "opcionesContainer", "multipleRespuesta", "previewContainer", "previewContent", "previewButton", "contenidoField", "retroalimentacionField"]

  connect() {
    this.tipoChanged()
    this.initEmparejamiento()
    this.initOpcionesMultiples()
    this.initPreview()
  }

  tipoChanged() {
    const tipo = this.tipoSelectTarget.value
    
    // Ocultar todos los tipos especficos primero
    this.respuestaCortaTarget.classList.add("hidden")
    if (this.hasEmparejamientoTarget) {
      this.emparejamientoTarget.classList.add("hidden")
    }
    if (this.hasMultipleRespuestaTarget) {
      this.multipleRespuestaTarget.classList.add("hidden")
    }
    
    // Mostrar el tipo seleccionado
    if (tipo === "respuesta_corta") {
      this.respuestaCortaTarget.classList.remove("hidden")
    } else if (tipo === "emparejamiento" && this.hasEmparejamientoTarget) {
      this.emparejamientoTarget.classList.remove("hidden")
    } else if (tipo === "multiple_respuesta" && this.hasMultipleRespuestaTarget) {
      this.multipleRespuestaTarget.classList.remove("hidden")
    }
    
    // Actualizar el modo de opciones segn el tipo
    this.actualizarModoOpciones(tipo)
  }
  
  actualizarModoOpciones(tipo) {
    // Para opciones mltiples y mltiple respuesta
    if (this.hasOpcionesContainerTarget) {
      const checkboxLabels = this.opcionesContainerTarget.querySelectorAll('.checkbox-label')
      
      if (tipo === "multiple_respuesta") {
        // Cambiar textos por checkboxes para seleccin mltiple
        checkboxLabels.forEach(label => {
          label.textContent = "Correcta"
        })
      } else if (tipo === "opcion_multiple") {
        // Cambiar textos por radio para opcin mltiple
        checkboxLabels.forEach(label => {
          label.textContent = "Correcta"
        })
      }
    }
  }

  previewImage(event) {
    const input = event.target
    
    if (input.files && input.files[0]) {
      const reader = new FileReader()
      
      reader.onload = (e) => {
        this.imagePreviewTarget.classList.remove("hidden")
        if (this.hasPreviewImageTarget) {
          this.previewImageTarget.src = e.target.result
          this.previewImageTarget.classList.remove("hidden")
        }
      }
      
      reader.readAsDataURL(input.files[0])
    }
  }
  
  initEmparejamiento() {
    if (!this.hasEmparejamientoTarget) return
    
    // Agregar event listener para el botn de agregar par
    const agregarBtn = document.getElementById('agregar-par')
    if (agregarBtn) {
      agregarBtn.addEventListener('click', this.agregarNuevoPar.bind(this))
    }
    
    // Inicializar funcin de eliminar par para todos los botones existentes
    this.initEliminarPar()
    
    // Inicializar los pares relacionados
    if (this.tipoSelectTarget.value === 'emparejamiento') {
      this.actualizarParesRelacionados()
    }
  }
  
  agregarNuevoPar() {
    const container = document.getElementById('pares-container')
    if (!container) return
    
    // Contar pares existentes para asignar nuevo ndice
    const paresExistentes = container.querySelectorAll('.par-item').length
    const nuevoIndice = paresExistentes + 1
    
    // Calcular nuevos valores de orden
    const ordenTermino = (paresExistentes * 2) + 1
    const ordenDefinicion = (paresExistentes * 2) + 2
    
    // Crear nuevo par
    const nuevoPar = document.createElement('div')
    nuevoPar.className = 'par-item border border-gray-700 p-3 rounded-lg'
    nuevoPar.innerHTML = `
      <div class="flex justify-between mb-2">
        <h5 class="text-gray-300 font-medium">Par ${nuevoIndice}</h5>
        <button type="button" class="text-red-400 hover:text-red-300 text-sm" onclick="eliminarPar(this)">
          Eliminar
        </button>
      </div>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <input type="hidden" name="quiz_pregunta[opciones_attributes][${ordenTermino}][es_termino]" value="true" />
          <input type="hidden" name="quiz_pregunta[opciones_attributes][${ordenTermino}][orden]" value="${ordenTermino}" class="orden-termino" />
          
          <div>
            <label class="block text-sm font-medium text-gray-300 mb-1" for="quiz_pregunta_opciones_attributes_${ordenTermino}_contenido">Trmino</label>
            <input class="w-full rounded-md border-gray-600 bg-gray-800 text-white focus:border-blue-500 focus:ring-blue-500" 
                placeholder="Escribe el trmino" 
                type="text" 
                name="quiz_pregunta[opciones_attributes][${ordenTermino}][contenido]" 
                id="quiz_pregunta_opciones_attributes_${ordenTermino}_contenido" />
          </div>
        </div>
        
        <div>
          <input type="hidden" name="quiz_pregunta[opciones_attributes][${ordenDefinicion}][es_termino]" value="false" />
          <input type="hidden" name="quiz_pregunta[opciones_attributes][${ordenDefinicion}][orden]" value="${ordenDefinicion}" class="orden-definicion" />
          
          <div>
            <label class="block text-sm font-medium text-gray-300 mb-1" for="quiz_pregunta_opciones_attributes_${ordenDefinicion}_contenido">Definicin</label>
            <input class="w-full rounded-md border-gray-600 bg-gray-800 text-white focus:border-blue-500 focus:ring-blue-500" 
                placeholder="Escribe la definicin" 
                type="text" 
                name="quiz_pregunta[opciones_attributes][${ordenDefinicion}][contenido]" 
                id="quiz_pregunta_opciones_attributes_${ordenDefinicion}_contenido" />
          </div>
        </div>
      </div>
    `
    
    // Agregar al contenedor
    container.appendChild(nuevoPar)
    
    // Actualizar pares relacionados
    this.actualizarParesRelacionados()
  }
  
  actualizarParesRelacionados() {
    const pares = document.querySelectorAll('.par-item')
    
    pares.forEach((par, index) => {
      const ordenTermino = (index * 2) + 1
      const ordenDefinicion = (index * 2) + 2
      
      // Crear o actualizar campo oculto para almacenar la relacin
      let parRelacionadoInput = par.querySelector(`input[name="quiz_pregunta[opciones_attributes][${ordenTermino}][par_relacionado]"]`)
      
      if (!parRelacionadoInput) {
        parRelacionadoInput = document.createElement('input')
        parRelacionadoInput.type = 'hidden'
        parRelacionadoInput.name = `quiz_pregunta[opciones_attributes][${ordenTermino}][par_relacionado]`
        par.querySelector('div:first-child > div:first-child').appendChild(parRelacionadoInput)
      }
      
      // Valor dummy para nuevos pares (se actualizar con IDs reales despus de guardar)
      const valorRelacion = { id: `dummy_${ordenDefinicion}`, tipo: 'definicion' }
      parRelacionadoInput.value = JSON.stringify(valorRelacion)
    })
  }
  
  initEliminarPar() {
    // Definir la funcin global para eliminar pares
    window.eliminarPar = (button) => {
      const parItem = button.closest('.par-item')
      
      if (parItem) {
        // Marcar para eliminacin si ya existe en la base de datos
        const idInputs = parItem.querySelectorAll('input[name$="[id]"]')
        idInputs.forEach(input => {
          if (input.value) {
            const destroyInput = document.createElement('input')
            destroyInput.type = 'hidden'
            destroyInput.name = input.name.replace('[id]', '[_destroy]')
            destroyInput.value = '1'
            parItem.appendChild(destroyInput)
          }
        })
        
        // Ocultar visualmente
        parItem.style.display = 'none'
        
        // Actualizar pares relacionados
        this.actualizarParesRelacionados()
      }
    }
  }
  
  initOpcionesMultiples() {
    // Solo inicializar si existe el contenedor de opciones
    if (!this.hasOpcionesContainerTarget) return
    
    // Agregar event listener para el botn de agregar opcin
    const agregarBtn = document.getElementById('agregar-opcion')
    if (agregarBtn) {
      agregarBtn.addEventListener('click', this.agregarNuevaOpcion.bind(this))
    }
    
    // Inicializar funcin de eliminar opcin
    this.initEliminarOpcion()
  }
  
  agregarNuevaOpcion() {
    const container = document.getElementById('opciones-container')
    if (!container) return
    
    // Contar opciones existentes para asignar nuevo ndice
    const opcionesExistentes = container.querySelectorAll('.opcion-item').length
    const nuevoIndice = opcionesExistentes + 1
    
    // Crear nueva opcin
    const nuevaOpcion = document.createElement('div')
    nuevaOpcion.className = 'opcion-item mb-3 p-3 border border-gray-700 rounded-lg'
    nuevaOpcion.innerHTML = `
      <div class="flex items-start gap-4">
        <div class="flex-grow">
          <label class="block text-sm font-medium text-gray-300 mb-1" for="quiz_pregunta_opciones_attributes_${nuevoIndice}_contenido">
            Opcin ${nuevoIndice}
          </label>
          <input type="hidden" name="quiz_pregunta[opciones_attributes][${nuevoIndice}][orden]" value="${nuevoIndice}" class="orden-opcion">
          <input class="w-full rounded-md border-gray-600 bg-gray-800 text-white focus:border-blue-500 focus:ring-blue-500" 
              placeholder="Texto de la opcin" 
              type="text" 
              name="quiz_pregunta[opciones_attributes][${nuevoIndice}][contenido]" 
              id="quiz_pregunta_opciones_attributes_${nuevoIndice}_contenido">
        </div>
        
        <div class="mt-6">
          <label class="inline-flex items-center">
            <input name="quiz_pregunta[opciones_attributes][${nuevoIndice}][es_correcta]" type="hidden" value="0">
            <input class="rounded border-gray-600 bg-gray-800 text-blue-600 focus:ring-blue-500 focus:ring-offset-gray-800" 
                type="checkbox" 
                value="1" 
                name="quiz_pregunta[opciones_attributes][${nuevoIndice}][es_correcta]" 
                id="quiz_pregunta_opciones_attributes_${nuevoIndice}_es_correcta">
            <span class="ml-2 text-sm text-gray-300 checkbox-label">Correcta</span>
          </label>
        </div>
        
        <div class="mt-4">
          <button type="button" class="p-2 text-red-400 hover:text-red-300" onclick="eliminarOpcion(this)">
            <i class="fas fa-trash"></i>
          </button>
        </div>
      </div>
    `
    
    // Agregar al contenedor
    container.appendChild(nuevaOpcion)
  }
  
  initEliminarOpcion() {
    // Definir la funcin global para eliminar opciones
    window.eliminarOpcion = (button) => {
      const opcionItem = button.closest('.opcion-item')
      
      if (opcionItem) {
        // Marcar para eliminacin si ya existe en la base de datos
        const idInput = opcionItem.querySelector('input[name$="[id]"]')
        if (idInput && idInput.value) {
          const destroyInput = document.createElement('input')
          destroyInput.type = 'hidden'
          destroyInput.name = idInput.name.replace('[id]', '[_destroy]')
          destroyInput.value = '1'
          opcionItem.appendChild(destroyInput)
        }
        
        // Ocultar visualmente
        opcionItem.style.display = 'none'
      }
    }
  }
  
  // Inicializa la función de previsualización
  initPreview() {
    // Añadimos esta función si el botón de previsualización existe
    if (!this.hasPreviewButtonTarget) return
    
    this.previewButtonTarget.addEventListener('click', this.mostrarPreview.bind(this))
  }
  
  // Genera una previsualización de la pregunta
  mostrarPreview(event) {
    event.preventDefault()
    
    // Obtener datos actuales del formulario
    const tipo = this.tipoSelectTarget.value
    const contenido = this.hasContenidoFieldTarget ? this.contenidoFieldTarget.value : "Sin contenido"
    const retroalimentacion = this.hasRetroalimentacionFieldTarget ? this.retroalimentacionFieldTarget.value : ""
    
    // Preparar contenido según el tipo de pregunta
    let previewHTML = `
      <div class="relative bg-gray-800 p-5 rounded-lg border border-gray-700">
        <button type="button" class="absolute top-2 right-2 text-gray-400 hover:text-white" data-action="pregunta-form#cerrarPreview">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
          </svg>
        </button>
        
        <div class="mb-4">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-md text-sm font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300">
            Vista previa
          </span>
        </div>
        
        <h3 class="text-lg font-medium text-white mb-4">${contenido}</h3>
    `
    
    // Mostrar opciones según el tipo de pregunta
    if (tipo === 'opcion_multiple' || tipo === 'multiple_respuesta') {
      // Recopilar todas las opciones del formulario
      const opciones = []
      const opcionesElements = this.opcionesContainerTarget.querySelectorAll('.opcion-item:not([style*="display: none"])')
      
      opcionesElements.forEach((opcion, index) => {
        const contenidoInput = opcion.querySelector('input[name$="[contenido]"]')
        if (contenidoInput && contenidoInput.value) {
          opciones.push(contenidoInput.value)
        }
      })
      
      // Botones de radio para opción múltiple, checkboxes para selección múltiple
      const inputType = tipo === 'opcion_multiple' ? 'radio' : 'checkbox'
      const inputName = tipo === 'opcion_multiple' ? 'preview_opcion' : 'preview_opcion[]'
      
      previewHTML += `<div class="space-y-3 mb-4">`
      
      opciones.forEach((opcion, index) => {
        previewHTML += `
          <div class="flex items-center">
            <input type="${inputType}" id="preview_opcion_${index}" name="${inputName}" 
                   class="${inputType === 'radio' ? 'form-radio' : 'form-checkbox'} h-4 w-4 text-blue-600 bg-gray-700 border-gray-600 focus:ring-blue-500 focus:ring-offset-gray-800" disabled>
            <label for="preview_opcion_${index}" class="ml-2 block text-sm text-gray-300">
              ${opcion}
            </label>
          </div>
        `
      })
      
      previewHTML += `</div>`
      
    } else if (tipo === 'verdadero_falso') {
      previewHTML += `
        <div class="space-y-3 mb-4">
          <div class="flex items-center">
            <input type="radio" id="preview_verdadero" name="preview_vf" class="form-radio h-4 w-4 text-blue-600 bg-gray-700 border-gray-600 focus:ring-blue-500 focus:ring-offset-gray-800" disabled>
            <label for="preview_verdadero" class="ml-2 block text-sm text-gray-300">Verdadero</label>
          </div>
          <div class="flex items-center">
            <input type="radio" id="preview_falso" name="preview_vf" class="form-radio h-4 w-4 text-blue-600 bg-gray-700 border-gray-600 focus:ring-blue-500 focus:ring-offset-gray-800" disabled>
            <label for="preview_falso" class="ml-2 block text-sm text-gray-300">Falso</label>
          </div>
        </div>
      `
    } else if (tipo === 'respuesta_corta') {
      previewHTML += `
        <div class="mb-4">
          <input type="text" class="w-full bg-gray-700 border border-gray-600 rounded-md py-2 px-3 text-white placeholder-gray-400 focus:ring-blue-500 focus:border-blue-500" 
                 placeholder="Escribe tu respuesta aquí..." disabled>
        </div>
      `
    } else if (tipo === 'emparejamiento') {
      // Recopilar términos y definiciones
      const terminos = []
      const definiciones = []
      
      if (this.hasEmparejamientoTarget) {
        const paresElements = this.emparejamientoTarget.querySelectorAll('.par-item:not([style*="display: none"])')
        
        paresElements.forEach(par => {
          const terminoInput = par.querySelector('input[name$="[contenido]"][id*="es_termino"][id$="_contenido"]')
          const definicionInput = par.querySelector('input[name$="[contenido]"]:not([id*="es_termino"])[id$="_contenido"]')
          
          if (terminoInput && terminoInput.value) {
            terminos.push(terminoInput.value)
          }
          
          if (definicionInput && definicionInput.value) {
            definiciones.push(definicionInput.value)
          }
        })
      }
      
      // Mezclar definiciones para mostrar
      const definicionesMezcladas = [...definiciones].sort(() => Math.random() - 0.5)
      
      previewHTML += `
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <div>
            <h4 class="text-sm font-medium text-gray-400 mb-2">Términos</h4>
            <div class="space-y-2">
      `
      
      terminos.forEach((termino, index) => {
        previewHTML += `
          <div class="flex items-center">
            <span class="inline-flex items-center justify-center h-6 w-6 rounded-full bg-blue-900 text-blue-300 text-sm font-medium mr-2">${index + 1}</span>
            <span class="text-gray-300">${termino}</span>
          </div>
        `
      })
      
      previewHTML += `
            </div>
          </div>
          <div>
            <h4 class="text-sm font-medium text-gray-400 mb-2">Definiciones</h4>
            <div class="space-y-2">
      `
      
      definicionesMezcladas.forEach((definicion, index) => {
        previewHTML += `
          <div class="flex items-center">
            <span class="inline-flex items-center justify-center h-6 w-6 rounded-full bg-purple-900 text-purple-300 text-sm font-medium mr-2">${String.fromCharCode(65 + index)}</span>
            <span class="text-gray-300">${definicion}</span>
          </div>
        `
      })
      
      previewHTML += `
            </div>
          </div>
        </div>
      `
    }
    
    // Añadir retroalimentación si existe
    if (retroalimentacion) {
      previewHTML += `
        <div class="mt-6 p-3 bg-gray-900 rounded border border-gray-700">
          <h4 class="text-sm font-medium text-blue-400 mb-1">Retroalimentación (visible después de responder)</h4>
          <p class="text-gray-300 text-sm">${retroalimentacion}</p>
        </div>
      `
    }
    
    // Cerrar el contenedor
    previewHTML += `</div>`
    
    // Mostrar la previsualización
    this.previewContentTarget.innerHTML = previewHTML
    this.previewContainerTarget.classList.remove('hidden')
  }
  
  // Cierra la vista previa
  cerrarPreview(event) {
    event.preventDefault()
    this.previewContainerTarget.classList.add('hidden')
  }
}