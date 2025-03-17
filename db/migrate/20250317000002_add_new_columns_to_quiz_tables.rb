class AddNewColumnsToQuizTables < ActiveRecord::Migration[7.1]
  def change
    # Añadir columnas a la tabla quizzes
    add_column :quizzes, :codigo_acceso, :string, comment: "Código único para acceso al quiz"
    add_column :quizzes, :fecha_publicacion, :datetime, comment: "Fecha cuando el quiz fue publicado"
    add_column :quizzes, :mostrar_resultados_inmediatos, :boolean, default: false, comment: "Indica si los resultados se muestran inmediatamente después de finalizar"
    add_column :quizzes, :aleatorizar_preguntas, :boolean, default: false, comment: "Indica si las preguntas se muestran en orden aleatorio"
    add_column :quizzes, :aleatorizar_opciones, :boolean, default: false, comment: "Indica si las opciones de las preguntas se muestran en orden aleatorio"
    add_column :quizzes, :peso_calificacion, :decimal, precision: 5, scale: 2, default: 100.0, comment: "Peso porcentual del quiz en la calificación"
    add_column :quizzes, :instrucciones, :text, comment: "Instrucciones detalladas para los estudiantes"
    
    # Añadir índice único al código de acceso
    add_index :quizzes, :codigo_acceso, unique: true
    
    # No añadimos retroalimentacion ya que existe desde la migración 20250304181020_add_retroalimentacion_to_quiz_preguntas
    # Ya se ha verificado que existe en la base de datos
  end
end