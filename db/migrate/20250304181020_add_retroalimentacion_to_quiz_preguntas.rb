class AddRetroalimentacionToQuizPreguntas < ActiveRecord::Migration[7.1]
  def change
    add_column :quiz_preguntas, :retroalimentacion, :text
  end
end