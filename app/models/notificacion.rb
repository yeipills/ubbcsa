# app/models/notificacion.rb
class Notificacion < ApplicationRecord
  belongs_to :usuario
  belongs_to :actor, class_name: 'Usuario', optional: true
  belongs_to :notificable, polymorphic: true, optional: true
  self.table_name = 'notificaciones'

  # Enumeraciones
  enum tipo: {
    sistema: 0,
    laboratorio: 1,
    curso: 2,
    quiz: 3,
    logro: 4,
    ejercicio: 5,
    mensaje: 6,
    alerta_seguridad: 7
  }

  enum nivel: {
    informativa: 0,
    exito: 1,
    advertencia: 2,
    error: 3
  }

  # Validaciones
  validates :titulo, :contenido, presence: true

  # Scopes
  scope :del_tipo, ->(tipo) { where(tipo: tipo) }
  scope :del_nivel, ->(nivel) { where(nivel: nivel) }
  scope :no_leidas, -> { where(leida: false) }
  scope :recientes, -> { order(created_at: :desc).limit(10) }

  # Métodos de instancia
  def marcar_como_leida!
    update(leida: true, leida_en: Time.current)
  end

  def marcar_como_no_leida!
    update(leida: false, leida_en: nil)
  end

  def tiempo_transcurrido
    # Formato legible del tiempo transcurrido desde la creación
    tiempo = (Time.current - created_at).to_i

    if tiempo < 60
      "hace #{tiempo} segundos"
    elsif tiempo < 3600
      "hace #{(tiempo / 60).to_i} minutos"
    elsif tiempo < 86_400
      "hace #{(tiempo / 3600).to_i} horas"
    elsif tiempo < 604_800
      "hace #{(tiempo / 86_400).to_i} días"
    elsif tiempo < 2_419_200
      "hace #{(tiempo / 604_800).to_i} semanas"
    elsif tiempo < 29_030_400
      "hace #{(tiempo / 2_419_200).to_i} meses"
    else
      "hace #{(tiempo / 29_030_400).to_i} años"
    end
  end

  # Métodos de clase para crear notificaciones específicas
  class << self
    # Notificación para laboratorio completado
    def laboratorio_completado(sesion_laboratorio)
      laboratorio = sesion_laboratorio.laboratorio
      usuario = sesion_laboratorio.usuario

      create!(
        usuario: usuario,
        notificable: laboratorio,
        tipo: :laboratorio,
        nivel: :exito,
        titulo: 'Laboratorio completado',
        contenido: "Has completado exitosamente el laboratorio '#{laboratorio.nombre}'",
        datos_adicionales: {
          laboratorio_id: laboratorio.id,
          curso_id: laboratorio.curso_id,
          tiempo_total: (sesion_laboratorio.tiempo_fin - sesion_laboratorio.tiempo_inicio).to_i
        }
      )
    end

    # Notificación para nuevo logro
    def nuevo_logro(logro)
      create!(
        usuario: logro.usuario,
        notificable: logro,
        tipo: :logro,
        nivel: :exito,
        titulo: '¡Nuevo logro conseguido!',
        contenido: logro.descripcion,
        datos_adicionales: {
          logro_id: logro.id,
          tipo_logro: logro.tipo
        }
      )
    end

    # Notificación para quiz disponible
    def quiz_disponible(quiz, usuario)
      create!(
        usuario: usuario,
        notificable: quiz,
        tipo: :quiz,
        nivel: :informativa,
        titulo: 'Nuevo quiz disponible',
        contenido: "El quiz '#{quiz.titulo}' ya está disponible en el curso '#{quiz.curso.nombre}'",
        datos_adicionales: {
          quiz_id: quiz.id,
          curso_id: quiz.curso_id,
          fecha_limite: quiz.fecha_fin
        }
      )
    end

    # Notificación para resultados de quiz
    def resultado_quiz(intento_quiz)
      quiz = intento_quiz.quiz

      create!(
        usuario: intento_quiz.usuario,
        notificable: intento_quiz,
        tipo: :quiz,
        nivel: :informativa,
        titulo: 'Resultados de quiz disponibles',
        contenido: "Los resultados del quiz '#{quiz.titulo}' están disponibles. Obtuviste #{intento_quiz.puntaje_total}%",
        datos_adicionales: {
          quiz_id: quiz.id,
          intento_id: intento_quiz.id,
          puntaje: intento_quiz.puntaje_total
        }
      )
    end

    # Notificación para ejercicio completado
    def ejercicio_completado(ejercicio_completado)
      ejercicio = ejercicio_completado.ejercicio

      create!(
        usuario: ejercicio_completado.usuario,
        notificable: ejercicio,
        tipo: :ejercicio,
        nivel: :exito,
        titulo: 'Objetivo completado',
        contenido: "Has completado el objetivo '#{ejercicio.titulo}'",
        datos_adicionales: {
          ejercicio_id: ejercicio.id,
          puntos: ejercicio.puntos
        }
      )
    end

    # Notificación para sesión iniciada
    def sesion_iniciada(sesion_laboratorio)
      laboratorio = sesion_laboratorio.laboratorio

      create!(
        usuario: sesion_laboratorio.usuario,
        notificable: laboratorio,
        tipo: :laboratorio,
        nivel: :informativa,
        titulo: 'Sesión iniciada',
        contenido: "Has iniciado una sesión en el laboratorio '#{laboratorio.nombre}'",
        datos_adicionales: {
          laboratorio_id: laboratorio.id,
          curso_id: laboratorio.curso_id,
          sesion_id: sesion_laboratorio.id
        }
      )
    end

    # Notificación de alerta de seguridad
    def alerta_seguridad(security_alert)
      create!(
        usuario: security_alert.usuario,
        notificable: security_alert,
        tipo: :alerta_seguridad,
        nivel: :advertencia,
        titulo: 'Alerta de seguridad',
        contenido: security_alert.mensaje,
        datos_adicionales: {
          nivel_alerta: security_alert.nivel,
          sesion_id: security_alert.sesion_laboratorio_id
        }
      )
    end

    # Notificación para los administradores
    def notificar_administradores(titulo, contenido, datos = {})
      Usuario.where(rol: 'admin').each do |admin|
        create!(
          usuario: admin,
          tipo: :sistema,
          nivel: :informativa,
          titulo: titulo,
          contenido: contenido,
          datos_adicionales: datos
        )
      end
    end

    # Notificación para los profesores de un curso
    def notificar_profesor(curso, titulo, contenido, datos = {})
      profesor = curso.profesor

      create!(
        usuario: profesor,
        notificable: curso,
        tipo: :curso,
        nivel: :informativa,
        titulo: titulo,
        contenido: contenido,
        datos_adicionales: datos
      )
    end

    # Notificación a todos los estudiantes de un curso
    def notificar_estudiantes_curso(curso, titulo, contenido, datos = {})
      curso.estudiantes.each do |estudiante|
        create!(
          usuario: estudiante,
          notificable: curso,
          tipo: :curso,
          nivel: :informativa,
          titulo: titulo,
          contenido: contenido,
          datos_adicionales: datos
        )
      end
    end
  end
end
