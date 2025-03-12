class NotificacionesService
  class << self
    # Crear y enviar una notificación
    def notificar(usuario, opciones = {})
      # Valores por defecto
      opciones = {
        tipo: :sistema,
        nivel: :informativa,
        titulo: 'Notificación',
        contenido: '',
        actor: nil,
        notificable: nil,
        datos_adicionales: {},
        accion_url: nil,
        icono: nil,
        canales: [:web]
      }.merge(opciones)

      # Verificar si el usuario tiene preferencias
      preferencias = PreferenciasNotificacion.find_or_create_by(usuario: usuario)

      # Crear la notificación
      notificacion = Notificacion.new(
        usuario: usuario,
        actor: opciones[:actor],
        notificable: opciones[:notificable],
        tipo: opciones[:tipo],
        nivel: opciones[:nivel],
        titulo: opciones[:titulo],
        contenido: opciones[:contenido],
        datos_adicionales: opciones[:datos_adicionales],
        accion_url: opciones[:accion_url],
        icono: opciones[:icono],
        mostrar_web: opciones[:canales].include?(:web),
        mostrar_email: opciones[:canales].include?(:email),
        mostrar_movil: opciones[:canales].include?(:movil)
      )

      # Aplicar preferencias del usuario
      apply_user_preferences(notificacion, preferencias)

      # Guardar la notificación
      return false unless notificacion.save

      # Enviar a través de los canales habilitados
      deliver_notification(notificacion, preferencias)

      notificacion
    end

    # Enviar notificación a múltiples usuarios
    def notificar_muchos(usuarios, opciones = {})
      usuarios.each do |usuario|
        notificar(usuario, opciones)
      end
    end

    # Enviar notificación a todos los administradores
    def notificar_admins(opciones = {})
      admins = Usuario.where(rol: 'admin')
      notificar_muchos(admins, opciones)
    end

    # Enviar notificación a todos los estudiantes de un curso
    def notificar_curso(curso, opciones = {})
      estudiantes = curso.estudiantes

      # Incluir el profesor del curso
      profesor = curso.profesor
      usuarios = estudiantes + [profesor]

      opciones[:notificable] = curso unless opciones[:notificable]
      opciones[:tipo] = :curso unless opciones[:tipo]

      notificar_muchos(usuarios, opciones)
    end

    # Marcar como leídas las notificaciones de un usuario
    def marcar_como_leidas(usuario, ids = nil)
      scope = usuario.notificaciones.no_leidas
      scope = scope.where(id: ids) if ids.present?

      scope.update_all(leida: true, leida_en: Time.current)
    end

    # Eliminar notificaciones antiguas
    def limpiar_notificaciones_antiguas(dias = 30)
      fecha_limite = dias.days.ago
      Notificacion.where('created_at < ?', fecha_limite).where(leida: true).delete_all
    end

    # Generar y enviar resúmenes diarios o semanales
    def enviar_resumenes
      # Buscar usuarios que deben recibir resumen hoy
      usuarios_con_resumen = Usuario.joins(:preferencias_notificacion)
                                    .where(preferencias_notificaciones: {
                                             email_habilitado: true
                                           })
                                    .select do |u|
                                      u.preferencias_notificacion.recibir_resumen_hoy?
                                    end

      usuarios_con_resumen.each do |usuario|
        generar_y_enviar_resumen(usuario)
      end
    end

    private

    # Aplicar preferencias del usuario a la notificación
    def apply_user_preferences(notificacion, preferencias)
      # Verificar cada canal según las preferencias
      notificacion.mostrar_web = preferencias.habilitado?(notificacion.tipo, 'web') if notificacion.mostrar_web

      notificacion.mostrar_email = preferencias.habilitado?(notificacion.tipo, 'email') if notificacion.mostrar_email

      return unless notificacion.mostrar_movil

      notificacion.mostrar_movil = preferencias.habilitado?(notificacion.tipo, 'movil')
    end

    # Entregar notificación a través de los canales habilitados
    def deliver_notification(notificacion, preferencias)
      # Notificación web en tiempo real
      deliver_web_notification(notificacion) if notificacion.mostrar_web && preferencias.web_habilitado

      # Notificación por email
      deliver_email_notification(notificacion) if notificacion.mostrar_email && preferencias.email_habilitado

      # Notificación móvil (si está configurado)
      return unless notificacion.mostrar_movil && preferencias.movil_habilitado

      deliver_mobile_notification(notificacion)
    end

    # Enviar notificación web en tiempo real
    def deliver_web_notification(notificacion)
      ActionCable.server.broadcast(
        "notificaciones_#{notificacion.usuario_id}",
        {
          id: notificacion.id,
          tipo: notificacion.tipo,
          nivel: notificacion.nivel,
          titulo: notificacion.titulo,
          contenido: notificacion.contenido,
          tiempo: notificacion.tiempo_transcurrido,
          icono: notificacion.icono,
          accion_url: notificacion.accion_url
        }
      )
    end

    # Enviar notificación por email
    def deliver_email_notification(notificacion)
      # Solo enviar email para notificaciones importantes o según configuración
      case notificacion.tipo
      when 'quiz', 'alerta_seguridad', 'curso'
        NotificacionMailer.enviar_notificacion(notificacion).deliver_later
      when 'sistema'
        NotificacionMailer.enviar_notificacion(notificacion).deliver_later
      when 'mensaje'
        NotificacionMailer.nuevo_mensaje(notificacion).deliver_later
      end
    end

    # Enviar notificación móvil
    def deliver_mobile_notification(notificacion)
      # Esta funcionalidad requeriría integración con servicios de notificaciones
      # push como Firebase Cloud Messaging, que queda fuera del alcance actual
      # pero se deja preparada la arquitectura para implementarlo en el futuro
    end

    # Generar y enviar resumen de notificaciones para un usuario
    def generar_y_enviar_resumen(usuario)
      preferencias = usuario.preferencias_notificacion

      # Determinar período para el resumen
      periodo = if preferencias.resumen_diario
                  1.day.ago
                else # resumen semanal
                  1.week.ago
                end

      # Obtener notificaciones recientes
      notificaciones = usuario.notificaciones
                              .where('created_at >= ?', periodo)
                              .order(created_at: :desc)

      # No enviar si no hay notificaciones
      return if notificaciones.empty?

      # Agrupar por tipo
      por_tipo = notificaciones.group_by(&:tipo)

      # Enviar email con resumen
      NotificacionMailer.resumen_notificaciones(
        usuario: usuario,
        notificaciones: notificaciones,
        por_tipo: por_tipo,
        periodo_texto: preferencias.resumen_diario ? 'diario' : 'semanal'
      ).deliver_later
    end
  end
end
