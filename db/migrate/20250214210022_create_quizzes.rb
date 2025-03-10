class CreateQuizzes < ActiveRecord::Migration[7.1]
  def change
    # Verificar si las tablas dependientes existen
    unless table_exists?(:cursos) && table_exists?(:laboratorios) && table_exists?(:usuarios)
      puts "⚠️ Tablas dependientes 'cursos', 'laboratorios' y/o 'usuarios' no existen. Saltando la creación de quizzes."
      return
    end
    
    create_table :quizzes do |t|
      t.string :titulo, null: false
      t.text :descripcion
      t.references :curso, null: false, foreign_key: true
      t.references :laboratorio, null: false, foreign_key: true
      t.references :usuario, null: false, foreign_key: true
      t.integer :estado, default: 0
      t.integer :tiempo_limite
      t.integer :intentos_permitidos, default: 1
      t.boolean :activo, default: true
      t.datetime :fecha_inicio
      t.datetime :fecha_fin

      t.timestamps
    end

    add_index :quizzes, [:curso_id, :laboratorio_id, :titulo], unique: true
  end
end