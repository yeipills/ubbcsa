# db/migrate/20250216231839_drop_evaluacion_tables.rb
class DropEvaluacionTables < ActiveRecord::Migration[7.1]
  def up
    drop_table :metricas_evaluacion
    drop_table :resultados_evaluacion
    drop_table :criterios_evaluacion
    drop_table :evaluaciones
  end

  def down
    # Recreación de tablas si necesitas rollback
  end
end