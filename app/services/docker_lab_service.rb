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
    },
    # Nuevos tipos de entorno para escenarios de defensa/ataque
    atacante: {
      image: 'kali-pentesting:latest',
      tools: %w[nmap metasploit-framework hydra john sqlmap],
      network: 'lab-network',
      resource_limits: { cpu: 2, memory: '2g' },
      targets: ['metasploitable', 'dvwa', 'webgoat']
    },
    defensor: {
      image: 'debian-security:latest',
      tools: %w[snort fail2ban iptables wazuh-agent],
      network: 'lab-network',
      resource_limits: { cpu: 1, memory: '1.5g' },
      targets: []
    },
    # Nuevos escenarios para CTF (Capture The Flag)
    ctf_ofensivo: {
      image: 'kali-ctf:latest',
      tools: %w[nmap dirbuster gobuster burpsuite hydra hashcat enum4linux],
      network: 'ctf-network',
      resource_limits: { cpu: 2, memory: '2g' },
      targets: ['ctf-target']
    },
    # Escenario red
    red_corporativa: {
      image: 'network-lab:latest',
      tools: %w[nmap tcpdump wireshark traceroute],
      network: 'corp-network',
      resource_limits: { cpu: 1, memory: '1g' },
      targets: ['router', 'firewall', 'server', 'client']
    }
  }
  
  # Configuraciones de máquinas objetivo
  TARGET_CONFIGS = {
    # Máquinas vulnerables
    metasploitable: {
      image: 'metasploitable:latest',
      description: 'Máquina Linux con múltiples vulnerabilidades',
      difficulty: 'intermedio',
      services: ['ssh', 'ftp', 'http', 'smb'],
      flags: 3
    },
    dvwa: {
      image: 'dvwa:latest',
      description: 'Aplicación web con vulnerabilidades deliberadas',
      difficulty: 'fácil',
      services: ['http', 'php', 'mysql'],
      flags: 5
    },
    webgoat: {
      image: 'webgoat:latest',
      description: 'Aplicación Java vulnerable para aprender seguridad web',
      difficulty: 'intermedio',
      services: ['http', 'java'],
      flags: 10
    },
    # Máquinas para defensa
    secure_ubuntu: {
      image: 'ubuntu-hardened:latest',
      description: 'Ubuntu con configuración robusta para defensa',
      difficulty: 'avanzado',
      services: ['ssh', 'http', 'mysql'],
      attack_vectors: ['bruteforce', 'sqli', 'rce']
    },
    windows_server: {
      image: 'windows-server:latest',
      description: 'Windows Server para prácticas de defensa',
      difficulty: 'avanzado',
      services: ['rdp', 'smb', 'iis'],
      attack_vectors: ['credentials', 'privilege-escalation', 'lateral-movement']
    },
    # Infraestructura de red
    router: {
      image: 'router-sim:latest',
      description: 'Simulador de router para configuración de red',
      network_role: 'gateway'
    },
    firewall: {
      image: 'pfsense:latest',
      description: 'Firewall para prácticas de seguridad perimetral',
      network_role: 'security'
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
      
      # Si este entorno tiene objetivos definidos, desplegarlos también
      if config[:targets].present?
        create_target_containers(sesion_laboratorio, config[:targets])
      end
      
      setup_monitoring(container_name, sesion_laboratorio.id)
      true
    else
      Rails.logger.error("Error al crear contenedor para sesión #{sesion_laboratorio.id}: #{result}")
      false
    end
  end
  
  # Crear contenedores objetivo para escenarios de ataque/defensa
  def self.create_target_containers(sesion_laboratorio, targets)
    targets.each do |target_name|
      target_config = TARGET_CONFIGS[target_name.to_sym]
      next unless target_config
      
      target_container_name = "target-#{target_name}-#{sesion_laboratorio.id}-#{SecureRandom.hex(4)}"
      
      # Construir el comando Docker para el contenedor objetivo
      cmd = [
        'docker run -d',
        "--name #{target_container_name}",
        "--cpus=1",
        "--memory=1g",
        "--network=#{ENVIRONMENT_CONFIGS[sesion_laboratorio.laboratorio.tipo.to_sym][:network]}",
        "-e TARGET_FOR=#{sesion_laboratorio.id}",
        "#{target_config[:image]}"
      ].join(' ')
      
      # Ejecutar comando
      result = `#{cmd} 2>&1`
      success = $?.success?
      
      if success
        Rails.logger.info("Objetivo #{target_name} (#{target_container_name}) desplegado para sesión #{sesion_laboratorio.id}")
        
        # Guardar la información del contenedor objetivo en la sesión
        existing_resources = sesion_laboratorio.resource_usage || {}
        targets_info = existing_resources['targets'] || {}
        
        targets_info[target_name] = {
          container_id: target_container_name,
          ip_address: get_container_ip(target_container_name),
          description: target_config[:description],
          services: target_config[:services],
          difficulty: target_config[:difficulty]
        }
        
        existing_resources['targets'] = targets_info
        sesion_laboratorio.update(resource_usage: existing_resources)
      else
        Rails.logger.error("Error al crear objetivo #{target_name} para sesión #{sesion_laboratorio.id}: #{result}")
      end
    end
  end

  # Pausar el entorno (sin destruirlo)
  def self.pause_environment(sesion_laboratorio)
    return true unless sesion_laboratorio.container_id

    result = `docker pause #{sesion_laboratorio.container_id} 2>&1`
    success = $?.success?

    if success
      Rails.logger.info("Contenedor #{sesion_laboratorio.container_id} pausado exitosamente")
      
      # También pausar los contenedores objetivo
      pause_target_containers(sesion_laboratorio)
      
      true
    else
      Rails.logger.error("Error al pausar contenedor #{sesion_laboratorio.container_id}: #{result}")
      false
    end
  end
  
  # Pausar contenedores objetivo
  def self.pause_target_containers(sesion_laboratorio)
    return unless sesion_laboratorio.resource_usage.is_a?(Hash) && sesion_laboratorio.resource_usage['targets'].is_a?(Hash)
    
    sesion_laboratorio.resource_usage['targets'].each do |_name, info|
      next unless info['container_id'].present?
      
      result = `docker pause #{info['container_id']} 2>&1`
      success = $?.success?
      
      if success
        Rails.logger.info("Contenedor objetivo #{info['container_id']} pausado exitosamente")
      else
        Rails.logger.error("Error al pausar contenedor objetivo #{info['container_id']}: #{result}")
      end
    end
  end

  # Reanudar entorno pausado
  def self.resume_environment(sesion_laboratorio)
    return true unless sesion_laboratorio.container_id

    result = `docker unpause #{sesion_laboratorio.container_id} 2>&1`
    success = $?.success?

    if success
      Rails.logger.info("Contenedor #{sesion_laboratorio.container_id} reanudado exitosamente")
      
      # También reanudar los contenedores objetivo
      resume_target_containers(sesion_laboratorio)
      
      true
    else
      Rails.logger.error("Error al reanudar contenedor #{sesion_laboratorio.container_id}: #{result}")
      false
    end
  end
  
  # Reanudar contenedores objetivo
  def self.resume_target_containers(sesion_laboratorio)
    return unless sesion_laboratorio.resource_usage.is_a?(Hash) && sesion_laboratorio.resource_usage['targets'].is_a?(Hash)
    
    sesion_laboratorio.resource_usage['targets'].each do |_name, info|
      next unless info['container_id'].present?
      
      result = `docker unpause #{info['container_id']} 2>&1`
      success = $?.success?
      
      if success
        Rails.logger.info("Contenedor objetivo #{info['container_id']} reanudado exitosamente")
      else
        Rails.logger.error("Error al reanudar contenedor objetivo #{info['container_id']}: #{result}")
      end
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

    # Destruir objetivos primero
    destroy_target_containers(sesion_laboratorio)
    
    # Detener y eliminar contenedor principal
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
  
  # Destruir contenedores objetivo
  def self.destroy_target_containers(sesion_laboratorio)
    return unless sesion_laboratorio.resource_usage.is_a?(Hash) && sesion_laboratorio.resource_usage['targets'].is_a?(Hash)
    
    sesion_laboratorio.resource_usage['targets'].each do |_name, info|
      next unless info['container_id'].present?
      
      `docker stop #{info['container_id']} 2>&1`
      result = `docker rm #{info['container_id']} 2>&1`
      success = $?.success?
      
      if success
        Rails.logger.info("Contenedor objetivo #{info['container_id']} eliminado exitosamente")
      else
        Rails.logger.error("Error al eliminar contenedor objetivo #{info['container_id']}: #{result}")
      end
    end
    
    # Limpiar información de objetivos
    resource_info = sesion_laboratorio.resource_usage || {}
    resource_info.delete('targets')
    sesion_laboratorio.update(resource_usage: resource_info)
  end

  # Obtener métricas del contenedor
  def self.get_metrics(sesion_laboratorio)
    return {} unless sesion_laboratorio.container_id

    # Obtener estadísticas de CPU, memoria y red
    stats = `docker stats #{sesion_laboratorio.container_id} --no-stream --format "{{.CPUPerc}},{{.MemPerc}},{{.NetIO}}"`
    return {} if stats.blank?

    cpu, mem, net = stats.strip.split(',')
    received, sent = net.split('/').map(&:strip)

    # Obtener información de objetivos
    target_metrics = get_target_metrics(sesion_laboratorio)

    # Normalizar valores
    {
      cpu_usage: cpu.gsub('%', '').to_f,
      memory_usage: mem.gsub('%', '').to_f,
      network_received: normalize_size(received),
      network_sent: normalize_size(sent),
      targets: target_metrics,
      timestamp: Time.current
    }
  end
  
  # Obtener métricas de los contenedores objetivo
  def self.get_target_metrics(sesion_laboratorio)
    return {} unless sesion_laboratorio.resource_usage.is_a?(Hash) && sesion_laboratorio.resource_usage['targets'].is_a?(Hash)
    
    target_metrics = {}
    
    sesion_laboratorio.resource_usage['targets'].each do |name, info|
      next unless info['container_id'].present?
      
      stats = `docker stats #{info['container_id']} --no-stream --format "{{.CPUPerc}},{{.MemPerc}},{{.NetIO}}"`
      next if stats.blank?
      
      cpu, mem, net = stats.strip.split(',')
      received, sent = net.split('/').map(&:strip)
      
      # Verificar si el contenedor está en ejecución
      status = `docker inspect --format='{{.State.Status}}' #{info['container_id']} 2>/dev/null`.strip
      
      target_metrics[name] = {
        cpu_usage: cpu.gsub('%', '').to_f,
        memory_usage: mem.gsub('%', '').to_f,
        network_received: normalize_size(received),
        network_sent: normalize_size(sent),
        status: status,
        ip_address: info['ip_address'] || get_container_ip(info['container_id'])
      }
    end
    
    target_metrics
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
  
  # Ejecutar comando en un contenedor objetivo
  def self.execute_command_on_target(sesion_laboratorio, target_name, command)
    return { success: false, output: 'Objetivo no disponible' } unless sesion_laboratorio.resource_usage.is_a?(Hash) && 
                                                                      sesion_laboratorio.resource_usage['targets'].is_a?(Hash) &&
                                                                      sesion_laboratorio.resource_usage['targets'][target_name].present?
    
    container_id = sesion_laboratorio.resource_usage['targets'][target_name]['container_id']
    return { success: false, output: 'Contenedor objetivo no disponible' } unless container_id.present?
    
    # Sanitizar comando
    sanitized_command = sanitize_command(command)
    
    # Ejecutar comando en el contenedor objetivo
    output = `docker exec #{container_id} /bin/bash -c "#{sanitized_command}" 2>&1`
    success = $?.success?
    
    # Registrar comando en el historial
    LogTerminal.create!(
      sesion_laboratorio: sesion_laboratorio,
      usuario: sesion_laboratorio.usuario,
      contenido: "[@#{target_name}] #{sanitized_command}",
      tipo: 'comando_objetivo'
    )
    
    # Registrar salida en el historial
    LogTerminal.create!(
      sesion_laboratorio: sesion_laboratorio,
      usuario: sesion_laboratorio.usuario,
      contenido: output,
      tipo: success ? 'resultado_objetivo' : 'error_objetivo'
    )
    
    { success: success, output: output }
  end
  
  # Listar objetivos disponibles para una sesión
  def self.list_targets(sesion_laboratorio)
    return [] unless sesion_laboratorio.resource_usage.is_a?(Hash) && 
                     sesion_laboratorio.resource_usage['targets'].is_a?(Hash)
    
    sesion_laboratorio.resource_usage['targets'].map do |name, info|
      {
        name: name,
        description: info['description'],
        ip_address: info['ip_address'] || 'No disponible',
        services: info['services'] || [],
        difficulty: info['difficulty'] || 'normal',
        status: get_container_status(info['container_id'])
      }
    end
  end
  
  # Crear un objetivo específico para una sesión
  def self.create_custom_target(sesion_laboratorio, target_type)
    return false unless TARGET_CONFIGS[target_type.to_sym].present?
    create_target_containers(sesion_laboratorio, [target_type])
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
  
  def self.get_container_ip(container_id)
    # Obtener la dirección IP del contenedor
    ip = `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' #{container_id} 2>/dev/null`.strip
    ip.present? ? ip : nil
  end
  
  def self.get_container_status(container_id)
    # Obtener el estado del contenedor
    status = `docker inspect --format='{{.State.Status}}' #{container_id} 2>/dev/null`.strip
    status.present? ? status : 'unknown'
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