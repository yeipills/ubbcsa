# app/services/ejercicio_verification_service.rb
class EjercicioVerificationService
  class VerificationError < StandardError; end

  # Verifica si un comando cumple con los requisitos de un ejercicio
  def self.verificar(ejercicio, sesion_laboratorio, comando, output = nil)
    # Obtener output del comando si no fue proporcionado
    if output.nil? && sesion_laboratorio.container_id.present?
      output = `docker exec #{sesion_laboratorio.container_id} /bin/bash -c "#{comando}" 2>&1`
    end

    # Determinar el verificador según el tipo de ejercicio
    resultado = case ejercicio.tipo
                when 'escaneo_red'
                  verificar_escaneo(comando, output, ejercicio.parametros)
                when 'fuerza_bruta'
                  verificar_fuerza_bruta(comando, output, ejercicio.parametros)
                when 'analisis_trafico'
                  verificar_analisis_trafico(comando, output, ejercicio.parametros)
                when 'ataque_dos'
                  verificar_dos(comando, output, ejercicio.parametros)
                when 'exploit'
                  verificar_exploit(comando, output, ejercicio.parametros)
                when 'web'
                  verificar_web(comando, output, ejercicio.parametros)
                when 'forense'
                  verificar_forense(comando, output, ejercicio.parametros)
                when 'script'
                  verificar_script(comando, output, ejercicio.parametros)
                else
                  raise VerificationError, "Tipo de ejercicio no reconocido: #{ejercicio.tipo}"
                end

    # Registrar intento y comprobar si cumple los objetivos
    registrar_intento(ejercicio, sesion_laboratorio, comando, resultado)

    # Verificar si todos los objetivos del ejercicio están cumplidos
    check_all_objectives_completed(ejercicio, sesion_laboratorio)

    resultado
  rescue VerificationError => e
    { success: false, message: e.message }
  rescue StandardError => e
    Rails.logger.error("Error verificando ejercicio #{ejercicio.id}: #{e.message}")
    { success: false, message: "Error en verificación: #{e.message}" }
  end

  private

  # Verificación para escaneo de redes
  def self.verificar_escaneo(comando, output, parametros)
    if comando.start_with?('nmap')
      validar_parametros_nmap(comando, output, parametros)
    elsif comando.start_with?('netdiscover')
      validar_parametros_netdiscover(comando, output, parametros)
    elsif comando.include?('tcpdump')
      validar_parametros_tcpdump(comando, output, parametros)
    else
      raise VerificationError, 'Comando de escaneo no válido. Prueba con nmap, netdiscover o tcpdump.'
    end
  end

  # Verificación para ataques de fuerza bruta
  def self.verificar_fuerza_bruta(comando, output, parametros)
    if comando.start_with?('hydra')
      validar_ataque_hydra(comando, output, parametros)
    elsif comando.start_with?('medusa')
      validar_ataque_medusa(comando, output, parametros)
    elsif comando.start_with?('john')
      validar_john(comando, output, parametros)
    elsif comando.include?('hashcat')
      validar_hashcat(comando, output, parametros)
    else
      raise VerificationError, 'Herramienta de fuerza bruta no válida. Prueba con hydra, medusa, john, or hashcat.'
    end
  end

  # Verificación para análisis de tráfico
  def self.verificar_analisis_trafico(comando, output, parametros)
    if comando.include?('tcpdump')
      validar_tcpdump(comando, output, parametros)
    elsif comando.include?('tshark') || comando.include?('wireshark')
      validar_tshark(comando, output, parametros)
    elsif comando.include?('bettercap')
      validar_bettercap(comando, output, parametros)
    else
      raise VerificationError, 'Herramienta de análisis no válida. Prueba con tcpdump, tshark o bettercap.'
    end
  end

  # Verificación para ataques de denegación de servicio
  def self.verificar_dos(comando, output, parametros)
    if comando.include?('hping3')
      validar_hping3(comando, output, parametros)
    elsif comando.include?('slowloris')
      validar_slowloris(comando, output, parametros)
    else
      raise VerificationError, 'Herramienta de DoS no válida. Prueba con hping3 o slowloris.'
    end
  end

  # Verificación para explotación de vulnerabilidades
  def self.verificar_exploit(comando, output, parametros)
    if comando.include?('msfconsole') || comando.include?('msfvenom')
      validar_metasploit(comando, output, parametros)
    elsif comando.include?('searchsploit')
      validar_searchsploit(comando, output, parametros)
    elsif comando.include?('sqlmap')
      validar_sqlmap(comando, output, parametros)
    else
      raise VerificationError, 'Herramienta de exploit no válida. Prueba con metasploit, searchsploit o sqlmap.'
    end
  end

  # Verificación para análisis web
  def self.verificar_web(comando, output, parametros)
    if comando.include?('sqlmap')
      validar_sqlmap(comando, output, parametros)
    elsif comando.include?('nikto')
      validar_nikto(comando, output, parametros)
    elsif comando.include?('dirb') || comando.include?('gobuster')
      validar_directory_brute(comando, output, parametros)
    elsif comando.include?('curl') || comando.include?('wget')
      validar_web_request(comando, output, parametros)
    else
      raise VerificationError, 'Herramienta web no válida. Prueba con sqlmap, nikto, dirb, gobuster, curl o wget.'
    end
  end

  # Verificación para análisis forense
  def self.verificar_forense(comando, output, parametros)
    if comando.include?('strings')
      validar_strings_forense(comando, output, parametros)
    elsif comando.include?('binwalk')
      validar_binwalk(comando, output, parametros)
    elsif comando.include?('volatility')
      validar_volatility(comando, output, parametros)
    elsif comando.include?('exiftool')
      validar_exiftool(comando, output, parametros)
    else
      raise VerificationError, 'Herramienta forense no válida. Prueba con strings, binwalk, volatility o exiftool.'
    end
  end

  # Verificación para scripts
  def self.verificar_script(comando, output, parametros)
    if comando.include?('python') || comando.include?('python3')
      validar_python_script(comando, output, parametros)
    elsif comando.include?('bash') || comando.end_with?('.sh')
      validar_bash_script(comando, output, parametros)
    else
      raise VerificationError, 'Script no válido. Prueba con Python o Bash.'
    end
  end

  # Validaciones específicas para cada herramienta
  def self.validar_parametros_nmap(comando, output, parametros)
    target = parametros['target_ip'] || parametros['target']
    required_flags = parametros['required_flags'] || []
    expected_ports = parametros['expected_ports'] || []

    # Verificar que se está escaneando el objetivo correcto
    raise VerificationError, "IP objetivo incorrecta. Debes escanear: #{target}" unless comando.include?(target)

    # Verificar flags requeridos
    required_flags.each do |flag|
      raise VerificationError, "Falta el parámetro requerido: #{flag}" unless comando.include?(flag)
    end

    # Verificar que se encontraron los puertos esperados si hay salida
    if output.present? && expected_ports.any?
      found_all_ports = expected_ports.all? { |port| output.include?("#{port}/") }
      unless found_all_ports
        raise VerificationError, 'No se detectaron todos los puertos esperados. Verifica tu escaneo.'
      end
    end

    { success: true, message: 'Escaneo configurado correctamente', details: { target: target } }
  end

  def self.validar_ataque_hydra(comando, output, parametros)
    target = parametros['target'] || parametros['ip']
    service = parametros['service']
    wordlist = parametros['wordlist']
    username = parametros['username']

    # Verificar parámetros básicos
    raise VerificationError, "Objetivo incorrecto. Debes atacar: #{target}" unless comando.include?(target)

    unless comando.include?(service)
      raise VerificationError, "Servicio incorrecto. Debes atacar el servicio: #{service}"
    end

    raise VerificationError, "Wordlist incorrecta. Debes usar: #{wordlist}" unless comando.include?(wordlist)

    # Verificar que se especificó el usuario si es necesario
    if username.present? && !comando.include?(username)
      raise VerificationError, "Usuario incorrecto. Debes intentar con el usuario: #{username}"
    end

    # Verificar si se encontró la contraseña en la salida
    if output.present? && parametros['password'].present? && output.include?("password: #{parametros['password']}")
      # Premio adicional por encontrar la contraseña
      return {
        success: true,
        message: '¡Excelente! Has encontrado la contraseña correcta',
        details: { password_found: true }
      }
    end

    { success: true, message: 'Ataque de fuerza bruta configurado correctamente' }
  end

  def self.validar_tcpdump(comando, output, parametros)
    interface = parametros['interface']
    filter = parametros['filter']
    protocol = parametros['protocol']

    # Verificar interfaz
    if interface.present? && !comando.include?("-i #{interface}")
      raise VerificationError, "Interfaz de red incorrecta. Debes usar: -i #{interface}"
    end

    # Verificar filtro si existe
    if filter.present? && !comando.include?(filter)
      raise VerificationError, "Filtro de captura incorrecto. Debes incluir: #{filter}"
    end

    # Verificar protocolo si existe
    if protocol.present? && !comando.include?(protocol)
      raise VerificationError, "Protocolo incorrecto. Debes capturar tráfico: #{protocol}"
    end

    { success: true, message: 'Captura de tráfico configurada correctamente' }
  end

  def self.validar_hping3(comando, output, parametros)
    target = parametros['target']
    attack_type = parametros['attack_type']

    # Verificar objetivo
    unless comando.include?(target)
      raise VerificationError, "Objetivo no especificado correctamente. Debes atacar: #{target}"
    end

    # Verificar tipo de ataque
    case attack_type
    when 'syn_flood'
      unless comando.include?('--flood') && comando.include?('-S')
        raise VerificationError, 'Configuración incorrecta para SYN flood. Debes usar --flood y -S'
      end
    when 'udp_flood'
      unless comando.include?('--flood') && comando.include?('-2')
        raise VerificationError, 'Configuración incorrecta para UDP flood. Debes usar --flood y -2'
      end
    when 'icmp_flood'
      unless comando.include?('--flood') && comando.include?('-1')
        raise VerificationError, 'Configuración incorrecta para ICMP flood. Debes usar --flood y -1'
      end
    end

    { success: true, message: 'Prueba DoS configurada correctamente' }
  end

  # Validación de Metasploit
  def self.validar_metasploit(comando, output, parametros)
    exploit = parametros['exploit']
    payload = parametros['payload']
    target = parametros['target']

    # Verificar si se está usando el exploit correcto
    if exploit.present? && !comando.include?(exploit) && !output.include?(exploit)
      raise VerificationError, "Exploit incorrecto. Debes usar: #{exploit}"
    end

    # Verificar payload
    if payload.present? && !comando.include?(payload) && !output.include?(payload)
      raise VerificationError, "Payload incorrecto. Debes usar: #{payload}"
    end

    # Verificar objetivo
    if target.present? && !comando.include?(target) && !output.include?(target)
      raise VerificationError, "Objetivo incorrecto. Debes atacar: #{target}"
    end

    # Verificar si se consiguió una sesión
    if output.present? && output.include?('Meterpreter session') && parametros['require_session']
      return {
        success: true,
        message: '¡Excelente! Has obtenido una sesión de Meterpreter',
        details: { session_established: true }
      }
    end

    { success: true, message: 'Configuración de Metasploit correcta' }
  end

  # Validación de scripts Python
  def self.validar_python_script(comando, output, parametros)
    required_modules = parametros['required_modules'] || []
    target = parametros['target']
    required_output = parametros['required_output']

    # Verificar módulos requeridos en el comando o salida
    if required_modules.any?
      found_modules = required_modules.all? do |mod|
        comando.include?(mod) || (output.present? && output.include?(mod))
      end

      unless found_modules
        raise VerificationError, "El script debe usar los siguientes módulos: #{required_modules.join(', ')}"
      end
    end

    # Verificar objetivo
    if target.present? && !comando.include?(target) && !output.include?(target)
      raise VerificationError, "Objetivo incorrecto. Debes usar: #{target}"
    end

    # Verificar salida esperada
    if required_output.present? && output.present? && !output.include?(required_output)
      raise VerificationError, 'La salida del script no contiene la información esperada'
    end

    { success: true, message: 'Script Python ejecutado correctamente' }
  end

  # Registro de intento
  def self.registrar_intento(ejercicio, sesion_laboratorio, comando, resultado)
    IntentoEjercicio.create!(
      ejercicio: ejercicio,
      sesion_laboratorio: sesion_laboratorio,
      comando_ejecutado: comando,
      resultado: resultado[:success],
      mensaje: resultado[:message],
      detalles: resultado[:details],
      timestamp: Time.current
    )
  end

  # Verificar si se han completado todos los objetivos
  def self.check_all_objectives_completed(ejercicio, sesion_laboratorio)
    # Obtener todos los intentos exitosos
    intentos_exitosos = IntentoEjercicio.where(
      ejercicio: ejercicio,
      sesion_laboratorio: sesion_laboratorio,
      resultado: true
    )

    # Verificar si se requieren múltiples objetivos
    objetivos_requeridos = ejercicio.parametros['required_objectives'].to_i
    objetivos_requeridos = 1 if objetivos_requeridos < 1

    return unless intentos_exitosos.count >= objetivos_requeridos

    # Marcar ejercicio como completado
    EjercicioCompletado.find_or_create_by(
      ejercicio: ejercicio,
      sesion_laboratorio: sesion_laboratorio,
      usuario: sesion_laboratorio.usuario
    )

    # Notificar al usuario
    ActionCable.server.broadcast(
      "laboratorio_#{sesion_laboratorio.id}",
      {
        type: 'objective_completed',
        ejercicio_id: ejercicio.id,
        title: ejercicio.titulo,
        message: "¡Objetivo completado: #{ejercicio.titulo}!"
      }
    )

    # Verificar si se han completado todos los ejercicios del laboratorio
    check_laboratorio_completed(sesion_laboratorio)
  end

  # Verificar si se ha completado el laboratorio
  def self.check_laboratorio_completed(sesion_laboratorio)
    laboratorio = sesion_laboratorio.laboratorio
    total_ejercicios = laboratorio.ejercicios.activos.count

    ejercicios_completados = EjercicioCompletado.where(
      ejercicio: laboratorio.ejercicios,
      sesion_laboratorio: sesion_laboratorio
    ).select(:ejercicio_id).distinct.count

    return unless ejercicios_completados >= total_ejercicios && total_ejercicios > 0

    # Marcar laboratorio como completado
    sesion_laboratorio.update(
      estado: 'completada',
      tiempo_fin: Time.current,
      completado: true
    )

    # Notificar al usuario
    ActionCable.server.broadcast(
      "laboratorio_#{sesion_laboratorio.id}",
      {
        type: 'laboratorio_completed',
        message: "¡Felicidades! Has completado todos los objetivos del laboratorio: #{laboratorio.nombre}"
      }
    )

    # Crear logro para el usuario
    Logro.create_for_completion(sesion_laboratorio.usuario, laboratorio)
  end
end
