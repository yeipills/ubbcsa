class UpdateQuizSchema < ActiveRecord::Migration[7.1]
  def change
    # Cambios a tabla quizzes
    unless column_exists?(:quizzes, :has_results_cache)
      add_column :quizzes, :has_results_cache, :boolean, default: false
    end
    
    # Cambios a tabla quiz_preguntas
    unless column_exists?(:quiz_preguntas, :metadata)
      add_column :quiz_preguntas, :metadata, :jsonb, default: {}
    end
    
    # Cambios a tabla intentos_quiz
    unless column_exists?(:intentos_quiz, :has_result)
      add_column :intentos_quiz, :has_result, :boolean, default: false
    end
    
    unless column_exists?(:intentos_quiz, :detalles_resultado)
      add_column :intentos_quiz, :detalles_resultado, :jsonb, default: {}
    end
    
    # Asegurar que table quiz_results exista
    unless table_exists?(:quiz_results)
      create_table :quiz_results do |t|
        t.references :quiz, null: false, foreign_key: true
        t.references :usuario, null: false, foreign_key: true
        t.references :intento_quiz, null: false, foreign_key: true
        t.decimal :puntaje_total, precision: 5, scale: 2, null: false
        t.integer :total_preguntas, null: false
        t.integer :respuestas_correctas, null: false
        t.integer :tiempo_segundos
        t.jsonb :preguntas_correctas, default: []
        t.jsonb :preguntas_incorrectas, default: []
        t.boolean :aprobado, default: false
        t.integer :posicion_ranking

        t.timestamps
      end
      
      add_index :quiz_results, [:quiz_id, :usuario_id, :intento_quiz_id], unique: true, name: 'index_quiz_results_on_unique_attempt'
      add_index :quiz_results, :aprobado
      add_index :quiz_results, [:quiz_id, :puntaje_total]
    end
    
    # Asegurar que tabla eventos_intento exista
    unless table_exists?(:eventos_intento)
      create_table :eventos_intento do |t|
        t.string :tipo, null: false
        t.references :usuario, null: false, foreign_key: true
        t.references :intento_quiz, null: false, foreign_key: true
        t.jsonb :detalles, default: {}
        t.datetime :timestamp, null: false

        t.timestamps
      end
      
      add_index :eventos_intento, :tipo
      add_index :eventos_intento, :timestamp
    end
  end
end
