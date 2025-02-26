# app/models/intento_quiz.rb
class IntentoQuiz < ApplicationRecord
  belongs_to :quiz
  belongs_to :usuario
  has_many :respuestas, class_name: 'RespuestaQuiz', dependent: :destroy

  validates :numero_intento, uniqueness: { scope: [:quiz_id, :usuario_id] }

  enum estado: {
    en_progreso: 0,
    completado: 1
  }

  before_validation :set_numero_intento, on: :create
  before_validation :set_iniciado_en, on: :create

  private

  def set_numero_intento
    ultimo_intento = quiz.intentos.where(usuario_id: usuario_id).maximum(:numero_intento) || 0
    self.numero_intento = ultimo_intento + 1
  end

  def set_iniciado_en
    self.iniciado_en ||= Time.current
  end
end