class AddLaboratorioIdToMetricaLaboratorios < ActiveRecord::Migration[7.1]
  def change
    # Primero añadir la referencia como nullable para poder migrar datos existentes
    add_reference :metrica_laboratorios, :laboratorio, null: true, foreign_key: true
    
    # Actualizar registros existentes con el laboratorio_id desde sesion_laboratorio
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE metrica_laboratorios
          SET laboratorio_id = (
            SELECT laboratorio_id 
            FROM sesion_laboratorios 
            WHERE sesion_laboratorios.id = metrica_laboratorios.sesion_laboratorio_id
          )
          WHERE laboratorio_id IS NULL
        SQL
      end
    end
    
    # Finalmente, hacer la columna not null
    change_column_null :metrica_laboratorios, :laboratorio_id, false
  end
end
