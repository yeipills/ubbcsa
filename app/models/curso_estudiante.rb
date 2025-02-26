# app/models/curso_estudiante.rb
class CursoEstudiante < ApplicationRecord
  belongs_to :curso
  belongs_to :usuario

  validates :curso_id, uniqueness: { scope: :usuario_id }
end