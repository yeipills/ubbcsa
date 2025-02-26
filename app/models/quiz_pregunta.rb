# app/models/quiz_pregunta.rb
class QuizPregunta < ApplicationRecord
  belongs_to :quiz
  has_many :opciones, class_name: 'QuizOpcion', foreign_key: 'pregunta_id', dependent: :destroy
  has_many :respuestas, class_name: 'RespuestaQuiz', foreign_key: 'pregunta_id'

  validates :contenido, presence: true
  validates :puntaje, presence: true, numericality: { greater_than: 0 }
  validates :orden, presence: true, uniqueness: { scope: :quiz_id }

  enum tipo: {
    opcion_multiple: 0,
    verdadero_falso: 1,
    respuesta_corta: 2
  }

  default_scope { order(orden: :asc) }
end