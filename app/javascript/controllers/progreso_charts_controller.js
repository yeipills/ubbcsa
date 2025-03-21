// app/javascript/controllers/progreso_charts_controller.js
import { Controller } from "@hotwired/stimulus"
import Chart from 'chart.js/auto'

export default class extends Controller {
  static targets = [
    "activityChart", 
    "difficultyChart", 
    "skillsChart", 
    "progressChart",
    "courseProgressChart"
  ]
  
  static values = {
    periodo: String,
    cursoId: Number
  }
  
  connect() {
    this.fetchChartData()
    this.setupFilterListeners()
  }
  
  setupFilterListeners() {
    // Configurar listeners para filtros de perodo
    document.querySelectorAll('[data-action="progreso-charts#changePeriod"]').forEach(element => {
      element.addEventListener('click', this.changePeriod.bind(this))
    })
    
    // Configurar listeners para filtros de curso
    document.querySelectorAll('[data-action="progreso-charts#changeCourse"]').forEach(element => {
      element.addEventListener('click', this.changeCourse.bind(this))
    })
  }
  
  changePeriod(event) {
    event.preventDefault()
    const periodo = event.currentTarget.dataset.periodo
    this.periodoValue = periodo
    
    // Actualizar la URL para mantener el estado de filtrado
    const url = new URL(window.location)
    url.searchParams.set('periodo', periodo)
    history.pushState({}, '', url)
    
    // Recargar datos
    this.fetchChartData()
  }
  
  changeCourse(event) {
    event.preventDefault()
    const cursoId = event.currentTarget.dataset.cursoId
    this.cursoIdValue = cursoId
    
    // Actualizar la URL para mantener el estado de filtrado
    const url = new URL(window.location)
    url.searchParams.set('curso_id', cursoId)
    history.pushState({}, '', url)
    
    // Recargar pgina completa para actualizar todos los datos
    window.location.reload()
  }
  
  fetchChartData() {
    const url = `/progreso/chart_data?periodo=${this.periodoValue}`
    
    fetch(url)
      .then(response => response.json())
      .then(data => {
        this.initializeCharts(data)
      })
      .catch(error => {
        console.error('Error fetching chart data:', error)
      })
  }
  
  initializeCharts(data) {
    if (this.hasActivityChartTarget) {
      this.initializeActivityChart(data)
    }
    
    if (this.hasDifficultyChartTarget && data.distribucion_completados) {
      this.initializeDifficultyChart(data.distribucion_completados)
    }
    
    if (this.hasSkillsChartTarget && data.distribucion_habilidades) {
      this.initializeSkillsChart(data.distribucion_habilidades)
    }
    
    if (this.hasProgressChartTarget && data.progreso_cursos) {
      this.initializeProgressChart(data.progreso_cursos)
    }
    
    if (this.hasCourseProgressChartTarget && data.progreso_promedio) {
      this.initializeCourseProgressChart(data.progreso_promedio)
    }
  }
  
  initializeActivityChart(data) {
    const ctx = this.activityChartTarget.getContext('2d')
    
    // Destruir grfico existente si hay uno
    if (this.activityChart) {
      this.activityChart.destroy()
    }
    
    this.activityChart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: data.labels,
        datasets: [{
          label: 'Sesiones de Laboratorio',
          data: data.values,
          borderColor: 'rgb(59, 130, 246)',
          backgroundColor: 'rgba(59, 130, 246, 0.1)',
          borderWidth: 2,
          tension: 0.1,
          fill: true
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom'
          },
          tooltip: {
            mode: 'index',
            intersect: false
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              precision: 0
            }
          }
        }
      }
    })
  }
  
  initializeDifficultyChart(data) {
    const ctx = this.difficultyChartTarget.getContext('2d')
    
    // Destruir grfico existente si hay uno
    if (this.difficultyChart) {
      this.difficultyChart.destroy()
    }
    
    // Preparar datos
    const labels = Object.keys(data)
    const values = Object.values(data)
    const backgroundColors = {
      'principiante': 'rgba(34, 197, 94, 0.7)',
      'intermedio': 'rgba(234, 179, 8, 0.7)',
      'avanzado': 'rgba(239, 68, 68, 0.7)'
    }
    
    this.difficultyChart = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: labels.map(label => this.capitalizeFirstLetter(label)),
        datasets: [{
          data: values,
          backgroundColor: labels.map(label => backgroundColors[label] || 'rgba(107, 114, 128, 0.7)')
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom'
          }
        }
      }
    })
  }
  
  initializeSkillsChart(data) {
    const ctx = this.skillsChartTarget.getContext('2d')
    
    // Destruir grfico existente si hay uno
    if (this.skillsChart) {
      this.skillsChart.destroy()
    }
    
    // Preparar datos
    const labels = data.map(item => this.formatTipoLaboratorio(item.tipo))
    const values = data.map(item => item.count)
    const backgroundColors = [
      'rgba(59, 130, 246, 0.7)',
      'rgba(139, 92, 246, 0.7)',
      'rgba(16, 185, 129, 0.7)',
      'rgba(245, 158, 11, 0.7)',
      'rgba(236, 72, 153, 0.7)'
    ]
    
    this.skillsChart = new Chart(ctx, {
      type: 'polarArea',
      data: {
        labels: labels,
        datasets: [{
          data: values,
          backgroundColor: backgroundColors
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom'
          }
        }
      }
    })
  }
  
  initializeProgressChart(data) {
    const ctx = this.progressChartTarget.getContext('2d')
    
    // Destruir grfico existente si hay uno
    if (this.progressChart) {
      this.progressChart.destroy()
    }
    
    // Preparar datos
    const labels = data.map(item => item.curso.nombre)
    const porcentajes = data.map(item => item.porcentaje)
    
    this.progressChart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [{
          label: 'Progreso %',
          data: porcentajes,
          backgroundColor: 'rgba(59, 130, 246, 0.7)',
          borderColor: 'rgb(59, 130, 246)',
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        indexAxis: 'y',
        plugins: {
          legend: {
            display: false
          }
        },
        scales: {
          x: {
            beginAtZero: true,
            max: 100,
            title: {
              display: true,
              text: 'Progreso (%)'
            }
          }
        }
      }
    })
  }
  
  initializeCourseProgressChart(data) {
    const ctx = this.courseProgressChartTarget.getContext('2d')
    
    // Destruir grfico existente si hay uno
    if (this.courseProgressChart) {
      this.courseProgressChart.destroy()
    }
    
    // Preparar datos
    const labels = data.map(item => item.curso.nombre)
    const porcentajes = data.map(item => item.promedio)
    
    this.courseProgressChart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [{
          label: 'Progreso Promedio %',
          data: porcentajes,
          backgroundColor: 'rgba(16, 185, 129, 0.7)',
          borderColor: 'rgb(16, 185, 129)',
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            max: 100,
            title: {
              display: true,
              text: 'Progreso Promedio (%)'
            }
          }
        }
      }
    })
  }
  
  // Utilidades para formateo
  capitalizeFirstLetter(string) {
    return string.charAt(0).toUpperCase() + string.slice(1)
  }
  
  formatTipoLaboratorio(tipo) {
    const mapping = {
      'pentesting': 'Pentesting',
      'forense': 'Forense',
      'redes': 'Redes',
      'web': 'Web',
      'exploit': 'Exploits',
      'escaneo_red': 'Escaneo',
      'fuerza_bruta': 'Fuerza Bruta',
      'analisis_trafico': 'Anlisis de Trfico'
    }
    
    return mapping[tipo] || this.capitalizeFirstLetter(tipo)
  }
}