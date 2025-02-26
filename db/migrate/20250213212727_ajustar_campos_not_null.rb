class AjustarCamposNotNull < ActiveRecord::Migration[7.1]
  def change
    change_column_null :laboratorios, :curso_id, false
    change_column_null :sesion_laboratorios, :laboratorio_id, false
    change_column_null :sesion_laboratorios, :usuario_id, false
  end
end