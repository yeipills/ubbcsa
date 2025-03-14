# app/models/laboratorio.rb
class Laboratorio < ApplicationRecord
  has_many :sesion_laboratorios
  has_many :usuarios, through: :sesion_laboratorios
  belongs_to :curso
  has_many :ejercicios, dependent: :destroy
  has_many :metrica_laboratorios

  validates :nombre, presence: true
  validates :descripcion, presence: true
  validates :tipo, presence: true
  validates :nivel_dificultad, presence: true
  validates :duracion_estimada, presence: true, numericality: { greater_than: 0 }
  validates :objetivos, presence: true, unless: -> { new_record? }
  validates :requisitos, presence: true, unless: -> { new_record? }

  scope :activos, -> { where(activo: true) }
  scope :recientes, -> { order(created_at: :desc).limit(5) }
  
  # Tipos de laboratorio con escenarios de ataque/defensa
  TIPOS = [
    ['Pentesting', 'pentesting'],
    ['Forense', 'forense'],
    ['Redes', 'redes'],
    ['Web', 'web'],
    ['Atacante', 'atacante'],
    ['Defensor', 'defensor'],
    ['CTF Ofensivo', 'ctf_ofensivo'],
    ['Red Corporativa', 'red_corporativa']
  ]

  def estado_display
    activo ? 'Activo' : 'Inactivo'
  end
  
  # Verifica si este tipo de laboratorio soporta máquinas objetivo
  def soporta_objetivos?
    %w[atacante defensor pentesting redes ctf_ofensivo red_corporativa].include?(tipo)
  end
  
  # Retorna las máquinas objetivo disponibles para este tipo de laboratorio
  def objetivos_disponibles
    case tipo
    when 'atacante'
      %w[metasploitable dvwa webgoat]
    when 'defensor'
      %w[secure_ubuntu windows_server]
    when 'pentesting'
      %w[metasploitable dvwa webgoat]
    when 'redes'
      %w[router firewall]
    when 'ctf_ofensivo'
      %w[ctf-target]
    when 'red_corporativa'
      %w[router firewall server client]
    else
      []
    end
  end
end
