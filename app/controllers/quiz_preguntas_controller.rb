# app/controllers/quiz_preguntas_controller.rb
class QuizPreguntasController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_quiz, except: [:edit, :update, :destroy, :delete]
  before_action :set_pregunta, only: %i[edit update destroy delete] # Agregado :delete al callback
  before_action :verificar_profesor

  def index
    @preguntas = @quiz.preguntas
  end

  def new
    @pregunta = @quiz.preguntas.build
    # Definir orden por defecto (siguiente orden disponible)
    ultimo_orden = @quiz.preguntas.maximum(:orden)
    @pregunta.orden = ultimo_orden ? ultimo_orden + 1 : 1
    
    # Asignar un tipo por defecto para evitar error de tipo nil
    @pregunta.tipo = 'opcion_multiple' unless @pregunta.tipo.present?
    
    # Conteo de preguntas y datos para la vista
    @preguntas_count = @quiz.preguntas.count
    @puntaje_total = @quiz.preguntas.sum(:puntaje)
    @tipos_preguntas = @quiz.preguntas.select('DISTINCT tipo').count
  end

  def create
    @pregunta = @quiz.preguntas.build(pregunta_params)

    if @pregunta.save
      @pregunta.imagen.purge if params[:quiz_pregunta][:remove_imagen] == '1' && @pregunta.imagen.attached?
      
      # Para preguntas de emparejamiento, procesar los pares después de guardar
      if @pregunta.emparejamiento?
        procesar_pares_emparejamiento(@pregunta, params[:quiz_pregunta][:opciones_attributes])
      end

      redirect_to quiz_path(@quiz), notice: 'Pregunta creada exitosamente.'
    else
      # Conteo de preguntas y datos para la vista en caso de error
      @preguntas_count = @quiz.preguntas.count
      @puntaje_total = @quiz.preguntas.sum(:puntaje)
      @tipos_preguntas = @quiz.preguntas.select('DISTINCT tipo').count
      
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Conteo de preguntas y datos para la vista
    @preguntas_count = @quiz.preguntas.count
    @puntaje_total = @quiz.preguntas.sum(:puntaje)
    @tipos_preguntas = @quiz.preguntas.select('DISTINCT tipo').count
  end

  def update
    if @pregunta.update(pregunta_params)
      @pregunta.imagen.purge if params[:quiz_pregunta][:remove_imagen] == '1' && @pregunta.imagen.attached?
      
      # Para preguntas de emparejamiento, procesar los pares después de guardar
      if @pregunta.emparejamiento?
        procesar_pares_emparejamiento(@pregunta, params[:quiz_pregunta][:opciones_attributes])
      end
      
      redirect_to quiz_path(@quiz), notice: 'Pregunta actualizada exitosamente.'
    else
      # Datos para la vista en caso de error
      @preguntas_count = @quiz.preguntas.count
      @puntaje_total = @quiz.preguntas.sum(:puntaje)
      @tipos_preguntas = @quiz.preguntas.select('DISTINCT tipo').count
      
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @pregunta.destroy
    redirect_to quiz_path(@quiz || @pregunta.quiz), notice: 'Pregunta eliminada exitosamente.'
  end
  
  # Método para la ruta personalizada de eliminación
  def delete
    @pregunta.destroy
    redirect_to quiz_path(@quiz || @pregunta.quiz), notice: 'Pregunta eliminada exitosamente.'
  end
  
  # Método para duplicar una pregunta existente
  def duplicar
    pregunta_original = QuizPregunta.find(params[:id])
    @quiz = pregunta_original.quiz
    
    # Verificar permisos
    unless current_usuario.profesor? && @quiz.curso.profesor_id == current_usuario.id
      return redirect_to quizzes_path, alert: 'No tienes permiso para realizar esta acción.'
    end
    
    # Duplicar la pregunta
    ActiveRecord::Base.transaction do
      # Crear nueva pregunta con los mismos atributos
      nueva_pregunta = @quiz.preguntas.create!(
        contenido: "#{pregunta_original.contenido} (copia)",
        tipo: pregunta_original.tipo,
        puntaje: pregunta_original.puntaje,
        retroalimentacion: pregunta_original.retroalimentacion,
        respuesta_correcta: pregunta_original.respuesta_correcta,
        # Asignar el siguiente orden disponible
        orden: (@quiz.preguntas.maximum(:orden) || 0) + 1
      )
      
      # Duplicar opciones
      if pregunta_original.requiere_opciones?
        pregunta_original.opciones.each do |opcion_original|
          nueva_opcion = nueva_pregunta.opciones.create!(
            contenido: opcion_original.contenido,
            es_correcta: opcion_original.es_correcta,
            orden: opcion_original.orden,
            es_termino: opcion_original.es_termino,
            par_relacionado: opcion_original.par_relacionado
          )
        end
      end
      
      # Duplicar imagen si existe
      if pregunta_original.imagen.attached?
        nueva_pregunta.imagen.attach(
          io: StringIO.new(pregunta_original.imagen.download),
          filename: pregunta_original.imagen.filename.to_s,
          content_type: pregunta_original.imagen.content_type
        )
      end
      
      # Procesar relaciones de emparejamiento después de duplicar
      if nueva_pregunta.emparejamiento?
        nueva_pregunta.terminos.each_with_index do |termino, index|
          definicion = nueva_pregunta.definiciones[index]
          next unless definicion
          
          termino.update(par_relacionado: { id: definicion.id, tipo: "definicion" })
        end
      end
      
      redirect_to edit_quiz_pregunta_path(@quiz, nueva_pregunta), notice: 'Pregunta duplicada exitosamente. Puedes editarla ahora.'
    end
    
  rescue ActiveRecord::RecordInvalid => e
    redirect_to quiz_path(@quiz), alert: "Error al duplicar la pregunta: #{e.message}"
  end
  
  # Método para mostrar una vista previa de la pregunta
  def preview
    @pregunta = QuizPregunta.find(params[:id])
    @quiz = @pregunta.quiz
    
    # Verificar permisos
    unless current_usuario.profesor? && @quiz.curso.profesor_id == current_usuario.id
      return render plain: "No autorizado", status: :unauthorized
    end
    
    # Renderizar una vista parcial de la pregunta
    render layout: false, partial: "intentos_quiz/pregunta", locals: {
      pregunta: @pregunta,
      intento: nil, # No hay intento activo en vista previa
      index: 1,     # Índice fijo para la vista previa
      solo_lectura: true # Modo de solo lectura para vista previa
    }
  end

  def reordenar
    @quiz = Quiz.find(params[:quiz_id])

    # Verificar permisos
    unless current_usuario.profesor? && @quiz.curso.profesor_id == current_usuario.id
      return render json: { error: 'No autorizado' }, status: :unauthorized
    end

    # Actualizar orden
    ActiveRecord::Base.transaction do
      params[:orden].each do |id, posicion|
        QuizPregunta.where(id: id).update_all(orden: posicion)
      end
    end

    # Responder con éxito
    render json: { status: 'success' }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_quiz
    @quiz = Quiz.find(params[:quiz_id])
  end

  def set_pregunta
    if @quiz
      @pregunta = @quiz.preguntas.find(params[:id])
    else
      @pregunta = QuizPregunta.find(params[:id])
      @quiz = @pregunta.quiz
    end
  end
  
  # Procesa las relaciones entre términos y definiciones en preguntas de emparejamiento
  def procesar_pares_emparejamiento(pregunta, opciones_params)
    return unless pregunta.emparejamiento? && opciones_params.present?
    
    # Primero, obtener todos los términos y definiciones
    terminos = pregunta.opciones.where(es_termino: true)
    definiciones = pregunta.opciones.where(es_termino: false)
    
    # Procesar cada par
    opciones_params.each do |_index, opcion_params|
      next unless opcion_params[:es_termino].to_s == "true" && opcion_params[:par_relacionado].present?
      
      begin
        # Obtener el término
        termino_id = opcion_params[:id]
        next unless termino_id.present?
        
        termino = QuizOpcion.find(termino_id)
        next unless termino && termino.pregunta_id == pregunta.id
        
        # Procesar par relacionado
        par_info = JSON.parse(opcion_params[:par_relacionado]) rescue nil
        next unless par_info && par_info["id"].present?
        
        # Si el ID del par es un dummy (nuevo), buscar por posición
        if par_info["id"].to_s.start_with?("dummy_")
          orden = par_info["id"].to_s.sub("dummy_", "").to_i
          definicion = definiciones.find_by(orden: orden)
          
          if definicion
            # Actualizar relación con ID real
            termino.update_column(:par_relacionado, { id: definicion.id, tipo: "definicion" })
          end
        else
          # Verificar que el par sea válido
          definicion_id = par_info["id"].to_i
          definicion = QuizOpcion.find_by(id: definicion_id)
          
          if definicion && definicion.pregunta_id == pregunta.id && !definicion.es_termino
            termino.update_column(:par_relacionado, { id: definicion.id, tipo: "definicion" })
          end
        end
      rescue => e
        Rails.logger.error("Error procesando par de emparejamiento: #{e.message}")
      end
    end
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
      :remove_imagen,
      opciones_attributes: [:id, :contenido, :es_correcta, :orden, :es_termino, :par_relacionado, :_destroy]
    )
  end

  def verificar_profesor
    quiz_actual = @quiz || (@pregunta&.quiz if @pregunta)
    
    return if current_usuario.profesor? && quiz_actual&.curso&.profesor_id == current_usuario.id

    redirect_to quizzes_path, alert: 'No tienes permiso para realizar esta acción.'
  end
end
