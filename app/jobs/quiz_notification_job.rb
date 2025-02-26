# app/jobs/quiz_notification_job.rb
class QuizNotificationJob < ApplicationJob
  queue_as :default

  def perform(quiz_id)
    quiz = Quiz.find(quiz_id)
    
    if quiz.publicado?
      notify_students_of_availability(quiz)
    end
  end

  private

  def notify_students_of_availability(quiz)
    quiz.curso.estudiantes.each do |estudiante|
      QuizNotification.create!(
        quiz: quiz,
        usuario: estudiante,
        tipo: :quiz_disponible
      )
    end
  end
end