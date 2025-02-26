class CreateQuizPreguntas < ActiveRecord::Migration[7.1]
  def change
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