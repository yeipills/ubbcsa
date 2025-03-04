# app/models/quiz_pregunta.rb
class QuizPregunta < ApplicationRecord
  self.table_name = 'quiz_preguntas' # Asegurar que usa el nombre correcto de la tabla

  belongs_to :quiz
  has_many :opciones, class_name: 'QuizOpcion', foreign_key: 'pregunta_id', dependent: :destroy
  has_many :respuestas, class_name: 'RespuestaQuiz', foreign_key: 'pregunta_id'
  has_one_attached :imagen

  validates :contenido, presence: true
  validates :puntaje, presence: true, numericality: { greater_than: 0 }
  validates :orden, presence: true, uniqueness: { scope: :quiz_id }

  enum tipo: {
    opcion_multiple: 0,
    verdadero_falso: 1,
    respuesta_corta: 2
  }

  default_scope { order(orden: :asc) }

  # Métodos auxiliares
  def requiere_opciones?
    opcion_multiple? || verdadero_falso?
  end

  def tiene_opciones_suficientes?
    return true unless opcion_multiple?

    opciones.count >= 2
  end

  def tiene_respuesta_correcta?
    if opcion_multiple? || verdadero_falso?
      opciones.where(es_correcta: true).exists?
    elsif respuesta_corta?
      respuesta_correcta.present?
    else
      false
    end
  end
end
