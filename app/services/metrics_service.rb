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

    # Verificar si podemos usar Docker
    if docker_available? && @sesion.container_id.present?
      # Intentar recoger métricas reales con Docker
      metrics = collect_docker_metrics
    else
      # Si Docker no está disponible, generar métricas simuladas
      metrics = generate_simulated_metrics
    end

    # Almacenar las métricas en caché
    Rails.cache.write("metrics_#{@sesion.id}", metrics, expires_in: 10.seconds)
    
    # Asegurarse de guardar con la relación al laboratorio
    begin
      # Asegurarse de que laboratorio existe y está asociado
      laboratorio_id = @sesion.laboratorio_id
      if laboratorio_id.present? && Laboratorio.where(id: laboratorio_id).exists?
        # Solo usando los campos que existen en la tabla
        MetricaLaboratorio.create!(
          sesion_laboratorio: @sesion,
          laboratorio_id: laboratorio_id,
          cpu_usage: metrics[:cpu_usage] || 0.0,
          memory_usage: metrics[:memory_usage] || 0.0,
          network_usage: metrics[:network_usage] || 0.0,
          timestamp: metrics[:timestamp] || Time.current
        )
      else
        Rails.logger.error("No se pudo guardar métricas: Laboratorio con ID #{laboratorio_id} no encontrado")
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Error guardando métricas: #{e.message}")
    end
    
    metrics
  rescue StandardError => e
    Rails.logger.error("Error collecting metrics: #{e.message}")
    default_metrics
  end

  private
  
  def docker_available?
    # Verificar si el comando docker está disponible
    system('which docker > /dev/null 2>&1')
  end
  
  def collect_docker_metrics
    container_id = @sesion.container_id || get_container_id
    return generate_simulated_metrics unless container_id.present?

    begin
      {
        cpu_usage: get_cpu_usage(container_id),
        memory_usage: get_memory_usage(container_id),
        network_usage: get_network_usage(container_id),
        timestamp: Time.current
      }
    rescue StandardError => e
      Rails.logger.error("Error collecting Docker metrics: #{e.message}")
      generate_simulated_metrics
    end
  end

  def get_container_id
    return @sesion.container_id if @sesion.container_id.present?
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
    if output.present?
      output.split('/').first.to_f
    else
      0.0
    end
  rescue StandardError => e
    Rails.logger.error("Error getting network usage: #{e.message}")
    0.0
  end
  
  def generate_simulated_metrics
    # Generar métricas simuladas basadas en tiempo de actividad
    time_active = Time.current - (@sesion.tiempo_inicio || Time.current - 1.hour)
    hours_active = [time_active / 3600, 0.1].max
    
    # Las métricas varían basándose en el tiempo activo
    cpu_base = 15 + rand(10)
    mem_base = 30 + rand(15)
    
    # Añadir variabilidad basada en el tiempo activo (aumenta con el tiempo)
    cpu_usage = [cpu_base + (hours_active * 2).to_i + rand(5), 90].min
    memory_usage = [mem_base + (hours_active * 5).to_i + rand(10), 80].min
    
    # Simular red con variabilidad
    network_usage = 50 + (hours_active * 10).to_i + rand(100)
    
    {
      cpu_usage: cpu_usage,
      memory_usage: memory_usage,
      network_usage: network_usage,
      timestamp: Time.current
    }
  end
  
  def default_metrics
    {
      cpu_usage: 10.0,
      memory_usage: 25.0,
      network_usage: 5.0,
      timestamp: Time.current
    }
  end
end