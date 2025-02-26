class AgregarForeignKeys < ActiveRecord::Migration[7.1]
  def change
    # Solo agregar foreign keys si las tablas existen
    if table_exists?(:laboratorios) && table_exists?(:cursos)
      add_foreign_key :laboratorios, :cursos, unless_exists: true
    end
    
    if table_exists?(:sesion_laboratorios) && table_exists?(:laboratorios)
      add_foreign_key :sesion_laboratorios, :laboratorios, unless_exists: true
    end
    
    if table_exists?(:sesion_laboratorios) && table_exists?(:usuarios)
      add_foreign_key :sesion_laboratorios, :usuarios, unless_exists: true
    end
    
    if table_exists?(:cursos) && table_exists?(:usuarios)
      add_foreign_key :cursos, :usuarios, column: :profesor_id, unless_exists: true
    end
  end
end