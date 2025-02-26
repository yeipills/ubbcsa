# app/models/quiz.rb
class Quiz < ApplicationRecord
  belongs_to :curso
  belongs_to :laboratorio
  belongs_to :usuario

  has_many :preguntas, class_name: 'QuizPregunta', dependent: :destroy
  has_many :intentos, class_name: 'IntentoQuiz', dependent: :destroy

  validates :titulo, presence: true
  validates :curso_id, presence: true 
  validates :laboratorio_id, presence: true
  validates :tiempo_limite, numericality: { greater_than: 0 }
  validates :intentos_permitidos, numericality: { greater_than: 0 }

  enum estado: {
    borrador: 0,
    publicado: 1,
    cerrado: 2
  }

  scope :activos, -> { where(activo: true) }
  scope :del_curso, ->(curso_id) { where(curso_id: curso_id) }

  private

  def fecha_fin_despues_de_inicio
    return unless fecha_inicio && fecha_fin
    if fecha_fin <= fecha_inicio
      errors.add(:fecha_fin, "debe ser posterior a la fecha de inicio")
    end
  end

  def tiempo_limite_valido
    if tiempo_limite.present? && tiempo_limite <= 0
      errors.add(:tiempo_limite, "debe ser mayor que 0")
    end
  end
end