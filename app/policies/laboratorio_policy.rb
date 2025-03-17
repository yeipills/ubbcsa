class LaboratorioPolicy < ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    true # Todos pueden ver el listado de laboratorios
  end

  def show?
    # Acceso para ver detalles del laboratorio
    return true if user.admin?
    return true if user.profesor? && record.curso.profesor_id == user.id
    
    # Estudiantes solo pueden acceder si están inscritos en el curso
    user.estudiante? && user.cursos.include?(record.curso)
  end

  def create?
    # Solo profesores y administradores pueden crear laboratorios
    user.admin? || user.profesor?
  end

  def update?
    # Solo el profesor dueño del curso o administradores pueden editar
    user.admin? || (user.profesor? && record.curso.profesor_id == user.id)
  end

  def destroy?
    # Solo el profesor dueño del curso o administradores pueden eliminar
    user.admin? || (user.profesor? && record.curso.profesor_id == user.id)
  end

  # Método general para verificar acceso
  def access?
    return false unless user
    return true if user.admin?
    return true if user.profesor? && record.curso.profesor_id == user.id
    
    # Estudiantes solo pueden acceder si están inscritos
    user.estudiante? && user.cursos.include?(record.curso)
  end

  # Método para verificar permisos de gestión
  def manage?
    user.admin? || (user.profesor? && record.curso.profesor_id == user.id)
  end
  
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.profesor?
        # Para profesores, solo laboratorios de sus cursos
        scope.joins(:curso).where(cursos: { profesor_id: user.id })
      else
        # Para estudiantes, solo laboratorios de cursos en los que están inscritos
        scope.joins(:curso).joins("INNER JOIN curso_estudiantes ON cursos.id = curso_estudiantes.curso_id")
             .where(curso_estudiantes: { usuario_id: user.id })
      end
    end
  end
end