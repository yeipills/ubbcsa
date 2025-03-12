# app/models/preferencias_notificacion.rb
class PreferenciasNotificacion < ApplicationRecord
  belongs_to :usuario

  # Validaciones
  validates :usuario_id, uniqueness: true
  validates :hora_resumen, format: { with: /\A([01]?[0-9]|2[0-3]):[0-5][0-9]\z/, message: 'debe tener formato HH:MM' }

  # Callback para garantizar que cada usuario tiene preferencias
  after_create :set_default_preferences

  TIPOS_NOTIFICACIONES = %w[sistema laboratorio curso quiz logro ejercicio mensaje alerta_seguridad].freeze
  CANALES = %w[web email movil].freeze

  self.table_name = 'preferencias_notificaciones'

  # Verificar si un tipo de notificación está habilitado para un canal
  def habilitado?(tipo, canal)
    # Verificar primero si el canal general está habilitado
    canal_habilitado = case canal.to_s
                       when 'web'
                         web_habilitado
                       when 'email'
                         email_habilitado
                       when 'movil'
                         movil_habilitado
                       else
                         true
                       end

    return false unless canal_habilitado

    # Verificar la configuración específica para el tipo
    configuracion = configuracion_tipos[tipo.to_s]
    return false unless configuracion

    configuracion[canal.to_s] == true
  end

  # Actualizar la configuración de un tipo específico
  def actualizar_configuracion(tipo, web: nil, email: nil, movil: nil)
    config = configuracion_tipos[tipo.to_s] || {}

    config['web'] = web unless web.nil?
    config['email'] = email unless email.nil?
    config['movil'] = movil unless movil.nil?

    nueva_configuracion = configuracion_tipos.merge(tipo.to_s => config)
    update(configuracion_tipos: nueva_configuracion)
  end

  # Habilitar o deshabilitar todos los canales para un tipo
  def set_all_channels(tipo, valor)
    config = {
      'web' => valor,
      'email' => valor,
      'movil' => valor
    }

    nueva_configuracion = configuracion_tipos.merge(tipo.to_s => config)
    update(configuracion_tipos: nueva_configuracion)
  end

  # Habilitar o deshabilitar un canal para todos los tipos
  def set_channel_for_all_types(canal, valor)
    nueva_configuracion = {}

    TIPOS_NOTIFICACIONES.each do |tipo|
      config = configuracion_tipos[tipo] || { 'web' => true, 'email' => true, 'movil' => true }
      config[canal.to_s] = valor
      nueva_configuracion[tipo] = config
    end

    update(configuracion_tipos: nueva_configuracion)

    # Actualizar también el estado general del canal
    case canal.to_s
    when 'web'
      update(web_habilitado: valor)
    when 'email'
      update(email_habilitado: valor)
    when 'movil'
      update(movil_habilitado: valor)
    end
  end

  # Verificar si un usuario debería recibir un resumen hoy
  def recibir_resumen_hoy?
    return false unless email_habilitado

    current_day = Date.current.wday

    # Resumen diario: todos los días
    return true if resumen_diario

    # Resumen semanal: solo los lunes (wday = 1)
    return (current_day == 1) if resumen_semanal

    false
  end

  private

  # Establecer preferencias por defecto según el rol del usuario
  def set_default_preferences
    return unless usuario

    case usuario.rol
    when 'admin'
      update(
        email_habilitado: true,
        web_habilitado: true,
        movil_habilitado: true,
        resumen_diario: true,
        resumen_semanal: false
      )
    when 'profesor'
      update(
        email_habilitado: true,
        web_habilitado: true,
        movil_habilitado: true,
        resumen_diario: false,
        resumen_semanal: true
      )
    else # estudiante
      update(
        email_habilitado: true,
        web_habilitado: true,
        movil_habilitado: true,
        resumen_diario: false,
        resumen_semanal: true
      )
    end
  end
end
