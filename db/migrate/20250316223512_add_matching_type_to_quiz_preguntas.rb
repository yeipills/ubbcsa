class AddMatchingTypeToQuizPreguntas < ActiveRecord::Migration[7.1]
  def change
    # Add a jsonb column for matched pairs data
    add_column :quiz_opciones, :par_relacionado, :jsonb, default: {}, null: false
    
    # Add a column to indicate if this is a term that needs matching
    add_column :quiz_opciones, :es_termino, :boolean, default: false, null: false
    
    # Add datos_json column to respuestas_quiz (if not already created)
    unless column_exists?(:respuestas_quiz, :datos_json)
      add_column :respuestas_quiz, :datos_json, :jsonb, default: {}, null: false
    end
  end
end
