class Course < ApplicationRecord
  belongs_to :professor
  belongs_to :category
  has_many :materials, dependent: :destroy
  has_many :enrollments, dependent: :destroy
  has_many :purchases, dependent: :destroy

  validates :nombre, presence: true
    
  # Scope para obtener cursos destacados
  scope :featured, -> { where(featured: true) }
end
