class IntentosQuizController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_quiz
  before_action :set_intento, only: %i[show update finalizar resultados]
  before_action :verificar_estudiante, except: [:index]
  before_action :verificar_elegibilidad, only: [:create]
  before_action :verificar_intento_en_progreso, only: %i[show update]
  before_action :verificar_intento_completado, only: [:resultados]

  def index
    @intentos = current_usuario.intentos_quiz.where(quiz_id: @quiz.id)
                               .includes(:respuestas)
                               .order(created_at: :desc)
  end

  def create
    @intento = @quiz.intentos.new(
      usuario: current_usuario,
      estado: :en_progreso,
      iniciado_en: Time.current,
      numero_intento: @quiz.intentos.where(usuario: current_usuario).count + 1
    )

    if @intento.save
      redirect_to quiz_intento_path(@quiz, @intento)
    else
      redirect_to quiz_path(@quiz), alert: 'No se pudo iniciar el intento. Por favor intenta nuevamente.'
    end
  end

  def show
    @preguntas = @quiz.preguntas.includes(:opciones).order(orden: :asc)
    @respuestas = @intento.respuestas.index_by(&:pregunta_id)

    # Si se especifica una pregunta, muestra solo esa
    @current_pregunta = if params[:pregunta_id].present?
                          @preguntas.find_by(id: params[:pregunta_id])
                        else
                          # Por defecto, mostrar la primera pregunta
                          @preguntas.first
                        end

    # Calcular progreso
    @respondidas = @respuestas.keys.count
    @total_preguntas = @preguntas.count
    @progreso = (@respondidas.to_f / @total_preguntas * 100).round

    # Tiempo transcurrido y restante
    @tiempo_transcurrido = Time.current - @intento.iniciado_en
    @tiempo_restante = (@quiz.tiempo_limite * 60) - @tiempo_transcurrido

    # Si se agotó el tiempo, finalizar automáticamente
    return unless @tiempo_restante <= 0

    finalizar
    nil
  end

  def update
    @respuesta = @intento.respuestas.find_or_initialize_by(pregunta_id: params[:pregunta_id])

    if params[:respuesta_quiz][:opcion_id].present?
      # Para preguntas de opción múltiple
      @respuesta.opcion_id = params[:respuesta_quiz][:opcion_id]
      @respuesta.respuesta_texto = nil
    else
      # Para preguntas de respuesta corta
      @respuesta.opcion_id = nil
      @respuesta.respuesta_texto = params[:respuesta_quiz][:respuesta_texto]
    end

    if @respuesta.save
      respond_to do |format|
        format.html do
          if params[:siguiente_pregunta_id].present?
            redirect_to quiz_intento_path(@quiz, @intento, pregunta_id: params[:siguiente_pregunta_id])
          else
            redirect_to quiz_intento_path(@quiz, @intento)
          end
        end
        format.json { render json: { success: true, pregunta_id: @respuesta.pregunta_id } }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { render :show }
        format.json { render json: { success: false, errors: @respuesta.errors.full_messages } }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("pregunta_#{params[:pregunta_id]}", partial: 'intentos_quiz/pregunta',
                                                                                        locals: { pregunta: @respuesta.pregunta, intento: @intento, respuesta: @respuesta })
        end
      end
    end
  end

  def finalizar
    # No finalizar si ya estaba completado
    return redirect_to resultados_quiz_intento_path(@quiz, @intento) if @intento.completado?

    @intento.update(
      estado: :completado,
      finalizado_en: Time.current
    )

    # Calcular resultados
    calcular_resultados

    redirect_to resultados_quiz_intento_path(@quiz, @intento)
  end

  def resultados
    @preguntas = @quiz.preguntas.includes(:opciones).order(orden: :asc)
    @respuestas = @intento.respuestas.includes(:opcion).index_by(&:pregunta_id)

    # Estadísticas del intento
    @tiempo_total = @intento.finalizado_en - @intento.iniciado_en
    @preguntas_correctas = @intento.respuestas.where(es_correcta: true).count
    @porcentaje_correcto = (@preguntas_correctas.to_f / @preguntas.count * 100).round(1)

    # Comparación con otros intentos
    @promedio_curso = @quiz.intentos.completado.average(:puntaje_total).to_f.round(1)
    @posicion_ranking = @quiz.intentos.completado
                             .where('puntaje_total > ?', @intento.puntaje_total)
                             .count + 1
    @total_intentos = @quiz.intentos.completado.count
  end

  private

  def set_quiz
    @quiz = Quiz.find(params[:quiz_id])
  end

  def set_intento
    @intento = @quiz.intentos.find(params[:id])

    # Verificar que el intento pertenece al usuario actual
    return if @intento.usuario == current_usuario

    redirect_to quiz_path(@quiz), alert: 'No tienes acceso a este intento.'
  end

  def verificar_estudiante
    return if @quiz.curso.estudiantes.include?(current_usuario)

    redirect_to quizzes_path, alert: 'No tienes acceso a este quiz.'
  end

  def verificar_elegibilidad
    # Verificar estado del quiz
    unless @quiz.publicado?
      redirect_to quiz_path(@quiz), alert: 'Este quiz no está disponible actualmente.'
      return
    end

    # Verificar fechas
    unless Time.current.between?(@quiz.fecha_inicio, @quiz.fecha_fin)
      redirect_to quiz_path(@quiz), alert: 'Este quiz no está disponible en este momento.'
      return
    end

    # Verificar intentos disponibles
    intentos_realizados = @quiz.intentos.where(usuario: current_usuario).count
    if intentos_realizados >= @quiz.intentos_permitidos
      redirect_to quiz_path(@quiz), alert: 'Ya has alcanzado el número máximo de intentos permitidos.'
      return
    end

    # Verificar si ya tiene un intento en progreso
    return unless @quiz.intentos.en_progreso.where(usuario: current_usuario).exists?

    intento = @quiz.intentos.en_progreso.where(usuario: current_usuario).first
    redirect_to quiz_intento_path(@quiz, intento), notice: 'Ya tienes un intento en progreso.'
    nil
  end

  def verificar_intento_en_progreso
    return if @intento.en_progreso?

    redirect_to resultados_quiz_intento_path(@quiz, @intento), alert: 'Este intento ya ha sido finalizado.'
  end

  def verificar_intento_completado
    return if @intento.completado?

    redirect_to quiz_intento_path(@quiz, @intento), alert: 'Debes finalizar el intento para ver los resultados.'
  end

  def calcular_resultados
    total_puntos = 0
    total_posible = 0

    # Para cada pregunta del quiz
    @quiz.preguntas.each do |pregunta|
      respuesta = @intento.respuestas.find_by(pregunta_id: pregunta.id)
      total_posible += pregunta.puntaje

      # Si no hay respuesta, se considera incorrecta
      next unless respuesta

      # Verificar si es correcta según el tipo de pregunta
      es_correcta = case pregunta.tipo
                    when 'opcion_multiple', 'verdadero_falso'
                      respuesta.opcion&.es_correcta?
                    when 'respuesta_corta'
                      verificar_respuesta_corta(pregunta, respuesta.respuesta_texto)
                    else
                      false
                    end

      if es_correcta
        respuesta.update(es_correcta: true, puntaje_obtenido: pregunta.puntaje)
        total_puntos += pregunta.puntaje
      else
        respuesta.update(es_correcta: false, puntaje_obtenido: 0)
      end
    end

    # Calcular porcentaje
    porcentaje = total_posible.zero? ? 0 : ((total_puntos / total_posible.to_f) * 100).round(1)
    @intento.update(puntaje_total: porcentaje)
  end

  def verificar_respuesta_corta(pregunta, respuesta_texto)
    return false if respuesta_texto.blank?

    # Implementación simple: considerar correcta si coincide exactamente con la respuesta esperada
    # Aquí se podría implementar comparación más sofisticada (ej. fuzzy matching, palabras clave, etc.)
    respuesta_correcta = pregunta.respuesta_correcta.to_s.downcase.strip
    respuesta_usuario = respuesta_texto.to_s.downcase.strip

    respuesta_usuario == respuesta_correcta
  end
end
