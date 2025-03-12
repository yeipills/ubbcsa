# app/services/docker_lab_service.rb
class DockerLabService
  # Configuraciones por tipo de entorno
  ENVIRONMENT_CONFIGS = {
    pentesting: {
      image: 'kali-pentesting:latest',
      tools: %w[nmap metasploit-framework burpsuite wireshark hydra],
      network: 'isolated',
      resource_limits: { cpu: 2, memory: '2g' }
    },
    forense: {
      image: 'kali-forensic:latest',
      tools: %w[autopsy volatility sleuthkit binwalk foremost],
      network: 'isolated',
      resource_limits: { cpu: 2, memory: '3g' }
    },
    redes: {
      image: 'kali-network:latest',
      tools: %w[nmap wireshark tcpdump netcat hping3],
      network: 'lab-network',
      resource_limits: { cpu: 1, memory: '1g' }
    },
    web: {
      image: 'kali-web:latest',
      tools: %w[burpsuite owasp-zap sqlmap dirb nikto],
      network: 'lab-network',
      resource_limits: { cpu: 1, memory: '1.5g' }
    }
  }

  # Iniciar un nuevo entorno de laboratorio
  def self.create_environment(sesion_laboratorio)
    tipo = sesion_laboratorio.laboratorio.tipo.to_sym
    config = ENVIRONMENT_CONFIGS[tipo] || ENVIRONMENT_CONFIGS[:pentesting]

    container_name = "lab-#{sesion_laboratorio.id}-#{SecureRandom.hex(4)}"

    # Guardar nombre del contenedor para futuras operaciones
    sesion_laboratorio.update(container_id: container_name)

    # Construir comando Docker para crear contenedor
    cmd = [
      'docker run -d',
      "--name #{container_name}",
      "--cpus=#{config[:resource_limits][:cpu]}",
      "--memory=#{config[:resource_limits][:memory]}",
      "--network=#{config[:network]}",
      "-e USER_ID=#{sesion_laboratorio.usuario.id}",
      "-e SESSION_ID=#{sesion_laboratorio.id}",
      "-e LAB_TYPE=#{tipo}",
      "-v #{data_volume_path(sesion_laboratorio)}:/home/kali/data",
      "#{config[:image]}"
    ].join(' ')

    # Ejecutar comando
    result = `#{cmd} 2>&1`
    success = $?.success?

    if success
      # Inicializar herramientas y configuración específica para el tipo de laboratorio
      initialize_tools(container_name, config[:tools])
      Rails.logger.info("Contenedor #{container_name} creado exitosamente para sesión #{sesion_laboratorio.id}")
      setup_monitoring(container_name, sesion_laboratorio.id)
      true
    else
      Rails.logger.error("Error al crear contenedor para sesión #{sesion_laboratorio.id}: #{result}")
      false
    end
  end

  # Pausar el entorno (sin destruirlo)
  def self.pause_environment(sesion_laboratorio)
    return true unless sesion_laboratorio.container_id

    result = `docker pause #{sesion_laboratorio.container_id} 2>&1`
    success = $?.success?

    if success
      Rails.logger.info("Contenedor #{sesion_laboratorio.container_id} pausado exitosamente")
      true
    else
      Rails.logger.error("Error al pausar contenedor #{sesion_laboratorio.container_id}: #{result}")
      false
    end
  end

  # Reanudar entorno pausado
  def self.resume_environment(sesion_laboratorio)
    return true unless sesion_laboratorio.container_id

    result = `docker unpause #{sesion_laboratorio.container_id} 2>&1`
    success = $?.success?

    if success
      Rails.logger.info("Contenedor #{sesion_laboratorio.container_id} reanudado exitosamente")
      true
    else
      Rails.logger.error("Error al reanudar contenedor #{sesion_laboratorio.container_id}: #{result}")
      false
    end
  end

  # Restaurar entorno a estado inicial
  def self.restore_environment(sesion_laboratorio)
    destroy_environment(sesion_laboratorio)
    create_environment(sesion_laboratorio)
  end

  # Destruir entorno completamente
  def self.destroy_environment(sesion_laboratorio)
    return true unless sesion_laboratorio.container_id

    # Hacer copia de seguridad si está configurado
    backup_environment(sesion_laboratorio) if sesion_laboratorio.backup_enabled

    # Detener y eliminar contenedor
    `docker stop #{sesion_laboratorio.container_id} 2>&1`
    result = `docker rm #{sesion_laboratorio.container_id} 2>&1`
    success = $?.success?

    if success
      Rails.logger.info("Contenedor #{sesion_laboratorio.container_id} eliminado exitosamente")
      # Limpiar ID del contenedor
      sesion_laboratorio.update(container_id: nil)
      true
    else
      Rails.logger.error("Error al eliminar contenedor #{sesion_laboratorio.container_id}: #{result}")
      false
    end
  end

  # Obtener métricas del contenedor
  def self.get_metrics(sesion_laboratorio)
    return {} unless sesion_laboratorio.container_id

    # Obtener estadísticas de CPU, memoria y red
    stats = `docker stats #{sesion_laboratorio.container_id} --no-stream --format "{{.CPUPerc}},{{.MemPerc}},{{.NetIO}}"`
    return {} if stats.blank?

    cpu, mem, net = stats.strip.split(',')
    received, sent = net.split('/').map(&:strip)

    # Normalizar valores
    {
      cpu_usage: cpu.gsub('%', '').to_f,
      memory_usage: mem.gsub('%', '').to_f,
      network_received: normalize_size(received),
      network_sent: normalize_size(sent),
      timestamp: Time.current
    }
  end

  # Realizar copia de seguridad del entorno
  def self.backup_environment(sesion_laboratorio)
    return unless sesion_laboratorio.container_id

    backup_path = Rails.root.join('storage', 'backups',
                                  "lab_#{sesion_laboratorio.id}_#{Time.current.strftime('%Y%m%d%H%M%S')}")
    FileUtils.mkdir_p(backup_path)

    # Copiar datos del volumen
    `docker cp #{sesion_laboratorio.container_id}:/home/kali/data #{backup_path}`

    # Guardar metadata
    File.write(
      "#{backup_path}/metadata.json",
      {
        sesion_id: sesion_laboratorio.id,
        usuario_id: sesion_laboratorio.usuario_id,
        laboratorio_id: sesion_laboratorio.laboratorio_id,
        tipo: sesion_laboratorio.laboratorio.tipo,
        fecha_backup: Time.current,
        container_id: sesion_laboratorio.container_id
      }.to_json
    )

    sesion_laboratorio.update(last_backup_at: Time.current)

    true
  end

  # Ejecutar comando en el entorno y verificar objetivos
  def self.execute_command(sesion_laboratorio, command, verificar_objetivo: true)
    return { success: false, output: 'Contenedor no disponible' } unless sesion_laboratorio.container_id

    # Sanitizar comando
    sanitized_command = sanitize_command(command)

    # Ejecutar comando en el contenedor
    output = `docker exec #{sesion_laboratorio.container_id} /bin/bash -c "#{sanitized_command}" 2>&1`
    success = $?.success?

    # Registrar comando en el historial
    LogTerminal.create!(
      sesion_laboratorio: sesion_laboratorio,
      usuario: sesion_laboratorio.usuario,
      contenido: sanitized_command,
      tipo: 'comando'
    )

    # Registrar salida en el historial
    LogTerminal.create!(
      sesion_laboratorio: sesion_laboratorio,
      usuario: sesion_laboratorio.usuario,
      contenido: output,
      tipo: success ? 'resultado' : 'error'
    )

    # Verificar objetivos si está habilitado
    verificar_objetivos(sesion_laboratorio, sanitized_command, output) if verificar_objetivo && success

    { success: success, output: output }
  end

  private

  def self.data_volume_path(sesion_laboratorio)
    "#{Rails.root}/storage/lab_data/#{sesion_laboratorio.id}"
  end

  def self.initialize_tools(container_name, tools)
    # Asegurar que todas las herramientas estén disponibles
    tool_installation = tools.join(' ')
    `docker exec #{container_name} /bin/bash -c "apt-get update && apt-get install -y #{tool_installation}"`
  end

  def self.setup_monitoring(container_name, session_id)
    # Iniciar monitoreo en segundo plano
    MonitorMetricsJob.perform_later(session_id)
  end

  def self.sanitize_command(command)
    # Sanitizar comando para evitar inyecciones
    command.gsub(/[&;|><$]/, '')
  end

  def self.normalize_size(size_str)
    # Convertir tamaños como "10.5MB" a bytes
    if size_str =~ /(\d+(\.\d+)?)([KMGT]?B)/
      value = ::Regexp.last_match(1).to_f
      unit = ::Regexp.last_match(3)

      case unit
      when 'KB'
        value * 1024
      when 'MB'
        value * 1024 * 1024
      when 'GB'
        value * 1024 * 1024 * 1024
      when 'TB'
        value * 1024 * 1024 * 1024 * 1024
      else
        value
      end
    else
      0
    end
  end

  def self.verificar_objetivos(sesion_laboratorio, command, output)
    # Buscar ejercicios del laboratorio actual
    ejercicios = sesion_laboratorio.laboratorio.ejercicios.where(activo: true)

    ejercicios.each do |ejercicio|
      # Delegar verificación al servicio especializado
      EjercicioVerificationService.verificar(ejercicio, sesion_laboratorio, command, output)
    end
  end
end
