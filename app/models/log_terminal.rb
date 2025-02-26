# app/models/log_terminal.rb
class LogTerminal < ApplicationRecord
  belongs_to :sesion_laboratorio
  belongs_to :usuario

  validates :contenido, presence: true
  validates :tipo, presence: true

  enum tipo: {
    comando: 'comando',
    resultado: 'resultado',
    error: 'error',
    sistema: 'sistema'
  }

  scope :recientes, -> { order(created_at: :desc) }
end