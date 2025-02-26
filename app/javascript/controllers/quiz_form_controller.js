// app/javascript/controllers/quiz_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["curso", "laboratorio"]

  connect() {
    if (this.hasCursoTarget && this.hasLaboratorioTarget) {
      this.loadLaboratorios()
    }
  }

  loadLaboratorios() {
    const cursoId = this.cursoTarget.value
    if (!cursoId) return

    fetch(`/cursos/${cursoId}/laboratorios`)
      .then(response => response.json())
      .then(laboratorios => {
        this.laboratorioTarget.innerHTML = ''
        laboratorios.forEach(lab => {
          const option = new Option(lab.nombre, lab.id)
          this.laboratorioTarget.add(option)
        })
      })
  }

  cursoChanged() {
    this.loadLaboratorios()
  }
}