class Professor < ApplicationRecord
  belongs_to :user
  has_many :courses, dependent: :restrict_with_exception

  validates :user_id, presence: true
end
