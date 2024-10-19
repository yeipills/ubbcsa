class Career < ApplicationRecord
  belongs_to :university
  has_many :users

  validates :nombre, presence: true
end
