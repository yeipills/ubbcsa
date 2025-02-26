# db/migrate/[TIMESTAMP]_create_curso_estudiantes.rb
class CreateCursoEstudiantes < ActiveRecord::Migration[7.1]
  def change
    create_table :curso_estudiantes do |t|
      t.references :curso, null: false, foreign_key: true
      t.references :usuario, null: false, foreign_key: true
      t.timestamps
    end

      # Añadimos un índice único para evitar duplicados
      add_index :curso_estudiantes, [:curso_id, :usuario_id], unique: true
  end
end