# app/models/ejercicio.rb
class Ejercicio < ApplicationRecord
  belongs_to :laboratorio
  has_many :ejercicio_completados
  
  validates :titulo, presence: true
  validates :descripcion, presence: true
  validates :nivel_dificultad, presence: true
  validates :tipo, presence: true

  enum tipo: {
    escaneo_red: 'escaneo_red',
    fuerza_bruta: 'fuerza_bruta',
    analisis_trafico: 'analisis_trafico',
    ataque_dos: 'ataque_dos'
  }

  def completado_por?(usuario)
    ejercicio_completados.where(usuario: usuario).exists?
  end
end