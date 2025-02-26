import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

export default class extends Controller {
  static targets = ["chart"]

  connect() {
    this.subscription = consumer.subscriptions.create({
      channel: "MetricsChannel",
      sesion_id: this.element.dataset.sesionId
    }, {
      received: (data) => this.updateMetrics(data)
    })
  }

  updateMetrics(data) {
    // Actualizar gráficos/métricas usando la librería de visualización preferida
  }

  disconnect() {
    this.subscription.unsubscribe()
  }
}