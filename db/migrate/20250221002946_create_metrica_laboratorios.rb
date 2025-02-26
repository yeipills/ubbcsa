class CreateMetricaLaboratorios < ActiveRecord::Migration[7.1]
  def change
    # Verificar si la tabla dependiente existe
    unless table_exists?(:sesion_laboratorios)
      puts "⚠️ Tabla dependiente 'sesion_laboratorios' no existe. Saltando la creación de metrica_laboratorios."
      return
    end
    
    create_table :metrica_laboratorios do |t|
      t.references :sesion_laboratorio, null: false, foreign_key: true
      t.float :cpu_usage, null: false, default: 0
      t.float :memory_usage, null: false, default: 0
      t.float :network_usage, null: false, default: 0
      t.datetime :timestamp, null: false

      t.timestamps
    end

    add_index :metrica_laboratorios, [:sesion_laboratorio_id, :timestamp]
  end
end