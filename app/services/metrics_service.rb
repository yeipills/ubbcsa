# app/services/metrics_service.rb
class MetricsService
  class << self
    def collect_metrics(sesion_laboratorio, options = {})
      new(sesion_laboratorio).collect_metrics(options)
    end
    
    def system_metrics
      {
        cpu_usage: get_system_cpu_usage,
        memory_usage: get_system_memory_usage,
        disk_usage: get_system_disk_usage,
        uptime: get_system_uptime
      }
    end
    
    private
    
    def get_system_cpu_usage
      # Valor simulado para CPU
      rand(20.0..50.0).round(1)
    end
    
    def get_system_memory_usage
      # Valor simulado para memoria
      rand(40.0..70.0).round(1)
    end
    
    def get_system_disk_usage
      # Valor simulado para disco
      rand(30.0..80.0).round(1)
    end
    
    def get_system_uptime
      # Simulación de tiempo activo (entre 1 y 30 días)
      "#{rand(1..30)} días, #{rand(0..23)} horas"
    end
  end

  def initialize(sesion_laboratorio)
    @sesion = sesion_laboratorio
  end

  def collect_metrics(options = {})
    skip_db_save = options[:skip_db_save] || false
    return {} unless @sesion

    # Verificar si podemos usar Docker
    if docker_available? && @sesion.container_id.present?
      # Intentar recoger métricas reales con Docker
      metrics = collect_docker_metrics
    else
      # Si Docker no está disponible, generar métricas simuladas
      metrics = generate_simulated_metrics
    end

    # Almacenar las métricas en caché (útil para lecturas rápidas)
    Rails.cache.write("metrics_#{@sesion.id}", metrics, expires_in: 10.seconds)
    
    # Guardar en la base de datos si no se indica lo contrario
    # MonitorMetricsJob ahora se encarga de guardar en la BD
    unless skip_db_save
      save_metrics_to_database(metrics)
    end
    
    metrics
  rescue StandardError => e
    Rails.logger.error("Error collecting metrics: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n")) if Rails.env.development?
    default_metrics
  end
  
  # Método público para obtener métricas de caché 
  def get_cached_metrics
    cached = Rails.cache.read("metrics_#{@sesion.id}")
    return cached if cached.present?
    
    # Si no hay en caché, generar nuevas
    collect_metrics
  end

  private
  
  def save_metrics_to_database(metrics)
    # Solo guardar si la sesión tiene laboratorio asociado
    return unless @sesion.laboratorio_id.present?
    
    begin
      MetricaLaboratorio.create!(
        sesion_laboratorio: @sesion,
        laboratorio_id: @sesion.laboratorio_id,
        cpu_usage: metrics[:cpu_usage] || 0.0,
        memory_usage: metrics[:memory_usage] || 0.0,
        network_usage: metrics[:network_usage] || 0.0,
        timestamp: metrics[:timestamp] || Time.current
      )
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Error guardando métricas: #{e.message}")
    end
  end
  
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
      # Procesar el formato como "1.45MB / 2.3MB"
      received = output.split('/').first.strip
      # Convertir a KB para tener un formato estándar
      value = parse_size_to_kb(received)
      value.to_f
    else
      0.0
    end
  rescue StandardError => e
    Rails.logger.error("Error getting network usage: #{e.message}")
    0.0
  end
  
  # Convertir diferentes unidades a KB
  def parse_size_to_kb(size_str)
    if size_str =~ /(\d+(\.\d+)?)\s*([KMGT]?B)/i
      value = $1.to_f
      unit = $3.upcase
      
      case unit
      when 'B'  
        value / 1024.0
      when 'KB' 
        value
      when 'MB' 
        value * 1024.0
      when 'GB' 
        value * 1024.0 * 1024.0
      when 'TB' 
        value * 1024.0 * 1024.0 * 1024.0
      else
        value
      end
    else
      0.0
    end
  end
  
  def generate_simulated_metrics
    # Generar métricas simuladas basadas en tiempo de actividad
    time_active = Time.current - (@sesion.tiempo_inicio || Time.current - 1.hour)
    hours_active = [time_active / 3600, 0.1].max
    
    # Patrón sinusoidal para simular variación más realista
    time_factor = ((Time.current.to_i / 60) % 10) / 10.0  # Varía entre 0 y 1 cada 10 minutos
    sin_factor = (Math.sin(time_factor * Math::PI * 2) + 1) / 2  # Transforma a rango 0-1
    
    # Las métricas varían basándose en el tiempo activo
    cpu_base = 15 + rand(10)
    mem_base = 30 + rand(15)
    
    # Añadir variabilidad basada en el tiempo activo (aumenta con el tiempo)
    cpu_variation = 15 * sin_factor
    cpu_usage = [cpu_base + (hours_active * 2).to_i + cpu_variation, 95].min
    
    memory_variation = 20 * sin_factor
    memory_usage = [mem_base + (hours_active * 3).to_i + memory_variation, 85].min
    
    # Simular red con variabilidad
    network_variation = 50 * sin_factor
    network_usage = 30 + (hours_active * 8).to_i + network_variation + rand(20)
    
    {
      cpu_usage: cpu_usage.round(1),
      memory_usage: memory_usage.round(1),
      network_usage: network_usage.round,
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