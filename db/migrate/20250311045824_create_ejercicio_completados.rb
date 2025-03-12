class CreateEjercicioCompletados < ActiveRecord::Migration[7.1]
  def change
    create_table :ejercicio_completados do |t|
      t.references :ejercicio, null: false, foreign_key: true
      t.references :sesion_laboratorio, null: false, foreign_key: true
      t.references :usuario, null: false, foreign_key: true
      t.datetime :completado_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end
    
    add_index :ejercicio_completados, [:ejercicio_id, :sesion_laboratorio_id, :usuario_id], unique: true, name: 'index_ejercicio_completados_unique'
  end
end