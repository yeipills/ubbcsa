class CreateEjercicios < ActiveRecord::Migration[7.1]
  def change
    create_table :ejercicios do |t|
      t.references :laboratorio, null: false, foreign_key: true
      t.string :titulo, null: false
      t.text :descripcion
      t.string :tipo, null: false
      t.string :nivel_dificultad, default: 'intermedio'
      t.jsonb :parametros, default: {}
      t.boolean :activo, default: true

      t.timestamps
    end
    
    add_index :ejercicios, [:laboratorio_id, :titulo], unique: true
    add_index :ejercicios, :tipo
  end
end