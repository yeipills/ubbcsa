class AddContainerManagementToSesionLaboratorios < ActiveRecord::Migration[7.1]
  def change
    add_column :sesion_laboratorios, :container_id, :string
    add_column :sesion_laboratorios, :backup_enabled, :boolean, default: false
    add_column :sesion_laboratorios, :last_backup_at, :datetime
    add_column :sesion_laboratorios, :resource_usage, :jsonb
    add_column :sesion_laboratorios, :container_status, :string
    add_column :sesion_laboratorios, :completado, :boolean, default: false
    
    add_index :sesion_laboratorios, :container_id
  end
end