# app/controllers/concerns/role_verifiable.rb
module RoleVerifiable
  extend ActiveSupport::Concern

  included do
    helper_method :can_manage_course?, :can_manage_quiz?, :can_view_reports?
  end

  def can_manage_course?(course)
    current_usuario.admin? || 
    (current_usuario.profesor? && course.profesor_id == current_usuario.id)
  end

  def can_manage_quiz?(quiz)
    current_usuario.admin? || 
    (current_usuario.profesor? && quiz.curso.profesor_id == current_usuario.id)
  end

  def can_view_reports?
    current_usuario.admin? || current_usuario.profesor?
  end
end
