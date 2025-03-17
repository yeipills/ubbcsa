// app/javascript/controllers/flash_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Flash controller connected!")
    this.timeout = setTimeout(() => {
      console.log("Attempting auto-close...")
      this.close()
    }, 5000)
  }

  close(event) {
    console.log("Close method called!")
    if (event) event.preventDefault()
    
    this.element.classList.add('animate-fade-out')
    setTimeout(() => {
      console.log("Removing element...")
      this.element.remove()
    }, 300)

    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  disconnect() {
    console.log("Flash controller disconnected!")
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }
}