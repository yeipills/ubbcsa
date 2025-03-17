class CreateTestQuizEmparejamientos < ActiveRecord::Migration[7.1]
  def change
    create_table :test_quiz_emparejamientos do |t|
      t.string :nombre, null: false
      t.text :descripcion
      t.jsonb :configuracion, default: {}
      t.timestamps
    end
  end
end
