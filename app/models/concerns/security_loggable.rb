# app/models/concerns/security_loggable.rb
module SecurityLoggable
  extend ActiveSupport::Concern

  included do
    after_create :log_creation
    after_update :log_changes
    before_destroy :log_deletion
  end

  private

  def log_creation
    SecurityLog.create(
      usuario_id: Current.usuario&.id,
      accion: 'creación',
      recurso_tipo: self.class.name,
      recurso_id: self.id,
      detalles: attributes
    )
  end

  def log_changes
    return unless saved_changes.any?
    
    SecurityLog.create(
      usuario_id: Current.usuario&.id,
      accion: 'modificación',
      recurso_tipo: self.class.name,
      recurso_id: self.id,
      detalles: saved_changes
    )
  end

  def log_deletion
    SecurityLog.create(
      usuario_id: Current.usuario&.id,
      accion: 'eliminación',
      recurso_tipo: self.class.name,
      recurso_id: self.id,
      detalles: attributes
    )
  end
end