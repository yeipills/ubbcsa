# app/mailers/quiz_mailer.rb
class QuizMailer < ApplicationMailer
  def quiz_disponible(usuario, quiz)
    @usuario = usuario
    @quiz = quiz
    mail(to: @usuario.email, subject: "Nuevo Quiz Disponible: #{@quiz.titulo}")
  end

  def resultado_disponible(usuario, intento)
    @usuario = usuario
    @intento = intento
    @quiz = @intento.quiz
    mail(to: @usuario.email, subject: "Resultados disponibles: #{@quiz.titulo}")
  end
end