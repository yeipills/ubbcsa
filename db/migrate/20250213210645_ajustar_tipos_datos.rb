class AjustarTiposDatos < ActiveRecord::Migration[7.1]
  def change
    # Verificar si la tabla existe antes de modificarla
    if table_exists?(:sesion_laboratorios)
      # Asegurar que tiempo_inicio y tiempo_fin sean timestamp
      change_column :sesion_laboratorios, :tiempo_inicio, :timestamp if column_exists?(:sesion_laboratorios, :tiempo_inicio)
      change_column :sesion_laboratorios, :tiempo_fin, :timestamp if column_exists?(:sesion_laboratorios, :tiempo_fin)
    end
  end
end