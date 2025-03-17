# app/controllers/concerns/role_verifiable.rb
module RoleVerifiable
  extend ActiveSupport::Concern

  included do
    helper_method :can_manage_course?, :can_manage_quiz?, :can_view_reports?, 
                  :can_manage_laboratorio?, :can_admin_dashboard?, :can_manage_users?,
                  :can_view_only?
  end

  # Verifica si el usuario tiene alguno de los roles especificados
  def has_role?(*roles)
    return false unless current_usuario
    roles.map(&:to_s).include?(current_usuario.rol)
  end
  
  # Método general para verificar si el usuario puede administrar un recurso
  def can_admin_resource?(resource_owner_id)
    return true if current_usuario.admin?
    return true if current_usuario.profesor? && resource_owner_id == current_usuario.id
    false
  end

  # Verificación específica para cursos
  def can_manage_course?(course)
    return true if current_usuario.admin?
    current_usuario.profesor? && course.profesor_id == current_usuario.id
  end

  # Verificación específica para quizzes
  def can_manage_quiz?(quiz)
    return true if current_usuario.admin?
    current_usuario.profesor? && quiz.curso.profesor_id == current_usuario.id
  end

  # Verificación específica para laboratorios
  def can_manage_laboratorio?(laboratorio)
    return true if current_usuario.admin?
    current_usuario.profesor? && laboratorio.curso.profesor_id == current_usuario.id
  end

  # Verificación para acceso a reportes
  def can_view_reports?
    current_usuario.admin? || current_usuario.profesor?
  end

  # Verificación para acceso al dashboard de administración
  def can_admin_dashboard?
    current_usuario.admin?
  end

  # Verificación para administración de usuarios
  def can_manage_users?
    current_usuario.admin?
  end

  # Verificación para roles de solo lectura (estudiantes)
  def can_view_only?
    current_usuario.estudiante?
  end
end
