// app/javascript/controllers/quiz_chart_controller.js
import { Controller } from "@hotwired/stimulus"
import Chart from 'chart.js/auto'

/**
 * Controlador para gráficos de estadísticas de quizzes
 * 
 * Este controlador maneja varios tipos de visualizaciones:
 * - puntajes: Distribución de puntajes en rangos
 * - tiempos: Distribución de tiempos de respuesta
 * - aciertos: Tasas de acierto por pregunta
 * - progreso: Gráfico de línea de progreso
 */
export default class extends Controller {
  static targets = ["puntajes", "tiempos", "aciertos", "progreso"]
  static values = { 
    data: Object,
    colors: {
      type: Array,
      default: ['#EF4444', '#F59E0B', '#FBBF24', '#34D399', '#10B981']
    }
  }
  
  connect() {
    console.log("Quiz Chart controller conectado")
    this.initializeCharts()
  }
  
  /**
   * Inicializa todos los gráficos disponibles según los targets presentes
   */
  initializeCharts() {
    if (this.hasPuntajesTarget) this.initializePuntajesChart()
    if (this.hasTiemposTarget) this.initializeTiemposChart()
    if (this.hasAciertosTarget) this.initializeAciertosChart()
    if (this.hasProgresoTarget) this.initializeProgresoChart()
  }
  
  /**
   * Inicializa el gráfico de distribución de puntajes
   */
  initializePuntajesChart() {
    const ctx = this.puntajesTarget.getContext('2d')
    const data = this.dataValue
    
    new Chart(ctx, {
      type: 'bar',
      data: {
        labels: data.rangos || ['0-20', '21-40', '41-60', '61-80', '81-100'],
        datasets: [{
          label: 'Distribución de Puntajes',
          data: data.valores || [],
          backgroundColor: this.colorsValue.map(c => `${c}80`), // con transparencia
          borderColor: this.colorsValue,
          borderWidth: 1
        }]
      },
      options: this.getChartOptions('Distribución de Puntajes')
    })
  }
  
  /**
   * Inicializa el gráfico de distribución de tiempos
   */
  initializeTiemposChart() {
    const ctx = this.tiemposTarget.getContext('2d')
    const data = this.dataValue
    
    new Chart(ctx, {
      type: 'bar',
      data: {
        labels: data.rangos_tiempo || ['< 5 min', '5-10 min', '10-15 min', '15-20 min', '> 20 min'],
        datasets: [{
          label: 'Tiempo de Resolución',
          data: data.valores_tiempo || [],
          backgroundColor: 'rgba(59, 130, 246, 0.5)',
          borderColor: 'rgb(59, 130, 246)',
          borderWidth: 1
        }]
      },
      options: this.getChartOptions('Distribución de Tiempos')
    })
  }
  
  /**
   * Inicializa el gráfico de tasas de acierto por pregunta
   */
  initializeAciertosChart() {
    const ctx = this.aciertosTarget.getContext('2d')
    const data = this.dataValue
    
    new Chart(ctx, {
      type: 'horizontalBar',
      data: {
        labels: data.preguntas || [],
        datasets: [{
          label: 'Tasa de Acierto (%)',
          data: data.tasas_acierto || [],
          backgroundColor: data.tasas_acierto?.map(tasa => {
            if (tasa >= 80) return 'rgba(16, 185, 129, 0.7)' // verde
            if (tasa >= 60) return 'rgba(245, 158, 11, 0.7)' // naranja
            return 'rgba(239, 68, 68, 0.7)' // rojo
          }) || [],
          borderWidth: 0
        }]
      },
      options: {
        indexAxis: 'y',
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                return `${context.raw}% de acierto`
              }
            }
          }
        },
        scales: {
          x: {
            beginAtZero: true,
            max: 100,
            grid: {
              color: 'rgba(255, 255, 255, 0.1)'
            },
            ticks: {
              color: 'rgba(255, 255, 255, 0.7)'
            }
          },
          y: {
            grid: {
              display: false
            },
            ticks: {
              color: 'rgba(255, 255, 255, 0.7)'
            }
          }
        }
      }
    })
  }
  
  /**
   * Inicializa el gráfico de línea de progreso
   */
  initializeProgresoChart() {
    const ctx = this.progresoTarget.getContext('2d')
    const data = this.dataValue
    
    new Chart(ctx, {
      type: 'line',
      data: {
        labels: data.fechas || [],
        datasets: [{
          label: 'Puntaje Promedio',
          data: data.promedios || [],
          borderColor: 'rgb(59, 130, 246)',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          tension: 0.4,
          fill: true
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: true,
            labels: {
              color: 'rgba(255, 255, 255, 0.7)'
            }
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            grid: {
              color: 'rgba(255, 255, 255, 0.1)'
            },
            ticks: {
              color: 'rgba(255, 255, 255, 0.7)'
            }
          },
          x: {
            grid: {
              display: false
            },
            ticks: {
              color: 'rgba(255, 255, 255, 0.7)'
            }
          }
        }
      }
    })
  }
  
  /**
   * Obtiene opciones comunes para los gráficos
   * @param {string} title - Título del gráfico
   * @returns {Object} Opciones de configuración del gráfico
   */
  getChartOptions(title) {
    return {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: false
        },
        title: {
          display: false,
          text: title,
          color: 'rgba(255, 255, 255, 0.9)',
          font: {
            size: 16
          }
        },
        tooltip: {
          callbacks: {
            label: function(context) {
              const value = context.raw
              const total = context.dataset.data.reduce((a, b) => a + b, 0)
              const percentage = total > 0 ? ((value / total) * 100).toFixed(1) : 0
              return `${value} (${percentage}%)`
            }
          }
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          ticks: {
            precision: 0,
            color: 'rgba(255, 255, 255, 0.7)'
          },
          grid: {
            color: 'rgba(255, 255, 255, 0.1)'
          }
        },
        x: {
          ticks: {
            color: 'rgba(255, 255, 255, 0.7)'
          },
          grid: {
            display: false
          }
        }
      }
    }
  }
}