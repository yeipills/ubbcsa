class Material < ApplicationRecord
  belongs_to :course

  validates :titulo, :contenido, presence: true
end
