# app/policies/quiz_policy.rb
class QuizPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    user.profesor?
  end

  def update?
    user.profesor? && record.usuario_id == user.id
  end

  def destroy?
    user.profesor? && record.usuario_id == user.id
  end

  class Scope < Scope
    def resolve
      if user.profesor?
        scope.where(usuario_id: user.id)
      else
        scope.where(estado: :publicado)
      end
    end
  end
end