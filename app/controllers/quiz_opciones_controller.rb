# app/controllers/quiz_opciones_controller.rb
class QuizOpcionesController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_pregunta
  
  def new
    @opcion = @pregunta.opciones.build
  end

  private

  def set_pregunta
    @pregunta = QuizPregunta.find(params[:pregunta_id])
  end
end