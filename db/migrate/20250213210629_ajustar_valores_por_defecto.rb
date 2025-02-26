class AjustarValoresPorDefecto < ActiveRecord::Migration[7.1]
  def change
    # Verificar si la tabla cursos existe antes de modificarla
    if table_exists?(:cursos)
      # Ajustar valor por defecto de activo en cursos si no existe
      change_column_default :cursos, :activo, from: nil, to: true if column_exists?(:cursos, :activo)
    end

    # Verificar si la tabla laboratorios existe antes de modificarla
    if table_exists?(:laboratorios)
      # Ajustar valor por defecto de activo en laboratorios si no existe
      change_column_default :laboratorios, :activo, from: nil, to: true if column_exists?(:laboratorios, :activo)
    end
  end
end