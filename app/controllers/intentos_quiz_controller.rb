class IntentosQuizController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_quiz
  before_action :set_intento, only: %i[show update finalizar resultados]
  before_action :verificar_estudiante, except: [:index]
  before_action :verificar_elegibilidad, only: [:create]
  before_action :verificar_intento_en_progreso, only: %i[show update]
  before_action :verificar_intento_completado, only: [:resultados]

  # Lista todos los intentos del usuario para un quiz específico
  def index
    @intentos = current_usuario.intentos_quiz.where(quiz_id: @quiz.id)
                               .includes(:respuestas)
                               .order(created_at: :desc)

    # Estadísticas básicas para el usuario
    @mejor_intento = @intentos.completado.order(puntaje_total: :desc).first
    @intentos_realizados = @intentos.count
    @intentos_completados = @intentos.completado.count
    @intentos_disponibles = [@quiz.intentos_permitidos - @intentos_realizados, 0].max

    respond_to do |format|
      format.html
      format.json { render json: @intentos }
    end
  end

  # Crea un nuevo intento de quiz
  def create
    @intento = @quiz.intentos.new(
      usuario: current_usuario,
      estado: :en_progreso,
      iniciado_en: Time.current,
      numero_intento: @quiz.intentos.where(usuario: current_usuario).count + 1
    )

    if @intento.save
      # Registrar evento de inicio de intento para estadísticas
      registrar_evento_intento('iniciar', @intento)

      redirect_to quiz_intento_path(@quiz, @intento)
    else
      redirect_to quiz_path(@quiz), alert: 'No se pudo iniciar el intento. Por favor intenta nuevamente.'
    end
  end

  # Muestra un intento en progreso con las preguntas
  def show
    # Obtener todas las preguntas con sus opciones, ordenadas por orden
    @preguntas = @quiz.preguntas.includes(:opciones).order(orden: :asc)

    # Mapear las respuestas del usuario para acceso rápido
    @respuestas = @intento.respuestas.index_by(&:pregunta_id)

    # Si se especifica una pregunta, muestra solo esa
    @current_pregunta = if params[:pregunta_id].present?
                          @preguntas.find_by(id: params[:pregunta_id])
                        else
                          # Por defecto, mostrar la primera pregunta sin responder o la primera
                          primera_sin_responder = @preguntas.find { |p| !@respuestas[p.id] }
                          primera_sin_responder || @preguntas.first
                        end

    # Calcular progreso y tiempo
    calcular_progreso_y_tiempo

    # Si se agotó el tiempo, finalizar automáticamente
    if @tiempo_restante <= 0 && @intento.en_progreso?
      finalizar
      return
    end

    # Ajustar el título de la página según la pregunta actual
    @page_title = "Pregunta #{@current_pregunta&.orden} - #{@quiz.titulo}"

    respond_to do |format|
      format.html
      format.turbo_stream # Para actualizaciones parciales con Turbo
      format.json do
        render json: {
          intento: @intento,
          pregunta_actual: @current_pregunta,
          progreso: @progreso,
          tiempo_restante: @tiempo_restante
        }
      end
    end
  end

  # Actualiza una respuesta del intento
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
      registrar_evento_respuesta(@respuesta)

      respond_to do |format|
        format.html do
          if params[:siguiente_pregunta_id].present?
            redirect_to quiz_intento_path(@quiz, @intento, pregunta_id: params[:siguiente_pregunta_id])
          else
            redirect_to quiz_intento_path(@quiz, @intento)
          end
        end
        format.json { render json: { success: true, pregunta_id: @respuesta.pregunta_id } }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("respuesta_#{@respuesta.pregunta_id}",
                                 partial: 'respuesta_badge',
                                 locals: { respuesta: @respuesta }),
            turbo_stream.replace('progreso',
                                 partial: 'progreso',
                                 locals: { progreso: calcular_progreso, total_preguntas: @quiz.preguntas.count })
          ]
        end
      end
    else
      respond_to do |format|
        format.html { render :show }
        format.json { render json: { success: false, errors: @respuesta.errors.full_messages } }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "pregunta_form_#{params[:pregunta_id]}",
            partial: 'pregunta_form',
            locals: { pregunta: @respuesta.pregunta, intento: @intento, respuesta: @respuesta }
          )
        end
      end
    end
  end

  # Finaliza un intento y calcula resultados
  def finalizar
    # No finalizar si ya estaba completado
    return redirect_to resultados_quiz_intento_path(@quiz, @intento) if @intento.completado?

    # Marcar como completado y guardar tiempo de finalización
    @intento.update(
      estado: :completado,
      finalizado_en: Time.current
    )

    # Calcular resultados (puntaje y respuestas correctas)
    calcular_resultados

    # Registrar evento de finalización
    registrar_evento_intento('finalizar', @intento)

    redirect_to resultados_quiz_intento_path(@quiz, @intento)
  end

  # Muestra los resultados de un intento completado
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

    # Datos para gráficos
    preparar_datos_graficos

    # Título de la página
    @page_title = "Resultados - #{@quiz.titulo}"
  end

  private

  def set_quiz
    @quiz = Quiz.find(params[:quiz_id])
  end

  def set_intento
    @intento = @quiz.intentos.find(params[:id])

    # Verificar que el intento pertenece al usuario actual
    return if @intento.usuario == current_usuario || current_usuario.profesor?

    redirect_to quiz_path(@quiz), alert: 'No tienes acceso a este intento.'
  end

  def verificar_estudiante
    return if @quiz.curso.estudiantes.include?(current_usuario) || current_usuario.profesor?

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

  def calcular_progreso_y_tiempo
    # Calcular progreso
    @respondidas = @respuestas.keys.count
    @total_preguntas = @preguntas.count
    @progreso = calcular_progreso

    # Calcular tiempo transcurrido y restante
    @tiempo_transcurrido = (Time.current - @intento.iniciado_en).to_i
    @tiempo_restante = (@quiz.tiempo_limite * 60) - @tiempo_transcurrido
    @tiempo_restante = 0 if @tiempo_restante < 0
  end

  def calcular_progreso
    total_preguntas = @quiz.preguntas.count
    return 0 if total_preguntas.zero?

    preguntas_respondidas = @intento.respuestas.count
    (preguntas_respondidas.to_f / total_preguntas * 100).round
  end

  def calcular_resultados
    total_puntos = 0
    total_posible = 0

    # Para cada pregunta del quiz
    @quiz.preguntas.each do |pregunta|
      total_posible += pregunta.puntaje

      # Buscar respuesta del usuario
      respuesta = @intento.respuestas.find_by(pregunta_id: pregunta.id)

      # Si no hay respuesta, se considera incorrecta
      next unless respuesta

      # Utilizar el servicio para evaluar la respuesta
      resultado = RespuestaEvaluatorService.evaluar(respuesta)

      # Sumar puntos al total
      total_puntos += resultado[:puntaje]
    end

    # Calcular porcentaje
    porcentaje = total_posible.zero? ? 0 : ((total_puntos / total_posible.to_f) * 100).round(1)
    @intento.update(puntaje_total: porcentaje)
  end

  def preparar_datos_graficos
    # Estructurar datos para gráficos
    @datos_grafico = {
      rangos: %w[0-20 21-40 41-60 61-80 81-100],
      valores: Array.new(5, 0) # Inicializar con ceros
    }

    # Agrupar puntajes en rangos
    @quiz.intentos.completado.each do |intento|
      rango_index = case intento.puntaje_total
                    when 0..20 then 0
                    when 21..40 then 1
                    when 41..60 then 2
                    when 61..80 then 3
                    else 4
                    end
      @datos_grafico[:valores][rango_index] += 1
    end

    # Identificar preguntas con más errores
    @respuestas_problematicas = {}
    @quiz.preguntas.each do |pregunta|
      total_respuestas = @quiz.intentos.completado.joins(:respuestas).where(respuestas_quiz: { pregunta_id: pregunta.id }).count
      next if total_respuestas == 0

      respuestas_incorrectas = @quiz.intentos.completado.joins(:respuestas).where(respuestas_quiz: {
                                                                                    pregunta_id: pregunta.id, es_correcta: false
                                                                                  }).count
      tasa_error = (respuestas_incorrectas.to_f / total_respuestas) * 100

      @respuestas_problematicas[pregunta] = tasa_error if tasa_error > 50 # Solo mostrar las más problemáticas
    end
    @respuestas_problematicas = @respuestas_problematicas.sort_by { |_, v| -v }.take(3)
  end

  def registrar_evento_intento(accion, intento)
    # Este método podría registrar eventos para análisis y estadísticas
    Rails.logger.info("[QUIZ_EVENT] Usuario #{current_usuario.id} #{accion} intento #{intento.id} para quiz #{@quiz.id}")

    # Aquí podría registrarse en una tabla de eventos o enviarse a un servicio de análisis
  end

  def registrar_evento_respuesta(respuesta)
    Rails.logger.info("[QUIZ_EVENT] Usuario #{current_usuario.id} respondió pregunta #{respuesta.pregunta_id} en intento #{respuesta.intento_quiz_id}")
  end
end
