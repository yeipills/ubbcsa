class MonitorMetricsJob < ApplicationJob
  queue_as :default

  def perform(sesion_id)
    sesion = SesionLaboratorio.find(sesion_id)
    return unless sesion.activa?

    metrics = MetricsService.collect_metrics(sesion)
    
    ActionCable.server.broadcast(
      "metrics_#{sesion_id}",
      metrics.to_json
    )

    # Programar próxima ejecución
    self.class.set(wait: 5.seconds).perform_later(sesion_id) if sesion.reload.activa?
  end
end