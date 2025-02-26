# app/controllers/quiz_preguntas_controller.rb
class QuizPreguntasController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_quiz
  before_action :set_pregunta, only: [:show, :edit, :update, :destroy]
  before_action :verificar_profesor

  def index
    @preguntas = @quiz.preguntas
  end
  
  def new
    @pregunta = @quiz.preguntas.build
  end

  def create
    @pregunta = @quiz.preguntas.build(pregunta_params)

    if @pregunta.save
      redirect_to quiz_path(@quiz), notice: 'Pregunta creada exitosamente.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @pregunta.update(pregunta_params)
      redirect_to quiz_path(@quiz), notice: 'Pregunta actualizada exitosamente.'
    else
      render :edit
    end
  end

  def destroy
    @pregunta.destroy
    redirect_to quiz_path(@quiz), notice: 'Pregunta eliminada exitosamente.'
  end

  private

  def set_quiz
    @quiz = Quiz.find(params[:quiz_id])
  end

  def set_pregunta
    @pregunta = @quiz.preguntas.find(params[:id])
  end

  def pregunta_params
    params.require(:quiz_pregunta).permit(:contenido, :tipo, :puntaje, :orden)
  end

  def verificar_profesor
    unless current_usuario.profesor? && @quiz.usuario == current_usuario
      redirect_to quizzes_path, alert: 'No tienes permiso para realizar esta acción.'
    end
  end
end