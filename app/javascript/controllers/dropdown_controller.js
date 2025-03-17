// app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  
  connect() {
    // Cerrar el men al hacer clic fuera de l
    this.clickOutsideHandler = this.closeMenuOnClickOutside.bind(this)
    document.addEventListener("click", this.clickOutsideHandler)
  }
  
  disconnect() {
    document.removeEventListener("click", this.clickOutsideHandler)
  }
  
  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")
  }
  
  closeMenuOnClickOutside(event) {
    if (!this.element.contains(event.target) && !this.menuTarget.classList.contains("hidden")) {
      this.menuTarget.classList.add("hidden")
    }
  }
}