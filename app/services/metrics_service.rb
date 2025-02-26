# app/services/metrics_service.rb
class MetricsService
  class << self
    def collect_metrics(sesion_laboratorio)
      new(sesion_laboratorio).collect_metrics
    end
  end

  def initialize(sesion_laboratorio)
    @sesion = sesion_laboratorio
  end

  def collect_metrics
    return {} unless @sesion && @sesion.laboratorio

    container_id = get_container_id
    return {} unless container_id

    metrics = {
      cpu_usage: get_cpu_usage(container_id),
      memory_usage: get_memory_usage(container_id),
      network_usage: get_network_usage(container_id),
      timestamp: Time.current
    }

    # Almacenar las métricas en caché
    Rails.cache.write("metrics_#{@sesion.id}", metrics, expires_in: 10.seconds)
    
    # Solo intentar crear el registro si tiene un laboratorio válido
    begin
      @sesion.metrica_laboratorios.create!(metrics)
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Error guardando métricas: #{e.message}")
    end
    
    metrics
  rescue StandardError => e
    Rails.logger.error("Error collecting metrics: #{e.message}")
    {
      cpu_usage: 0.0,
      memory_usage: 0.0,
      network_usage: 0.0,
      timestamp: Time.current
    }
  end

  private

  def get_container_id
    return nil unless @sesion.laboratorio&.tipo
    
    begin
      `docker ps -qf "name=#{@sesion.laboratorio.tipo}"`.strip
    rescue StandardError => e
      Rails.logger.error("Error getting container ID: #{e.message}")
      nil
    end
  end

  def get_cpu_usage(container_id)
    output = `docker stats --no-stream --format "{{.CPUPerc}}" #{container_id} 2>/dev/null`.strip
    # Eliminar el símbolo % si existe y convertir a float
    output.gsub('%', '').to_f
  rescue StandardError => e
    Rails.logger.error("Error getting CPU usage: #{e.message}")
    0.0
  end

  def get_memory_usage(container_id)
    output = `docker stats --no-stream --format "{{.MemPerc}}" #{container_id} 2>/dev/null`.strip
    # Eliminar el símbolo % si existe y convertir a float
    output.gsub('%', '').to_f
  rescue StandardError => e
    Rails.logger.error("Error getting memory usage: #{e.message}")
    0.0
  end

  def get_network_usage(container_id)
    output = `docker stats --no-stream --format "{{.NetIO}}" #{container_id} 2>/dev/null`.strip
    # Extraer el primer número (recibido) de una cadena como "1.45MB / 2.3MB"
    output.split('/').first.to_f
  rescue StandardError => e
    Rails.logger.error("Error getting network usage: #{e.message}")
    0.0
  end
end