# app/models/ejercicio_completado.rb
class EjercicioCompletado < ApplicationRecord
  belongs_to :ejercicio
  belongs_to :sesion_laboratorio
  belongs_to :usuario

  validates :ejercicio_id, uniqueness: { scope: %i[sesion_laboratorio_id usuario_id] }

  scope :recientes, -> { order(completado_at: :desc) }
end
