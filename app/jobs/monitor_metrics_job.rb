class MonitorMetricsJob < ApplicationJob
  queue_as :default
  
  # Límite para almacenar métricas por sesión (para evitar sobrecarga de BD)
  METRICS_LIMIT_PER_SESSION = 100
  # Frecuencia de recolección de métricas (en segundos)
  COLLECTION_INTERVAL = 5

  def perform(sesion_id)
    sesion = SesionLaboratorio.find_by(id: sesion_id)
    return unless sesion && sesion.activa?

    # Verificar si tiene container_id (para métricas reales)
    # Si no, usaremos métricas simuladas pero mostraremos un mensaje
    unless sesion.container_id.present?
      Rails.logger.info("MonitorMetricsJob: Usando métricas simuladas para sesión #{sesion_id} - sin container_id")
    end

    # Obtener métricas a través del servicio correspondiente
    if defined?(DockerLabService) && DockerLabService.respond_to?(:get_metrics)
      metrics = DockerLabService.get_metrics(sesion)
    else
      # Usamos collect_metrics pero no guardaremos aquí en la DB para evitar duplicación
      metrics_service = MetricsService.new(sesion)
      metrics = metrics_service.collect_metrics(skip_db_save: true)
    end
    
    return if metrics.blank? || metrics.empty?

    # Guarda métricas en la base de datos
    begin
      # Asegurar que exista asociación con el laboratorio
      if sesion.laboratorio_id.present? 
        # Crear el registro
        metrica = MetricaLaboratorio.create!(
          sesion_laboratorio: sesion,
          laboratorio_id: sesion.laboratorio_id,
          cpu_usage: metrics[:cpu_usage] || 0,
          memory_usage: metrics[:memory_usage] || 0,
          network_usage: (metrics[:network_received] || 0) + (metrics[:network_sent] || 0),
          timestamp: Time.current
        )
        
        # Verificar si hay demasiadas métricas para esta sesión y limpiar antiguas
        cleanup_old_metrics(sesion)
      else
        Rails.logger.warn("MonitorMetricsJob: No se pudo guardar métrica para sesión #{sesion_id} - sin laboratorio_id")
      end
    rescue => e
      Rails.logger.error("MonitorMetricsJob: Error guardando métrica: #{e.message}")
    end
    
    # Preparar datos para transmitir por ActionCable
    metric_data = {
      type: 'metric',
      cpu: metrics[:cpu_usage] || 0,
      memory: metrics[:memory_usage] || 0,
      network: metrics[:network_usage] || metrics[:network_received] || 0,
      timestamp: Time.current
    }
    
    # Transmitir métricas usando el formato estándar
    MetricsChannel.broadcast_to(
      sesion,
      metric_data
    )

    # Programar próxima ejecución si la sesión sigue activa
    if sesion.reload.activa?
      self.class.set(wait: COLLECTION_INTERVAL.seconds).perform_later(sesion_id)
    else
      Rails.logger.info("MonitorMetricsJob: Finalizando monitoreo de métricas para sesión #{sesion_id}")
    end
  end
  
  private
  
  def cleanup_old_metrics(sesion)
    # Contar cuántas métricas tiene esta sesión
    count = MetricaLaboratorio.where(sesion_laboratorio_id: sesion.id).count
    
    # Si hay demasiadas, eliminar las más antiguas
    if count > METRICS_LIMIT_PER_SESSION
      # Encontrar ID del registro más antiguo que podemos eliminar
      oldest_to_keep = MetricaLaboratorio
                         .where(sesion_laboratorio_id: sesion.id)
                         .order(created_at: :desc)
                         .limit(METRICS_LIMIT_PER_SESSION)
                         .pluck(:id)
                         .last
      
      if oldest_to_keep
        # Eliminar todo lo que sea más antiguo que el último que queremos conservar
        MetricaLaboratorio
          .where(sesion_laboratorio_id: sesion.id)
          .where("id < ?", oldest_to_keep)
          .delete_all
      end
    end
  end
end