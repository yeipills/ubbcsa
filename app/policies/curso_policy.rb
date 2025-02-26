# app/policies/curso_policy.rb
class CursoPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.profesor? || record.estudiante?(user)
  end

  def create?
    user.profesor?
  end

  def update?
    user.profesor? && record.profesor?(user)
  end

  def destroy?
    user.profesor? && record.profesor?(user)
  end

  def inscribir_estudiante?
    user.profesor? && record.profesor?(user)
  end

  def desinscribir_estudiante?
    user.profesor? && record.profesor?(user)
  end
end