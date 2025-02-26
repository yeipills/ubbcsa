class AjustarPrecisionTiempos < ActiveRecord::Migration[7.1]
  def change
    # Verificar si la tabla existe antes de modificarla
    if table_exists?(:sesion_laboratorios)
      change_column :sesion_laboratorios, :tiempo_inicio, :datetime if column_exists?(:sesion_laboratorios, :tiempo_inicio)
      change_column :sesion_laboratorios, :tiempo_fin, :datetime if column_exists?(:sesion_laboratorios, :tiempo_fin)
    end
  end
end