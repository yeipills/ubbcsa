class QuizOpcionesController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_pregunta
  before_action :set_opcion, only: %i[edit update destroy]
  before_action :verificar_profesor

  def index
    @opciones = @pregunta.opciones.order(orden: :asc)

    respond_to do |format|
      format.html
      format.json { render json: @opciones }
    end
  end

  def new
    @opcion = @pregunta.opciones.build
    # Calcular orden automáticamente
    ultimo_orden = @pregunta.opciones.maximum(:orden) || 0
    @opcion.orden = ultimo_orden + 1
  end

  def create
    @opcion = @pregunta.opciones.build(opcion_params)

    if @opcion.save
      redirect_to quiz_pregunta_path(@pregunta.quiz, @pregunta), notice: 'Opción creada exitosamente.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    # Si se marca como correcta y es pregunta de opción única, desmarcar las otras
    if opcion_params[:es_correcta] == '1' && @pregunta.opcion_multiple?
      @pregunta.opciones.where.not(id: @opcion.id).update_all(es_correcta: false)
    end

    if @opcion.update(opcion_params)
      redirect_to quiz_pregunta_path(@pregunta.quiz, @pregunta), notice: 'Opción actualizada exitosamente.'
    else
      render :edit
    end
  end

  def destroy
    @opcion.destroy
    redirect_to quiz_pregunta_path(@pregunta.quiz, @pregunta), notice: 'Opción eliminada exitosamente.'
  end

  def reordenar
    params[:orden].each do |id, position|
      QuizOpcion.where(id: id).update_all(orden: position)
    end

    head :ok
  end

  private

  def set_pregunta
    @pregunta = QuizPregunta.find(params[:pregunta_id])
  end

  def set_opcion
    @opcion = @pregunta.opciones.find(params[:id])
  end

  def opcion_params
    params.require(:quiz_opcion).permit(
      :contenido,
      :es_correcta,
      :orden,
      :retroalimentacion,
      :imagen
    )
  end

  def verificar_profesor
    return if current_usuario.profesor? && @pregunta.quiz.curso.profesor_id == current_usuario.id

    redirect_to quizzes_path, alert: 'No tienes permiso para realizar esta acción.'
  end
end
