# app/policies/intento_quiz_policy.rb
class IntentoQuizPolicy < ApplicationPolicy
  def create?
    return false unless user.estudiante?
    return false unless record.quiz.publicado?
    return false if record.quiz.fecha_fin < Time.current
    
    intentos_actuales = user.intentos_quiz.where(quiz: record.quiz).count
    intentos_actuales < record.quiz.intentos_permitidos
  end

  def update?
    user == record.usuario && record.en_progreso?
  end

  def finalizar?
    user == record.usuario && record.en_progreso?
  end
end