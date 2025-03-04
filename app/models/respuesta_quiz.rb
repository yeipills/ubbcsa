class RespuestaQuiz < ApplicationRecord
  self.table_name = 'respuestas_quiz'

  belongs_to :intento_quiz
  belongs_to :pregunta, class_name: 'QuizPregunta'
  belongs_to :opcion, class_name: 'QuizOpcion', optional: true

  # Validaciones
  validates :pregunta_id, uniqueness: { scope: :intento_quiz_id }
  validate :validar_tipo_respuesta

  # Scopes
  scope :correctas, -> { where(es_correcta: true) }
  scope :incorrectas, -> { where(es_correcta: false) }

  # Métodos de instancia
  def es_correcta?
    es_correcta
  end

  def valor
    opcion_id.present? ? opcion.contenido : respuesta_texto
  end

  def verificar_correctitud
    case pregunta.tipo
    when 'opcion_multiple', 'verdadero_falso'
      opcion&.es_correcta? || false
    when 'respuesta_corta'
      verificar_respuesta_corta
    when 'emparejamiento'
      verificar_emparejamiento
    else
      false
    end
  end

  def tiempo_respuesta
    return nil unless created_at && intento_quiz&.iniciado_en

    (created_at - intento_quiz.iniciado_en).to_i
  end

  private

  def validar_tipo_respuesta
    case pregunta.tipo
    when 'opcion_multiple', 'verdadero_falso'
      errors.add(:opcion_id, 'debe seleccionar una opción') if opcion_id.blank?
    when 'respuesta_corta'
      errors.add(:respuesta_texto, 'no puede estar en blanco') if respuesta_texto.blank?
    when 'emparejamiento'
      errors.add(:base, 'debe proporcionar una respuesta') if respuesta_texto.blank? && opcion_id.blank?
    end
  end

  def verificar_respuesta_corta
    return false if respuesta_texto.blank?

    # Comparación básica (se puede mejorar con algoritmos más sofisticados)
    respuesta_correcta = pregunta.respuesta_correcta.to_s.downcase.strip
    respuesta_usuario = respuesta_texto.to_s.downcase.strip

    if respuesta_usuario == respuesta_correcta
      self.es_correcta = true
      self.puntaje_obtenido = pregunta.puntaje
    else
      self.es_correcta = false
      self.puntaje_obtenido = 0
    end

    es_correcta
  end

  def verificar_emparejamiento
    # Implementación simple para emparejamiento
    self.es_correcta = opcion&.es_correcta? || false
    self.puntaje_obtenido = es_correcta ? pregunta.puntaje : 0

    es_correcta
  end
end
