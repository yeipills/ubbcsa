class MonitorMetricsJob < ApplicationJob
  queue_as :default

  def perform(sesion_id)
    sesion = SesionLaboratorio.find_by(id: sesion_id)
    return unless sesion && sesion.activa? && sesion.container_id.present?

    # Obtener métricas a través del servicio correspondiente
    if defined?(DockerLabService) && DockerLabService.respond_to?(:get_metrics)
      metrics = DockerLabService.get_metrics(sesion)
    else
      metrics = MetricsService.collect_metrics(sesion)
    end
    
    return if metrics.blank? || metrics.empty?

    # Guardar métricas en base de datos
    MetricaLaboratorio.create!(
      sesion_laboratorio: sesion,
      cpu_usage: metrics[:cpu_usage] || 0,
      memory_usage: metrics[:memory_usage] || 0,
      network_usage: (metrics[:network_received] || 0) + (metrics[:network_sent] || 0),
      timestamp: Time.current
    )
    
    # Transmitir métricas por varios canales para compatibilidad
    # Canal antiguo
    ActionCable.server.broadcast(
      "metrics_#{sesion_id}",
      metrics.to_json
    )
    
    # Canal nuevo más específico
    ActionCable.server.broadcast(
      "laboratorio_#{sesion_id}_metrics",
      { 
        type: 'metrics', 
        metrics: metrics 
      }
    )

    # Programar próxima ejecución si la sesión sigue activa
    self.class.set(wait: 5.seconds).perform_later(sesion_id) if sesion.reload.activa?
  end
end