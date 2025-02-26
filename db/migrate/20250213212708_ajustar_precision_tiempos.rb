class AjustarPrecisionTiempos < ActiveRecord::Migration[7.1]
  def change
    change_column :sesion_laboratorios, :tiempo_inicio, :datetime
    change_column :sesion_laboratorios, :tiempo_fin, :datetime
  end
end