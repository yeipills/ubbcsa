
class AjustarValoresPorDefecto < ActiveRecord::Migration[7.1]
  def change
    # Ajustar valor por defecto de activo en cursos si no existe
    change_column_default :cursos, :activo, from: nil, to: true

    # Ajustar valor por defecto de activo en laboratorios si no existe
    change_column_default :laboratorios, :activo, from: nil, to: true
  end
end