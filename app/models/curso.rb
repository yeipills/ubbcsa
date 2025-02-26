class Curso < ApplicationRecord
  belongs_to :profesor, class_name: 'Usuario'
  has_many :curso_estudiantes
  has_many :estudiantes, through: :curso_estudiantes, source: :usuario
  has_many :laboratorios
  has_many :quizzes

  validates :nombre, presence: true
  validates :codigo, presence: true, uniqueness: true
  
  attribute :estado, :integer
  enum estado: { borrador: 0, publicado: 1, archivado: 2 }
  
  scope :activos, -> { where(activo: true) }

  def profesor?(usuario)
    profesor_id == usuario.id
  end
end