// app/javascript/controllers/quiz_response_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Configurar listeners para autoguardado
    this.element.addEventListener('quiz:autosave', this.autoSave.bind(this))
    
    // Configurar listeners para cambios
    this.setupChangeListeners()
    
    // Restaurar valores anteriores si hay
    this.restoreFormValues()
  }
  
  setupChangeListeners() {
    // Escuchar cambios en radio buttons
    this.element.querySelectorAll('input[type="radio"]').forEach(radio => {
      radio.addEventListener('change', () => {
        // Marcar como modificado para autoguardado
        this.element.dataset.modified = 'true'
        
        // Guardar en sessionStorage para prevenir prdida
        this.saveFormValues()
      })
    })
    
    // Escuchar cambios en campos de texto
    this.element.querySelectorAll('textarea').forEach(textarea => {
      textarea.addEventListener('input', () => {
        this.element.dataset.modified = 'true'
        this.saveFormValues()
      })
      
      // Guardar al perder el foco (por si acaso)
      textarea.addEventListener('blur', () => {
        if (this.element.dataset.modified === 'true') {
          this.autoSave()
        }
      })
    })
    
    // Escuchar cambios en selects de emparejamiento
    this.element.querySelectorAll('select.matching-select').forEach(select => {
      select.addEventListener('change', () => {
        this.element.dataset.modified = 'true'
        this.saveFormValues()
        
        // Actualizar campo oculto con los pares seleccionados
        this.updateMatchingPairs()
      })
    })
  }
  
  updateMatchingPairs() {
    // Obtener todos los selects de emparejamiento
    const matchingSelects = this.element.querySelectorAll('select.matching-select')
    
    if (matchingSelects.length === 0) return
    
    // Crear objeto para almacenar los pares (trmino_id => definicin_id)
    const matchingPairs = {}
    
    // Recorrer todos los selects
    matchingSelects.forEach(select => {
      const terminoId = select.dataset.terminoId
      const definicionId = select.value
      
      if (terminoId && definicionId) {
        matchingPairs[terminoId] = definicionId
      }
    })
    
    // Actualizar el campo oculto
    const hiddenField = this.element.querySelector('input[name="respuesta_quiz[respuesta_texto]"]')
    if (hiddenField) {
      hiddenField.value = JSON.stringify(matchingPairs)
    }
  }
  
  saveFormValues() {
    // Guardar valores del formulario en sessionStorage
    const formData = new FormData(this.element)
    const formValues = {}
    
    for (let [key, value] of formData.entries()) {
      formValues[key] = value
    }
    
    // Guardar en sessionStorage con ID nico basado en pregunta
    const preguntaId = this.element.querySelector('input[name="pregunta_id"]').value
    sessionStorage.setItem(`quiz_response_${preguntaId}`, JSON.stringify(formValues))
  }
  
  restoreFormValues() {
    // Restaurar valores del formulario desde sessionStorage
    const preguntaId = this.element.querySelector('input[name="pregunta_id"]').value
    const savedValues = sessionStorage.getItem(`quiz_response_${preguntaId}`)
    
    if (savedValues) {
      const formValues = JSON.parse(savedValues)
      
      // Restaurar radio buttons
      if (formValues['respuesta_quiz[opcion_id]']) {
        const radio = this.element.querySelector(`input[name="respuesta_quiz[opcion_id]"][value="${formValues['respuesta_quiz[opcion_id]']}"]`)
        if (radio) radio.checked = true
      }
      
      // Restaurar campos de texto
      if (formValues['respuesta_quiz[respuesta_texto]']) {
        const textarea = this.element.querySelector('textarea[name="respuesta_quiz[respuesta_texto]"]')
        if (textarea) textarea.value = formValues['respuesta_quiz[respuesta_texto]']
        
        // Si es emparejamiento, restaurar los selects
        if (this.element.querySelector('select.matching-select')) {
          try {
            const matchingPairs = JSON.parse(formValues['respuesta_quiz[respuesta_texto]'])
            
            // Recorrer cada par y restaurar selects
            Object.entries(matchingPairs).forEach(([terminoId, definicionId]) => {
              const select = this.element.querySelector(`select[data-termino-id="${terminoId}"]`)
              if (select) select.value = definicionId
            })
          } catch (e) {
            console.error('Error al restaurar pares de emparejamiento:', e)
          }
        }
      }
    }
  }
  
  autoSave(event) {
    // Si no hay cambios, no autoguardar
    if (this.element.dataset.modified !== 'true') return
    
    // Obtener pregunta_id
    const preguntaId = this.element.querySelector('input[name="pregunta_id"]').value
    
    // Crear FormData
    const formData = new FormData(this.element)
    
    // Enviar por AJAX
    fetch(this.element.action, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      },
      body: formData,
      credentials: 'same-origin'
    })
    .then(response => response.json())
    .then(data => {
      // Resetear estado modificado
      this.element.dataset.modified = 'false'
      
      // Limpiar sessionStorage para esta pregunta
      sessionStorage.removeItem(`quiz_response_${preguntaId}`)
      
      console.log('Autoguardado exitoso:', data)
    })
    .catch(error => {
      console.error('Error en autoguardado:', error)
    })
  }
  
  disconnect() {
    this.element.removeEventListener('quiz:autosave', this.autoSave)
  }
}