# app/mailers/notificacion_mailer.rb
class NotificacionMailer < ApplicationMailer
  default from: 'notificaciones@ubbcsa.cl'

  # Enviar una notificación individual
  def enviar_notificacion(notificacion)
    @notificacion = notificacion
    @usuario = notificacion.usuario

    # Personalizar según el tipo de notificación
    subject = case notificacion.tipo
              when 'quiz'
                "UBB CSA: Quiz - #{notificacion.titulo}"
              when 'curso'
                "UBB CSA: Curso - #{notificacion.titulo}"
              when 'sistema'
                "UBB CSA: Sistema - #{notificacion.titulo}"
              when 'alerta_seguridad'
                "UBB CSA: ⚠️ ALERTA - #{notificacion.titulo}"
              else
                "UBB CSA: #{notificacion.titulo}"
              end

    mail(
      to: @usuario.email,
      subject: subject
    )
  end

  # Enviar notificación de nuevo mensaje
  def nuevo_mensaje(notificacion)
    @notificacion = notificacion
    @usuario = notificacion.usuario
    @remitente = notificacion.actor
    @mensaje = notificacion.notificable

    mail(
      to: @usuario.email,
      subject: "UBB CSA: Nuevo mensaje de #{@remitente&.nombre_completo || 'Sistema'}"
    )
  end

  # Enviar resumen de notificaciones
  def resumen_notificaciones(usuario:, notificaciones:, por_tipo:, periodo_texto:)
    @usuario = usuario
    @notificaciones = notificaciones
    @por_tipo = por_tipo
    @periodo_texto = periodo_texto
    @fecha = Date.current

    mail(
      to: @usuario.email,
      subject: "UBB CSA: Resumen #{periodo_texto} de actividad - #{@fecha.strftime('%d/%m/%Y')}"
    )
  end

  # Notificar resultado de quiz
  def resultado_quiz(intento_quiz)
    @intento = intento_quiz
    @usuario = intento_quiz.usuario
    @quiz = intento_quiz.quiz

    mail(
      to: @usuario.email,
      subject: "UBB CSA: Resultados del quiz #{@quiz.titulo}"
    )
  end

  # Notificar nuevo quiz disponible
  def quiz_disponible(quiz, usuario)
    @quiz = quiz
    @usuario = usuario
    @curso = quiz.curso

    mail(
      to: @usuario.email,
      subject: "UBB CSA: Nuevo quiz disponible - #{@quiz.titulo}"
    )
  end

  # Notificar alerta de seguridad
  def alerta_seguridad(alerta)
    @alerta = alerta
    @usuario = alerta.usuario
    @sesion = alerta.sesion_laboratorio

    mail(
      to: @usuario.email,
      subject: "UBB CSA: ⚠️ ALERTA DE SEGURIDAD - #{@alerta.nivel.upcase}"
    )
  end

  # Notificar logro conseguido
  def logro_conseguido(logro)
    @logro = logro
    @usuario = logro.usuario

    mail(
      to: @usuario.email,
      subject: 'UBB CSA: ¡Felicidades! Has conseguido un nuevo logro'
    )
  end
end
