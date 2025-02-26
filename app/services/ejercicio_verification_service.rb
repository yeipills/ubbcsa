# app/services/ejercicio_verification_service.rb
class EjercicioVerificationService
  class VerificationError < StandardError; end

  def self.verificar(ejercicio, sesion_laboratorio, comando)
    begin
      resultado = case ejercicio.tipo
      when 'escaneo_red'
        verificar_escaneo(comando, ejercicio.parametros)
      when 'fuerza_bruta'
        verificar_fuerza_bruta(comando, ejercicio.parametros)
      when 'analisis_trafico'
        verificar_analisis_trafico(comando, ejercicio.parametros)
      when 'ataque_dos'
        verificar_dos(comando, ejercicio.parametros)
      else
        raise VerificationError, "Tipo de ejercicio no reconocido"
      end

      registrar_intento(ejercicio, sesion_laboratorio, comando, resultado)
      resultado
    rescue VerificationError => e
      { success: false, message: e.message }
    end
  end

  private

  def self.verificar_escaneo(comando, parametros)
    # Verifica comandos de nmap y otros escáneres
    if comando.start_with?('nmap')
      validar_parametros_nmap(comando, parametros)
    elsif comando.start_with?('netdiscover')
      validar_parametros_netdiscover(comando, parametros)
    else
      raise VerificationError, "Comando de escaneo no válido"
    end
  end

  def self.verificar_fuerza_bruta(comando, parametros)
    # Verifica herramientas como hydra, medusa, etc.
    case
    when comando.start_with?('hydra')
      validar_ataque_hydra(comando, parametros)
    when comando.start_with?('medusa')
      validar_ataque_medusa(comando, parametros)
    when comando.start_with?('john')
      validar_john(comando, parametros)
    else
      raise VerificationError, "Herramienta de fuerza bruta no válida"
    end
  end

  def self.verificar_analisis_trafico(comando, parametros)
    # Verifica herramientas como wireshark, tcpdump
    case
    when comando.start_with?('tcpdump')
      validar_tcpdump(comando, parametros)
    when comando.start_with?('tshark')
      validar_tshark(comando, parametros)
    else
      raise VerificationError, "Herramienta de análisis no válida"
    end
  end

  def self.verificar_dos(comando, parametros)
    # Verifica herramientas de prueba de DoS
    if comando.start_with?('hping3')
      validar_hping3(comando, parametros)
    else
      raise VerificationError, "Herramienta DoS no válida"
    end
  end

  # Validaciones específicas para cada herramienta
  def self.validar_parametros_nmap(comando, parametros)
    target = parametros['target_ip']
    required_flags = parametros['required_flags']
    
    unless comando.include?(target)
      raise VerificationError, "IP objetivo incorrecta"
    end

    required_flags.each do |flag|
      unless comando.include?(flag)
        raise VerificationError, "Falta el parámetro requerido: #{flag}"
      end
    end

    { success: true, message: "Escaneo configurado correctamente" }
  end

  def self.validar_ataque_hydra(comando, parametros)
    required_params = ['target', 'service', 'wordlist']
    
    required_params.each do |param|
      unless comando.include?(parametros[param])
        raise VerificationError, "Falta el parámetro #{param}"
      end
    end

    { success: true, message: "Ataque de fuerza bruta configurado correctamente" }
  end

  def self.validar_tcpdump(comando, parametros)
    interface = parametros['interface']
    filter = parametros['filter']

    unless comando.include?("-i #{interface}")
      raise VerificationError, "Interface de red incorrecta"
    end

    unless comando.include?(filter)
      raise VerificationError, "Filtro de captura incorrecto"
    end

    { success: true, message: "Captura de tráfico configurada correctamente" }
  end

  def self.validar_hping3(comando, parametros)
    target = parametros['target']
    attack_type = parametros['attack_type']

    unless comando.include?(target)
      raise VerificationError, "Objetivo no especificado correctamente"
    end

    case attack_type
    when 'syn_flood'
      unless comando.include?('--flood') && comando.include?('-S')
        raise VerificationError, "Configuración incorrecta para SYN flood"
      end
    when 'udp_flood'
      unless comando.include?('--flood') && comando.include?('-2')
        raise VerificationError, "Configuración incorrecta para UDP flood"
      end
    end

    { success: true, message: "Prueba DoS configurada correctamente" }
  end

  def self.registrar_intento(ejercicio, sesion_laboratorio, comando, resultado)
    IntentoEjercicio.create!(
      ejercicio: ejercicio,
      sesion_laboratorio: sesion_laboratorio,
      comando_ejecutado: comando,
      resultado: resultado[:success],
      mensaje: resultado[:message],
      timestamp: Time.current
    )
  end
end