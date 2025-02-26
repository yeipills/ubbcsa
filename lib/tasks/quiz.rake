# lib/tasks/quiz.rake
namespace :quiz do
  desc "Cierra los quizzes vencidos"
  task cerrar_vencidos: :environment do
    Quiz.where("fecha_fin < ?", Time.current).update_all(estado: :cerrado)
  end

  desc "Envía recordatorios para quizzes próximos a vencer"
  task enviar_recordatorios: :environment do
    Quiz.publicado.where("fecha_fin < ?", 24.hours.from_now).find_each do |quiz|
      quiz.curso.estudiantes.each do |estudiante|
        QuizMailer.recordatorio_quiz(estudiante, quiz).deliver_later
      end
    end
  end
end