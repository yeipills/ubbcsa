class AgregarForeignKeys < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :laboratorios, :cursos, unless_exists: true
    add_foreign_key :sesion_laboratorios, :laboratorios, unless_exists: true
    add_foreign_key :sesion_laboratorios, :usuarios, unless_exists: true
    add_foreign_key :cursos, :usuarios, column: :profesor_id, unless_exists: true
  end
end