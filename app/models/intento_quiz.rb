class IntentoQuiz < ApplicationRecord
  self.table_name = 'intentos_quiz'

  belongs_to :quiz
  belongs_to :usuario
  has_many :respuestas, class_name: 'RespuestaQuiz', dependent: :destroy

  # Validaciones
  validates :numero_intento, uniqueness: { scope: %i[quiz_id usuario_id] }
  validates :iniciado_en, presence: true

  # Enumeraciones
  enum estado: {
    en_progreso: 0,
    completado: 1,
    expirado: 2
  }

  # Callbacks
  before_validation :set_numero_intento, on: :create
  before_validation :set_iniciado_en, on: :create

  # Scopes
  scope :completados, -> { where(estado: :completado) }
  scope :en_curso, -> { where(estado: :en_progreso) }
  scope :recientes, -> { order(created_at: :desc) }

  # Métodos de instancia
  def duracion_segundos
    return nil unless finalizado_en

    (finalizado_en - iniciado_en).to_i
  end

  def progreso_porcentaje
    total_preguntas = quiz.preguntas.count
    return 0 if total_preguntas.zero?

    preguntas_respondidas = respuestas.count
    (preguntas_respondidas.to_f / total_preguntas * 100).round
  end

  def tiempo_restante_segundos
    return 0 unless en_progreso?

    tiempo_limite = quiz.tiempo_limite * 60
    tiempo_transcurrido = Time.current - iniciado_en

    [tiempo_limite - tiempo_transcurrido.to_i, 0].max
  end

  def respuesta_para(pregunta)
    respuestas.find_by(pregunta_id: pregunta.id)
  end

  def pregunta_respondida?(pregunta)
    respuesta_para(pregunta).present?
  end

  def calcular_resultado
    return if estado != 'completado'

    total_puntos = 0
    total_posible = 0

    quiz.preguntas.each do |pregunta|
      total_posible += pregunta.puntaje

      respuesta = respuesta_para(pregunta)
      next unless respuesta&.es_correcta?

      total_puntos += respuesta.puntaje_obtenido
    end

    porcentaje = total_posible.zero? ? 0 : ((total_puntos / total_posible.to_f) * 100).round(1)
    update_column(:puntaje_total, porcentaje)

    porcentaje
  end

  def resultado_texto
    case puntaje_total
    when 0..59.9
      'Insuficiente'
    when 60..69.9
      'Suficiente'
    when 70..79.9
      'Bueno'
    when 80..89.9
      'Muy bueno'
    else
      'Excelente'
    end
  end

  def self.expirar_intentos_vencidos
    where(estado: :en_progreso)
      .joins(:quiz)
      .where('intentos_quiz.created_at + (quizzes.tiempo_limite * interval \'1 minute\') < ?', Time.current)
      .update_all(estado: :expirado, finalizado_en: Time.current)
  end

  def expirado?
    return false unless quiz.tiempo_limite
    return false if finalizado_en.present?

    tiempo_transcurrido = (Time.current - iniciado_en) / 60
    tiempo_transcurrido > quiz.tiempo_limite
  end

  private

  def set_numero_intento
    return if numero_intento.present?

    ultimo_intento = quiz.intentos.where(usuario_id: usuario_id).maximum(:numero_intento) || 0
    self.numero_intento = ultimo_intento + 1
  end

  def set_iniciado_en
    self.iniciado_en ||= Time.current
  end
end
