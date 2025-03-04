# app/controllers/quiz_preguntas_controller.rb
class QuizPreguntasController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_quiz
  before_action :set_pregunta, only: %i[edit update destroy] # Eliminado :show del callback
  before_action :verificar_profesor

  def index
    @preguntas = @quiz.preguntas
  end

  def new
    @pregunta = @quiz.preguntas.build
    # Definir orden por defecto (siguiente orden disponible)
    ultimo_orden = @quiz.preguntas.maximum(:orden)
    @pregunta.orden = ultimo_orden ? ultimo_orden + 1 : 1
  end

  def create
    @pregunta = @quiz.preguntas.build(pregunta_params)

    if @pregunta.save
      @pregunta.imagen.purge if params[:quiz_pregunta][:remove_imagen] == '1' && @pregunta.imagen.attached?
      redirect_to quiz_path(@quiz), notice: 'Pregunta creada exitosamente.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @pregunta.update(pregunta_params)
      @pregunta.imagen.purge if params[:quiz_pregunta][:remove_imagen] == '1' && @pregunta.imagen.attached?
      redirect_to quiz_path(@quiz), notice: 'Pregunta actualizada exitosamente.'
    else
      render :edit, status: :unprocessable_entity
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
    params.require(:quiz_pregunta).permit(
      :contenido,
      :tipo,
      :puntaje,
      :orden,
      :retroalimentacion,
      :respuesta_correcta,
      :imagen,
      :remove_imagen
    )
  end

  def verificar_profesor
    return if current_usuario.profesor? && @quiz.curso.profesor_id == current_usuario.id

    redirect_to quizzes_path, alert: 'No tienes permiso para realizar esta acción.'
  end
end
