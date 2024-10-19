class Role < ApplicationRecord
  has_many :users, dependent: :restrict_with_exception

  validates :nombre, presence: true, uniqueness: true
end
