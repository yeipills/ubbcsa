# app/policies/curso_policy.rb
class CursoPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.admin? || user.profesor? || record.estudiante?(user)
  end

  def create?
    user.admin? || user.profesor?
  end

  def update?
    user.admin? || (user.profesor? && record.profesor?(user))
  end

  def destroy?
    user.admin? || (user.profesor? && record.profesor?(user))
  end

  def inscribir_estudiante?
    user.admin? || (user.profesor? && record.profesor?(user))
  end

  def desinscribir_estudiante?
    user.admin? || (user.profesor? && record.profesor?(user))
  end
  
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.profesor?
        scope.where(profesor_id: user.id)
      else
        # Para estudiantes, solo los cursos en los que están inscritos
        user.cursos
      end
    end
  end
end