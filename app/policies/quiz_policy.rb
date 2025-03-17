# app/policies/quiz_policy.rb
class QuizPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    # Todos pueden ver un quiz, pero los estudiantes solo los publicados
    return true if user.admin? || user.profesor?
    
    # Estudiantes solo pueden ver quizzes publicados de sus cursos
    user.estudiante? && record.estado == 'publicado' && user.cursos.include?(record.curso)
  end

  def create?
    # Solo profesores y administradores pueden crear quizzes
    user.admin? || user.profesor?
  end

  def update?
    # Solo el profesor creador del quiz o administradores pueden editar
    user.admin? || (user.profesor? && record.curso.profesor_id == user.id)
  end

  def destroy?
    # Solo el profesor creador del quiz o administradores pueden eliminar
    user.admin? || (user.profesor? && record.curso.profesor_id == user.id)
  end
  
  def publicar?
    # Solo el profesor creador del quiz o administradores pueden publicar
    user.admin? || (user.profesor? && record.curso.profesor_id == user.id)
  end
  
  def despublicar?
    # Solo el profesor creador del quiz o administradores pueden despublicar
    user.admin? || (user.profesor? && record.curso.profesor_id == user.id)
  end
  
  def duplicate?
    # Solo el profesor creador del quiz o administradores pueden duplicar
    user.admin? || (user.profesor? && record.curso.profesor_id == user.id)
  end
  
  def estadisticas?
    # Solo el profesor creador del quiz o administradores pueden ver estadísticas
    user.admin? || (user.profesor? && record.curso.profesor_id == user.id)
  end
  
  def exportar_resultados?
    # Solo el profesor creador del quiz o administradores pueden exportar resultados
    user.admin? || (user.profesor? && record.curso.profesor_id == user.id)
  end

  class Scope < Scope
    def resolve
      if user.admin?
        # Administrador ve todos los quizzes
        scope.all
      elsif user.profesor?
        # Profesor ve sus propios quizzes (de sus cursos)
        scope.joins(:curso).where(cursos: { profesor_id: user.id })
      else
        # Estudiantes solo ven quizzes publicados de sus cursos
        scope.joins(:curso)
             .joins("INNER JOIN curso_estudiantes ON cursos.id = curso_estudiantes.curso_id")
             .where(curso_estudiantes: { usuario_id: user.id }, quizzes: { estado: 'publicado' })
      end
    end
  end
end