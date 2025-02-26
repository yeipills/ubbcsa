# app/models/quiz_notification.rb
class QuizNotification < ApplicationRecord
  belongs_to :quiz
  belongs_to :usuario
  
  enum tipo: {
    quiz_disponible: 0,
    quiz_por_vencer: 1,
    resultado_disponible: 2
  }
end