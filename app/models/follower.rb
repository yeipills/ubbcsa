class Follower < ApplicationRecord
  belongs_to :user
  belongs_to :follower, class_name: 'User'

  # Validación para evitar que un usuario se siga a sí mismo
  validates :user_id, :follower_id, presence: true
  validates :user_id, uniqueness: { scope: :follower_id, message: 'ya está siguiendo a este usuario' }
  validate :cannot_follow_self

  # Método de validación personalizado para evitar que un usuario se siga a sí mismo
  def cannot_follow_self
    errors.add(:follower_id, 'no puede seguirse a sí mismo') if user_id == follower_id
  end
end
