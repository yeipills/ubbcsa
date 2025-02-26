class CreateQuizOpciones < ActiveRecord::Migration[7.1]
  def change
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