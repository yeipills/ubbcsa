class AddEstadoToCursos < ActiveRecord::Migration[7.1]
  def change
    add_column :cursos, :estado, :integer
  end
end
