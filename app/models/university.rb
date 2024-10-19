class University < ApplicationRecord
  has_many :careers, dependent: :destroy

  validates :nombre, presence: true
end
