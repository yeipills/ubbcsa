// app/javascript/controllers/quiz_results_controller.js
import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

// Registrar componentes de Chart.js
Chart.register(...registerables)

/**
 * Quiz Results Controller
 * 
 * Controlador para la visualización de resultados de quiz, incluyendo:
 * - Gráficos de rendimiento comparativo
 * - Filtrado de preguntas por resultados
 * - Impresión de resultados para estudiantes
 * - Expandir/contraer detalles de preguntas
 */
export default class extends Controller {
  static targets = [
    "chart", 
    "detailToggle", 
    "detailContent", 
    "questionFilter", 
    "correctCount", 
    "incorrectCount",
    "questionCount",
    "expandAllButton"
  ]
  
  static values = {
    intentoId: Number,
    quizId: Number,
    puntaje: Number,
    datosGrafico: Object,
    comparacionCurso: Object
  }
  
  connect() {
    this.inicializarGraficos()
    this.inicializarFiltros()
    this.autoExpandFirstIncorrect()
  }
  
  // Gráficos de resultados
  inicializarGraficos() {
    // Esperar a que los elementos estén renderizados
    setTimeout(() => {
      this.renderizarGraficoPuntaje()
      this.renderizarGraficoComparacion()
      this.renderizarGraficoTiempo()
    }, 100)
  }
  
  renderizarGraficoPuntaje() {
    const chartElement = this.chartTargets.find(el => el.dataset.chartType === "puntaje")
    if (!chartElement) return
    
    const ctx = chartElement.getContext('2d')
    const correctas = parseFloat(this.puntajeValue) || 0
    const incorrectas = 100 - correctas
    
    // Configurar colores según rendimiento
    const colorPrimario = correctas >= 60 ? 
      'rgba(34, 197, 94, 0.8)' : // Verde para aprobado
      'rgba(239, 68, 68, 0.8)'   // Rojo para reprobado
    
    const colorSecundario = 'rgba(100, 116, 139, 0.8)' // Gris para incorrecto
    
    // Gráfico de dona para puntaje
    new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: ['Correcto', 'Incorrecto'],
        datasets: [{
          data: [correctas, incorrectas],
          backgroundColor: [colorPrimario, colorSecundario],
          borderColor: [
            colorPrimario.replace('0.8', '1'),
            colorSecundario.replace('0.8', '1')
          ],
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        cutout: '70%',
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              color: '#e2e8f0', // text-gray-200
              font: {
                size: 11
              }
            }
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                return `${context.label}: ${context.raw.toFixed(1)}%`
              }
            }
          }
        }
      }
    })
  }
  
  renderizarGraficoComparacion() {
    const chartElement = this.chartTargets.find(el => el.dataset.chartType === "comparacion")
    if (!chartElement || !this.hasComparacionCursoValue) return
    
    const ctx = chartElement.getContext('2d')
    const datosComparacion = this.comparacionCursoValue
    
    // Para gráfico de barras de comparación
    new Chart(ctx, {
      type: 'bar',
      data: {
        labels: ['Tu puntaje', 'Promedio curso', 'Mejor puntaje'],
        datasets: [{
          label: 'Puntaje (%)',
          data: [
            this.puntajeValue, 
            datosComparacion.promedio || 0, 
            datosComparacion.mejor || 0
          ],
          backgroundColor: [
            'rgba(59, 130, 246, 0.8)', // blue-500
            'rgba(250, 204, 21, 0.8)', // yellow-400
            'rgba(34, 197, 94, 0.8)'   // green-500
          ],
          borderColor: [
            'rgba(59, 130, 246, 1)',
            'rgba(250, 204, 21, 1)',
            'rgba(34, 197, 94, 1)'
          ],
          borderWidth: 1,
          borderRadius: 4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            max: 100,
            ticks: {
              color: '#e2e8f0', // text-gray-200
              font: {
                size: 10
              }
            },
            grid: {
              color: 'rgba(255, 255, 255, 0.1)'
            }
          },
          x: {
            ticks: {
              color: '#e2e8f0', // text-gray-200
              font: {
                size: 10
              }
            },
            grid: {
              color: 'rgba(255, 255, 255, 0.1)'
            }
          }
        },
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                return `${context.dataset.label}: ${context.raw.toFixed(1)}%`
              }
            }
          }
        }
      }
    })
  }
  
  renderizarGraficoTiempo() {
    const chartElement = this.chartTargets.find(el => el.dataset.chartType === "tiempo")
    if (!chartElement || !this.hasComparacionCursoValue) return
    
    const ctx = chartElement.getContext('2d')
    const datosComparacion = this.comparacionCursoValue
    
    // Datos para gráfico de tiempo (en minutos)
    const tiempoUsuario = datosComparacion.tiempo_usuario ? datosComparacion.tiempo_usuario / 60 : 0
    const tiempoPromedio = datosComparacion.tiempo_promedio ? datosComparacion.tiempo_promedio / 60 : 0
    
    // Para gráfico de barras de tiempo
    new Chart(ctx, {
      type: 'bar',
      data: {
        labels: ['Tu tiempo', 'Tiempo promedio'],
        datasets: [{
          label: 'Tiempo (minutos)',
          data: [tiempoUsuario, tiempoPromedio],
          backgroundColor: [
            'rgba(147, 51, 234, 0.8)', // purple-600
            'rgba(251, 146, 60, 0.8)'  // orange-400
          ],
          borderColor: [
            'rgba(147, 51, 234, 1)',
            'rgba(251, 146, 60, 1)'
          ],
          borderWidth: 1,
          borderRadius: 4
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              color: '#e2e8f0', // text-gray-200
              font: {
                size: 10
              },
              callback: function(value) {
                return `${value} min`
              }
            },
            grid: {
              color: 'rgba(255, 255, 255, 0.1)'
            }
          },
          x: {
            ticks: {
              color: '#e2e8f0', // text-gray-200
              font: {
                size: 10
              }
            },
            grid: {
              color: 'rgba(255, 255, 255, 0.1)'
            }
          }
        },
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                const minutos = Math.floor(context.raw)
                const segundos = Math.round((context.raw - minutos) * 60)
                return `${minutos}m ${segundos}s`
              }
            }
          }
        }
      }
    })
  }
  
  // Filtrado de preguntas
  inicializarFiltros() {
    // Si no hay filtros, salir
    if (!this.hasQuestionFilterTarget) return
    
    // Inicializar contadores
    this.actualizarContadores()
  }
  
  filtrarPreguntas(event) {
    const filtro = event.target.value
    const preguntas = document.querySelectorAll('.pregunta-resultado')
    
    preguntas.forEach(pregunta => {
      const esCorrecta = pregunta.dataset.correcta === "true"
      
      switch (filtro) {
        case "todas":
          pregunta.classList.remove("hidden")
          break
        case "correctas":
          pregunta.classList.toggle("hidden", !esCorrecta)
          break
        case "incorrectas":
          pregunta.classList.toggle("hidden", esCorrecta)
          break
      }
    })
    
    // Actualizar contador de preguntas visibles
    this.actualizarContadorVisible()
  }
  
  actualizarContadores() {
    if (!this.hasCorrectCountTarget || !this.hasIncorrectCountTarget) return
    
    const preguntas = document.querySelectorAll('.pregunta-resultado')
    let correctas = 0
    let incorrectas = 0
    
    preguntas.forEach(pregunta => {
      if (pregunta.dataset.correcta === "true") {
        correctas++
      } else {
        incorrectas++
      }
    })
    
    this.correctCountTarget.textContent = correctas
    this.incorrectCountTarget.textContent = incorrectas
    
    // Actualizar contador total visible
    if (this.hasQuestionCountTarget) {
      this.questionCountTarget.textContent = preguntas.length
    }
  }
  
  actualizarContadorVisible() {
    const preguntasVisibles = document.querySelectorAll('.pregunta-resultado:not(.hidden)').length
    const total = document.querySelectorAll('.pregunta-resultado').length
    
    if (this.hasQuestionCountTarget) {
      this.questionCountTarget.textContent = preguntasVisibles
    }
  }
  
  // Funciones de detalle para preguntas
  toggleDetalles(event) {
    const detalleId = event.currentTarget.dataset.detalleTarget
    const contenido = document.getElementById(detalleId)
    
    if (contenido) {
      const estaExpandido = contenido.classList.contains("hidden")
      
      // Cambiar icono del toggle
      const icono = event.currentTarget.querySelector("svg")
      if (icono) {
        icono.style.transform = estaExpandido ? "rotate(180deg)" : "rotate(0deg)"
      }
      
      // Mostrar/ocultar contenido
      contenido.classList.toggle("hidden", !estaExpandido)
      
      // Cambiar texto del botón
      if (event.currentTarget.dataset.toggleText) {
        const textoOriginal = event.currentTarget.querySelector("span").textContent.trim()
        event.currentTarget.querySelector("span").textContent = event.currentTarget.dataset.toggleText
        event.currentTarget.dataset.toggleText = textoOriginal
      }
    }
  }
  
  // Auto-expandir primera pregunta incorrecta para guiar al usuario
  autoExpandFirstIncorrect() {
    // Buscar primera pregunta incorrecta
    const primeraIncorrecta = document.querySelector('.pregunta-resultado[data-correcta="false"]')
    
    if (primeraIncorrecta) {
      // Encontrar el botón de toggle dentro de la pregunta
      const toggleButton = primeraIncorrecta.querySelector('[data-quiz-results-target="detailToggle"]')
      const detalleId = toggleButton?.dataset.detalleTarget
      
      if (toggleButton && detalleId) {
        // Expandir automáticamente
        const detalleContenido = document.getElementById(detalleId)
        if (detalleContenido) {
          detalleContenido.classList.remove("hidden")
          
          // Ajustar el botón
          const icono = toggleButton.querySelector("svg")
          if (icono) {
            icono.style.transform = "rotate(180deg)"
          }
          
          if (toggleButton.dataset.toggleText) {
            const textoOriginal = toggleButton.querySelector("span").textContent.trim()
            toggleButton.querySelector("span").textContent = toggleButton.dataset.toggleText
            toggleButton.dataset.toggleText = textoOriginal
          }
          
          // Hacer scroll a esta pregunta
          setTimeout(() => {
            primeraIncorrecta.scrollIntoView({ behavior: 'smooth', block: 'center' })
          }, 500)
        }
      }
    }
  }
  
  // Expandir o contraer todas las preguntas
  toggleAllDetails(event) {
    const expandir = event.currentTarget.dataset.action === "expand"
    const toggleButtons = this.detailToggleTargets
    
    toggleButtons.forEach(button => {
      const detalleId = button.dataset.detalleTarget
      const contenido = document.getElementById(detalleId)
      
      if (contenido) {
        const estaExpandido = !contenido.classList.contains("hidden")
        
        // Solo actuar si el estado actual es diferente al deseado
        if (expandir !== estaExpandido) {
          // Cambiar icono
          const icono = button.querySelector("svg")
          if (icono) {
            icono.style.transform = expandir ? "rotate(180deg)" : "rotate(0deg)"
          }
          
          // Mostrar/ocultar contenido
          contenido.classList.toggle("hidden", !expandir)
          
          // Cambiar texto del botón
          if (button.dataset.toggleText) {
            const textoOriginal = button.querySelector("span").textContent.trim()
            button.querySelector("span").textContent = button.dataset.toggleText
            button.dataset.toggleText = textoOriginal
          }
        }
      }
    })
    
    // Actualizar botón expandir/contraer todo
    if (this.hasExpandAllButtonTarget) {
      const textoOriginal = this.expandAllButtonTarget.textContent.trim()
      this.expandAllButtonTarget.textContent = this.expandAllButtonTarget.dataset.toggleText
      this.expandAllButtonTarget.dataset.toggleText = textoOriginal
      this.expandAllButtonTarget.dataset.action = expandir ? "quiz-results#collapseAll" : "quiz-results#expandAll"
    }
  }
  
  expandAll(event) {
    event.currentTarget.dataset.action = "collapse"
    this.toggleAllDetails(event)
  }
  
  collapseAll(event) {
    event.currentTarget.dataset.action = "expand"
    this.toggleAllDetails(event)
  }
  
  // Funciones de impresión
  imprimirResultados(event) {
    event.preventDefault()
    
    // Expandir todas las preguntas antes de imprimir
    const preguntas = document.querySelectorAll('.pregunta-resultado')
    preguntas.forEach(pregunta => {
      const detalles = pregunta.querySelector('[id^="detalles_"]')
      if (detalles) {
        detalles.classList.remove("hidden")
      }
    })
    
    // Ejecutar impresión
    window.print()
    
    // Retornar al estado anterior (opcional, depende de la experiencia deseada)
    setTimeout(() => {
      // Si quieres dejar todo expandido, comenta esta sección
      preguntas.forEach(pregunta => {
        const detalles = pregunta.querySelector('[id^="detalles_"]')
        if (detalles) {
          detalles.classList.add("hidden")
        }
      })
    }, 1000)
  }
  
  exportarPDF(event) {
    event.preventDefault()
    window.location.href = `/quizzes/${this.quizIdValue}/intentos/${this.intentoIdValue}/exportar?formato=pdf`
  }
  
  exportarCSV(event) {
    event.preventDefault()
    window.location.href = `/quizzes/${this.quizIdValue}/intentos/${this.intentoIdValue}/exportar?formato=csv`
  }
  
  // Funciones para compartir
  compartirResultados(event) {
    event.preventDefault()
    
    // Crear enlace para compartir
    const url = `${window.location.origin}/quizzes/${this.quizIdValue}/intentos/${this.intentoIdValue}/resultados`
    
    // Intentar usar la API Web Share si está disponible
    if (navigator.share) {
      navigator.share({
        title: 'Resultados de mi Quiz',
        text: `He obtenido ${this.puntajeValue}% en este quiz. ¡Inténtalo tú también!`,
        url: url
      }).catch(error => {
        console.log('Error compartiendo resultados', error)
        this.copiarEnlace(url)
      })
    } else {
      this.copiarEnlace(url)
    }
  }
  
  copiarEnlace(url) {
    // Usar clipboard API si está disponible
    if (navigator.clipboard) {
      navigator.clipboard.writeText(url)
        .then(() => {
          this.mostrarNotificacion('Enlace copiado al portapapeles', 'success')
        })
        .catch(err => {
          console.error('Error al copiar: ', err)
          this.mostrarNotificacion('No se pudo copiar el enlace', 'error')
        })
    } else {
      // Fallback para navegadores más antiguos
      const input = document.createElement('input')
      input.value = url
      document.body.appendChild(input)
      input.select()
      
      try {
        document.execCommand('copy')
        this.mostrarNotificacion('Enlace copiado al portapapeles', 'success')
      } catch (err) {
        console.error('Error al copiar', err)
        this.mostrarNotificacion('No se pudo copiar el enlace', 'error')
      }
      
      document.body.removeChild(input)
    }
  }
  
  mostrarNotificacion(mensaje, tipo = 'info') {
    // Crear notificación flotante
    const notificacion = document.createElement('div')
    
    const claseColor = tipo === 'success' ? 
                      'bg-green-600 border-green-700' : 
                      (tipo === 'error' ? 'bg-red-600 border-red-700' : 'bg-blue-600 border-blue-700')
    
    notificacion.className = `fixed bottom-4 right-4 px-4 py-2 rounded-lg shadow-lg z-50 ${claseColor} text-white border`
    notificacion.innerHTML = mensaje
    
    // Añadir al DOM
    document.body.appendChild(notificacion)
    
    // Animar entrada
    notificacion.style.animation = 'fadeInUp 0.3s ease-out forwards'
    
    // Eliminar después de 3 segundos
    setTimeout(() => {
      notificacion.style.animation = 'fadeOutDown 0.3s ease-in forwards'
      setTimeout(() => notificacion.remove(), 300)
    }, 3000)
  }
}

// Estilos de animación para notificaciones
if (!document.querySelector('#quiz-results-styles')) {
  const style = document.createElement('style')
  style.id = 'quiz-results-styles'
  style.textContent = `
    @keyframes fadeInUp {
      from {
        opacity: 0;
        transform: translateY(10px);
      }
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }
    
    @keyframes fadeOutDown {
      from {
        opacity: 1;
        transform: translateY(0);
      }
      to {
        opacity: 0;
        transform: translateY(10px);
      }
    }
  `
  document.head.appendChild(style)
}