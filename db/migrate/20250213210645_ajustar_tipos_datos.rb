class AjustarTiposDatos < ActiveRecord::Migration[7.1]
  def change
    # Asegurar que tiempo_inicio y tiempo_fin sean timestamp
    change_column :sesion_laboratorios, :tiempo_inicio, :timestamp
    change_column :sesion_laboratorios, :tiempo_fin, :timestamp
  end
end