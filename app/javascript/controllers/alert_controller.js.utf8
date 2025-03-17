// app/javascript/controllers/alert_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    autoDismiss: Boolean,
    dismissAfter: Number
  }

  connect() {
    if (this.autoDismissValue) {
      setTimeout(() => {
        this.dismiss()
      }, this.dismissAfterValue)
    }
  }

  dismiss() {
    this.element.classList.add('fade-out')
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}