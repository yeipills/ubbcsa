class AddRespuestaCorrectaToQuizPreguntas < ActiveRecord::Migration[7.1]
  def change
    add_column :quiz_preguntas, :respuesta_correcta, :string
  end
end
