# app/controllers/intentos_quiz_controller.rb
class IntentosQuizController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_quiz
  before_action :set_intento, only: [:show, :update, :finalizar]
  before_action :verificar_estudiante, except: [:index]

  def create
    if puede_iniciar_intento?
      @intento = @quiz.intentos.create!(
        usuario: current_usuario,
        estado: :en_progreso,
        iniciado_en: Time.current
      )
      redirect_to quiz_intento_path(@quiz, @intento)
    else
      redirect_to quiz_path(@quiz), alert: 'No puedes iniciar este quiz.'
    end
  end

  def show
    @preguntas = @quiz.preguntas.includes(:opciones)
    @respuestas = @intento.respuestas.index_by(&:pregunta_id)
  end

  def update
    @respuesta = @intento.respuestas.find_or_initialize_by(pregunta_id: params[:pregunta_id])
    
    if @respuesta.update(respuesta_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to quiz_intento_path(@quiz, @intento) }
      end
    else
      render :show
    end
  end

  def finalizar
    if @intento.update(estado: :completado, finalizado_en: Time.current)
      calcular_puntaje
      redirect_to resultados_quiz_intento_path(@quiz, @intento)
    else
      redirect_to quiz_intento_path(@quiz, @intento), alert: 'Error al finalizar el intento.'
    end
  end

  private

  def set_quiz
    @quiz = Quiz.find(params[:quiz_id])
  end

  def set_intento
    @intento = @quiz.intentos.find(params[:id])
  end

  def respuesta_params
    params.require(:respuesta_quiz).permit(:opcion_id, :respuesta_texto)
  end

  def verificar_estudiante
    unless @quiz.curso.estudiantes.include?(current_usuario)
      redirect_to quizzes_path, alert: 'No tienes acceso a este quiz.'
    end
  end

  def puede_iniciar_intento?
    intentos_actuales = @quiz.intentos.where(usuario: current_usuario).count
    @quiz.publicado? && 
    intentos_actuales < @quiz.intentos_permitidos &&
    Time.current.between?(@quiz.fecha_inicio, @quiz.fecha_fin)
  end

  def calcular_puntaje
    total_puntos = 0
    total_posible = 0

    @intento.respuestas.includes(:pregunta, :opcion).each do |respuesta|
      pregunta = respuesta.pregunta
      total_posible += pregunta.puntaje

      case pregunta.tipo
      when 'opcion_multiple'
        if respuesta.opcion&.es_correcta?
          total_puntos += pregunta.puntaje
          respuesta.update(es_correcta: true, puntaje_obtenido: pregunta.puntaje)
        end
      when 'respuesta_corta'
        # Implementar lógica para respuestas cortas
      end
    end

    porcentaje = (total_puntos / total_posible.to_f) * 100
    @intento.update(puntaje_total: porcentaje)
  end
end