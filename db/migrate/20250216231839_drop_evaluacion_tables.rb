# db/migrate/20250216231839_drop_evaluacion_tables.rb
class DropEvaluacionTables < ActiveRecord::Migration[7.1]
  def up
    # Comprobar existencia de tablas antes de intentar eliminarlas
    drop_table :metricas_evaluacion if table_exists?(:metricas_evaluacion)
    drop_table :resultados_evaluacion if table_exists?(:resultados_evaluacion)
    drop_table :criterios_evaluacion if table_exists?(:criterios_evaluacion)
    drop_table :evaluaciones if table_exists?(:evaluaciones)
  end

  def down
    # Recreación de tablas si necesitas rollback
  end
end