# db/migrate/20250214210627_create_respuestas_quiz.rb
class CreateRespuestasQuiz < ActiveRecord::Migration[7.1]
  def change
    # Verificar si las tablas dependientes existen
    unless table_exists?(:intentos_quiz) && table_exists?(:quiz_preguntas) && table_exists?(:quiz_opciones)
      puts "⚠️ Tablas dependientes 'intentos_quiz', 'quiz_preguntas' y/o 'quiz_opciones' no existen. Saltando la creación de respuestas_quiz."
      return
    end
    
    create_table :respuestas_quiz do |t|
      t.references :intento_quiz, null: false, foreign_key: { to_table: :intentos_quiz }
      t.references :pregunta, null: false, foreign_key: { to_table: :quiz_preguntas }
      t.references :opcion, foreign_key: { to_table: :quiz_opciones }
      t.text :respuesta_texto
      t.decimal :puntaje_obtenido, precision: 5, scale: 2
      t.boolean :es_correcta
      t.datetime :respondido_en

      t.timestamps
    end

    add_index :respuestas_quiz, [:intento_quiz_id, :pregunta_id], unique: true
  end
end