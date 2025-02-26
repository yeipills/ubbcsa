class CreateQuizOpciones < ActiveRecord::Migration[7.1]
  def change
    # Verificar si la tabla dependiente existe
    unless table_exists?(:quiz_preguntas)
      puts " Tabla dependiente 'quiz_preguntas' no existe. Saltando la creación de quiz_opciones."
      return
    end
    
    create_table :quiz_opciones do |t|
      t.references :pregunta, null: false, foreign_key: { to_table: :quiz_preguntas }
      t.text :contenido, null: false
      t.boolean :es_correcta, default: false
      t.integer :orden
      t.boolean :activa, default: true

      t.timestamps
    end

    add_index :quiz_opciones, [:pregunta_id, :orden]
  end
end