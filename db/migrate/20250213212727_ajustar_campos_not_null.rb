class AjustarCamposNotNull < ActiveRecord::Migration[7.1]
  def change
    # Verificar si las tablas existen antes de modificar campos not null
    if table_exists?(:laboratorios)
      change_column_null :laboratorios, :curso_id, false if column_exists?(:laboratorios, :curso_id)
    end
    
    if table_exists?(:sesion_laboratorios)
      change_column_null :sesion_laboratorios, :laboratorio_id, false if column_exists?(:sesion_laboratorios, :laboratorio_id)
      change_column_null :sesion_laboratorios, :usuario_id, false if column_exists?(:sesion_laboratorios, :usuario_id)
    end
  end
end