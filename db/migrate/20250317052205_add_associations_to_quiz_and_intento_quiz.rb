class AddAssociationsToQuizAndIntentoQuiz < ActiveRecord::Migration[7.1]
  def change
    # Añadir relación con QuizResult a los modelos
    add_column :quizzes, :has_results_cache, :boolean, default: false
    add_column :intentos_quiz, :has_result, :boolean, default: false
    
    # Agregar campos adicionales para analíticas
    add_column :intentos_quiz, :detalles_resultado, :jsonb, default: {}
    add_column :intentos_quiz, :puntaje_obtenido, :decimal, precision: 8, scale: 2
    add_column :intentos_quiz, :puntaje_maximo, :decimal, precision: 8, scale: 2
    
    # Índice para buscar intentos con/sin resultados
    add_index :intentos_quiz, :has_result
  end
end
