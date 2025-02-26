class CreateIntentosQuiz < ActiveRecord::Migration[7.1]
  def change
    # Verificar si las tablas dependientes existen
    unless table_exists?(:quizzes) && table_exists?(:usuarios)
      puts " Tablas dependientes 'quizzes' y/o 'usuarios' no existen. Saltando la creación de intentos_quiz."
      return
    end
    
    create_table :intentos_quiz do |t|
      t.references :quiz, null: false, foreign_key: true
      t.references :usuario, null: false, foreign_key: true
      t.integer :estado, default: 0
      t.decimal :puntaje_total, precision: 5, scale: 2
      t.datetime :iniciado_en
      t.datetime :finalizado_en
      t.integer :tiempo_usado
      t.integer :numero_intento

      t.timestamps
    end

    add_index :intentos_quiz, [:quiz_id, :usuario_id, :numero_intento], unique: true
  end
end