# app/models/laboratorio.rb
class Laboratorio < ApplicationRecord
  has_many :sesion_laboratorios
  has_many :usuarios, through: :sesion_laboratorios
  belongs_to :curso

  validates :nombre, presence: true
  validates :descripcion, presence: true
  validates :tipo, presence: true
  validates :nivel_dificultad, presence: true
  validates :duracion_estimada, presence: true, numericality: { greater_than: 0 }
  validates :objetivos, presence: true
  validates :requisitos, presence: true

  scope :activos, -> { where(activo: true) }
  scope :recientes, -> { order(created_at: :desc).limit(5) }

  def estado_display
    activo ? 'Activo' : 'Inactivo'
  end
end
