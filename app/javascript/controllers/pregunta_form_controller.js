// app/javascript/controllers/pregunta_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tipoSelect", "respuestaCorta", "imagePreview", "previewImage"]

  connect() {
    this.tipoChanged()
  }

  tipoChanged() {
    const tipo = this.tipoSelectTarget.value
    
    if (tipo === "respuesta_corta") {
      this.respuestaCortaTarget.classList.remove("hidden")
    } else {
      this.respuestaCortaTarget.classList.add("hidden")
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
}