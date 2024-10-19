class Category < ApplicationRecord
  has_many :courses, dependent: :restrict_with_exception

  validates :name, presence: true
end
