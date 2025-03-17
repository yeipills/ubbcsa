// app/javascript/controllers/activity_chart_controller.js
import { Controller } from "@hotwired/stimulus"
import Chart from 'chart.js/auto'

export default class extends Controller {
  connect() {
    const data = JSON.parse(this.element.dataset.activityChartData)
    this.initChart(data)
  }

  initChart(data) {
    const ctx = this.element.querySelector('canvas').getContext('2d')
    
    new Chart(ctx, {
      type: 'line',
      data: {
        labels: data.labels,
        datasets: [{
          label: 'Tiempo en Laboratorios',
          data: data.values,
          borderColor: 'rgb(59, 130, 246)',
          tension: 0.1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom'
          }
        },
        scales: {
          y: {
            beginAtZero: true
          }
        }
      }
    })
  }
}