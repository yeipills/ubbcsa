class CreateQuizPreguntas < ActiveRecord::Migration[7.1]
  def change
    # Verificar si la tabla dependiente existe
    unless table_exists?(:quizzes)
      puts " Tabla dependiente 'quizzes' no existe. Saltando la creación de quiz_preguntas."
      return
    end
    
    create_table :quiz_preguntas do |t|
      t.references :quiz, null: false, foreign_key: true
      t.text :contenido, null: false
      t.integer :tipo, null: false
      t.decimal :puntaje, precision: 5, scale: 2, null: false
      t.integer :orden
      t.boolean :activa, default: true

      t.timestamps
    end

    add_index :quiz_preguntas, [:quiz_id, :orden]
  end
end