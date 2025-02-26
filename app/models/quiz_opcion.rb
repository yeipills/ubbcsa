# app/models/quiz_opcion.rb
class QuizOpcion < ApplicationRecord
  belongs_to :pregunta, class_name: 'QuizPregunta'
  has_many :respuestas, class_name: 'RespuestaQuiz', foreign_key: 'opcion_id'

  validates :contenido, presence: true
  validates :orden, presence: true, uniqueness: { scope: :pregunta_id }

  default_scope { order(orden: :asc) }
end