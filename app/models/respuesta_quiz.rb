# app/models/respuesta_quiz.rb
class RespuestaQuiz < ApplicationRecord
  belongs_to :intento_quiz
  belongs_to :pregunta, class_name: 'QuizPregunta'
  belongs_to :opcion, class_name: 'QuizOpcion', optional: true

  validates :pregunta_id, uniqueness: { scope: :intento_quiz_id }
end