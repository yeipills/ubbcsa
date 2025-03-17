class CreateQuizResults < ActiveRecord::Migration[7.1]
  def change
    create_table :quiz_results do |t|
      t.references :quiz, null: false, foreign_key: true
      t.references :usuario, null: false, foreign_key: true
      t.references :intento_quiz, null: false, foreign_key: { to_table: :intentos_quiz }
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
  end
end
