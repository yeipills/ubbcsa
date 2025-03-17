import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"
import Chart from 'chart.js/auto'

export default class extends Controller {
  static targets = ["chart"]
  static values = {
    sesionId: String
  }

  connect() {
    if (!this.hasSesionIdValue) {
      this.sesionIdValue = this.element.dataset.sesionId
    }
    
    if (!this.sesionIdValue) {
      console.error("No se ha proporcionado el ID de sesin para las mtricas")
      return
    }

    this.initChart()
    this.setupSubscription()
    
    // Limitar los datos en memoria
    this.dataPoints = []
    this.MAX_DATA_POINTS = 30
  }

  initChart() {
    if (!this.hasChartTarget) return
    
    const ctx = this.chartTarget.getContext('2d')
    
    this.chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: [],
        datasets: [
          {
            label: 'CPU (%)',
            borderColor: 'rgb(75, 192, 192)',
            backgroundColor: 'rgba(75, 192, 192, 0.2)',
            data: [],
            fill: true,
            tension: 0.2
          },
          {
            label: 'Memoria (%)',
            borderColor: 'rgb(153, 102, 255)',
            backgroundColor: 'rgba(153, 102, 255, 0.2)',
            data: [],
            fill: true,
            tension: 0.2
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            max: 100,
            ticks: {
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
              color: 'rgba(255, 255, 255, 0.1)'
            }
          }
        },
        animation: {
          duration: 500
        }
      }
    })
  }

  setupSubscription() {
    this.subscription = consumer.subscriptions.create({
      channel: "MetricsChannel",
      sesion_id: this.sesionIdValue
    }, {
      received: (data) => this.updateMetrics(data)
    })
  }

  updateMetrics(data) {
    if (!this.chart) return
    
    // Verificar si los datos recibidos son un objeto con propiedades especficas
    if (data && (data.type === 'metric' || data.cpu_usage !== undefined)) {
      // Guardar el punto de datos para referencia futura
      this.dataPoints.push(data)
      
      // Limitar el nmero de puntos para evitar problemas de memoria
      if (this.dataPoints.length > this.MAX_DATA_POINTS) {
        this.dataPoints.shift()
      }
      
      // Formatear la etiqueta de tiempo
      const timestamp = data.timestamp ? new Date(data.timestamp) : new Date()
      const timeLabel = timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })
      
      // Actualizar las etiquetas (eje X)
      this.chart.data.labels = this.dataPoints.map(point => {
        const time = point.timestamp ? new Date(point.timestamp) : new Date()
        return time.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })
      })
      
      // Actualizar los datos (datasets)
      this.chart.data.datasets[0].data = this.dataPoints.map(point => 
        point.cpu_usage || point.cpu || 0
      )
      
      this.chart.data.datasets[1].data = this.dataPoints.map(point => 
        point.memory_usage || point.memory || 0
      )
      
      // Actualizar el grfico
      this.chart.update()
      
      // Tambin actualizar elementos DOM si es necesario
      this.updateMetricElements(data)
    }
  }
  
  updateMetricElements(data) {
    // Actualizar elementos DOM con valores de mtricas si existen
    const cpuElement = document.querySelector('[data-metric="cpu"]')
    const memElement = document.querySelector('[data-metric="memory"]')
    const netElement = document.querySelector('[data-metric="network"]')
    
    if (cpuElement) {
      cpuElement.textContent = `${Math.round(data.cpu_usage || data.cpu || 0)}%`
    }
    
    if (memElement) {
      memElement.textContent = `${Math.round(data.memory_usage || data.memory || 0)}%`
    }
    
    if (netElement) {
      netElement.textContent = `${Math.round(data.network_usage || data.network || 0)} KB/s`
    }
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    
    if (this.chart) {
      this.chart.destroy()
    }
  }
}