// app/javascript/controllers/quiz_chart_controller.js
import { Controller } from "@hotwired/stimulus"
import Chart from 'chart.js/auto'

export default class extends Controller {
  static values = {
    type: String,
    data: Array
  }

  connect() {
    this.initChart()
  }
  
  initChart() {
    const ctx = this.element.querySelector('canvas').getContext('2d')
    
    switch (this.typeValue) {
      case 'puntajes':
        this.createPuntajesChart(ctx)
        break
      case 'tiempos':
        this.createTiemposChart(ctx)
        break
      default:
        console.error('Tipo de gráfico no reconocido:', this.typeValue)
    }
  }
  
  createPuntajesChart(ctx) {
    // Agrupar puntajes en rangos
    const ranges = {
      '0-20': 0,
      '21-40': 0,
      '41-60': 0,
      '61-80': 0,
      '81-100': 0
    }
    
    this.dataValue.forEach(puntaje => {
      if (puntaje <= 20) ranges['0-20']++
      else if (puntaje <= 40) ranges['21-40']++
      else if (puntaje <= 60) ranges['41-60']++
      else if (puntaje <= 80) ranges['61-80']++
      else ranges['81-100']++
    })
    
    // Crear colores según rango
    const colors = [
      'rgba(239, 68, 68, 0.7)', // Rojo - suspenso
      'rgba(245, 158, 11, 0.7)', // Naranja - bajo
      'rgba(251, 191, 36, 0.7)', // Amarillo - aprobado justo
      'rgba(52, 211, 153, 0.7)', // Verde claro - bien
      'rgba(16, 185, 129, 0.7)'  // Verde - excelente
    ]
    
    // Crear gráfico
    new Chart(ctx, {
      type: 'bar',
      data: {
        labels: Object.keys(ranges),
        datasets: [{
          label: 'Distribución de Puntajes',
          data: Object.values(ranges),
          backgroundColor: colors,
          borderColor: colors.map(color => color.replace('0.7', '1')),
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                const value = context.raw
                const total = context.dataset.data.reduce((a, b) => a + b, 0)
                const percentage = ((value / total) * 100).toFixed(1)
                return `${value} estudiantes (${percentage}%)`
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
    })
  }
  
  createTiemposChart(ctx) {
    // Implementar gráfico de tiempos similar al de puntajes
    // ...
  }
}