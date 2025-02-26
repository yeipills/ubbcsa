# app/models/security_alert.rb
class SecurityAlert < ApplicationRecord
  belongs_to :sesion_laboratorio
  belongs_to :usuario

  NIVELES = ['bajo', 'medio', 'alto', 'crítico']
  
  validates :nivel, inclusion: { in: NIVELES }
  validates :mensaje, presence: true

  after_create :notificar_administradores

  private

  def notificar_administradores
    AdminMailer.security_alert(self).deliver_later if nivel.in?(['alto', 'crítico'])
  end
end