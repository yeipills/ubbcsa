class AddEstadoToCursos < ActiveRecord::Migration[7.1]
  def change
    # Verificar si la tabla cursos existe antes de modificarla
    if table_exists?(:cursos)
      add_column :cursos, :estado, :integer unless column_exists?(:cursos, :estado)
    end
  end
end
