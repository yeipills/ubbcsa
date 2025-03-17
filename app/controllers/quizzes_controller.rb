class QuizzesController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_curso, only: %i[new create]
  before_action :set_quiz, only: %i[show edit update destroy publicar despublicar duplicate estadisticas]
  before_action :verify_role_access, only: %i[new create edit update destroy publicar despublicar]

  def index
    @quizzes = if current_usuario.profesor?
                 Quiz.includes(:curso, :laboratorio)
                     .where(curso_id: current_usuario.cursos_como_profesor.pluck(:id))
                     .order(created_at: :desc)
               else
                 Quiz.activos
                     .includes(:curso, :laboratorio)
                     .where(curso_id: current_usuario.cursos.pluck(:id))
                     .where('fecha_inicio <= ? AND fecha_fin >= ?', Time.current, Time.current)
                     .order(fecha_fin: :asc)
               end

    # Filtrado opcional
    @quizzes = @quizzes.where(estado: params[:estado]) if params[:estado].present?

    return unless params[:curso_id].present?

    @quizzes = @quizzes.where(curso_id: params[:curso_id])
  end

  def show
    @preguntas = @quiz.preguntas.includes(:opciones).order(orden: :asc)

    # Si es estudiante, preparar o buscar intento existente
    return if current_usuario.profesor?

    @intento = current_usuario.intentos_quiz.find_or_initialize_by(quiz: @quiz, estado: :en_progreso)
    @intentos_anteriores = current_usuario.intentos_quiz.where(quiz: @quiz,
                                                               estado: :completado).order(created_at: :desc)
  end

  def new
    if @curso.nil?
      redirect_to cursos_path, alert: 'Debe seleccionar un curso para crear un quiz'
      return
    end
    
    # Verificar que el curso tenga laboratorios asociados
    if @curso.laboratorios.empty?
      redirect_to curso_path(@curso), alert: 'El curso no tiene laboratorios asociados. Debe crear al menos un laboratorio antes de poder crear un quiz.'
      return
    end
    
    @quiz = @curso.quizzes.build
    # Set default dates for the quiz
    @quiz.fecha_inicio = Time.current.beginning_of_hour + 1.hour
    @quiz.fecha_fin = Time.current.beginning_of_hour + 1.day + 1.hour
    @laboratorios = @curso.laboratorios
  end

  def create
    # Verificar nuevamente que el curso tenga laboratorios asociados
    if @curso.laboratorios.empty?
      redirect_to curso_path(@curso), alert: 'El curso no tiene laboratorios asociados. Debe crear al menos un laboratorio antes de poder crear un quiz.'
      return
    end
    
    @quiz = @curso.quizzes.build(quiz_params)
    @quiz.usuario = current_usuario
    
    # Set default dates if not provided in the params
    if params[:quiz][:fecha_inicio].blank? || params[:quiz][:fecha_fin].blank?
      @quiz.fecha_inicio = Time.current.beginning_of_hour + 1.hour if @quiz.fecha_inicio.nil?
      @quiz.fecha_fin = Time.current.beginning_of_hour + 1.day + 1.hour if @quiz.fecha_fin.nil?
    end
    
    # Verificar que se haya seleccionado un laboratorio
    if params[:quiz][:laboratorio_id].blank?
      flash.now[:alert] = 'Debe seleccionar un laboratorio para el quiz'
      @laboratorios = @curso.laboratorios
      render :new, status: :unprocessable_entity
      return
    end

    begin
      if @quiz.save
        redirect_to quiz_path(@quiz), notice: 'Quiz creado exitosamente. Ahora puedes agregar preguntas.'
      else
        @laboratorios = @curso.laboratorios
        render :new, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotUnique => e
      @quiz.errors.add(:titulo, "ya existe un quiz con este título para el mismo curso y laboratorio")
      @laboratorios = @curso.laboratorios
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @laboratorios = @quiz.curso.laboratorios
  end

  def update
    if @quiz.update(quiz_params)
      redirect_to quiz_path(@quiz), notice: 'Quiz actualizado exitosamente.'
    else
      @laboratorios = @quiz.curso.laboratorios
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @quiz.destroy
    redirect_to curso_quizzes_path(@quiz.curso), notice: 'Quiz eliminado exitosamente.'
  end

  def publicar
    return unless @quiz.borrador?

    if @quiz.update(estado: :publicado, fecha_publicacion: Time.current)
      # Asegurarse de que tenga un código de acceso generado
      @quiz.generar_codigo_acceso if @quiz.codigo_acceso.blank?
      
      # Notificar a los estudiantes
      QuizNotificationJob.perform_later(@quiz.id)
      redirect_to @quiz, notice: 'Quiz publicado exitosamente. Los estudiantes han sido notificados.'
    else
      redirect_to @quiz, alert: 'Error al publicar el quiz.'
    end
  end

  def despublicar
    return unless @quiz.publicado?

    if @quiz.update(estado: :borrador)
      redirect_to @quiz, notice: 'Quiz despublicado exitosamente.'
    else
      redirect_to @quiz, alert: 'Error al despublicar el quiz.'
    end
  end

  def duplicate
    @original_quiz = Quiz.find(params[:id])
    authorize @original_quiz # Si usas Pundit

    ActiveRecord::Base.transaction do
      @quiz = @original_quiz.dup
      @quiz.titulo = "Copia de #{@original_quiz.titulo}"
      @quiz.fecha_inicio = nil
      @quiz.fecha_fin = nil
      @quiz.estado = :borrador
      @quiz.save!

      @original_quiz.preguntas.each do |pregunta_original|
        nueva_pregunta = pregunta_original.dup
        nueva_pregunta.quiz = @quiz
        nueva_pregunta.save!

        pregunta_original.opciones.each do |opcion_original|
          nueva_opcion = opcion_original.dup
          nueva_opcion.pregunta = nueva_pregunta
          nueva_opcion.save!
        end
      end
    end

    redirect_to edit_quiz_path(@quiz), notice: 'Quiz duplicado correctamente. Ahora puedes editarlo.'
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @original_quiz, alert: "Error al duplicar: #{e.message}"
  end
  
  # Método simplificado para gestionar preguntas
  def gestionar_preguntas
    @quiz = Quiz.find(params[:id])
    @preguntas = @quiz.preguntas.includes(:opciones).order(orden: :asc)
    
    # Redireccionar a la vista normal del quiz
    redirect_to quiz_path(@quiz), notice: "Esta funcionalidad ha sido simplificada temporalmente."
  end

  def estadisticas
    @intentos = @quiz.intentos
                     .includes(:usuario, respuestas: { pregunta: :opciones })
                     .where(estado: :completado)
                     .order(created_at: :desc)
    @puntaje_promedio = @intentos.average(:puntaje_total)
    @tiempo_promedio = @intentos.average('EXTRACT(EPOCH FROM (finalizado_en - iniciado_en))').to_i

    # Preguntas con más errores
    @preguntas_problematicas = @quiz.preguntas
                                    .joins(respuestas: :intento_quiz)
                                    .where(respuestas_quiz: { es_correcta: false })
                                    .group('quiz_preguntas.id')
                                    .select('quiz_preguntas.*, COUNT(*) as error_count')
                                    .order('error_count DESC')
                                    .limit(5)
  end

  def exportar_resultados
    @quiz = Quiz.find(params[:id])
    @intentos = @quiz.intentos.completado.includes(:usuario, :respuestas)
    formato = params[:formato] || 'csv'

    respond_to do |format|
      format.csv { enviar_csv(@quiz) }
      format.pdf { generar_pdf(@quiz) }
    end
  end

  private

  def enviar_csv(quiz)
    filename = "quiz_#{quiz.id}_resultados_#{Date.today.strftime('%Y%m%d')}.csv"
    send_data generar_csv(quiz), filename: filename, type: 'text/csv'
  end

  def generar_csv(quiz)
    # Implementación de generación de CSV
  end

  def generar_pdf(quiz)
    # Implementación con Prawn u otra gema PDF
  end

  def set_curso
    @curso = Curso.find(params[:curso_id]) if params[:curso_id]
  end

  def set_quiz
    @quiz = Quiz.find(params[:id])
  end

  def quiz_params
    params.require(:quiz).permit(
      :titulo,
      :descripcion,
      :laboratorio_id,
      :estado,
      :tiempo_limite,
      :intentos_permitidos,
      :fecha_inicio,
      :fecha_fin,
      :instrucciones,
      :mostrar_resultados_inmediatos,
      :peso_calificacion,
      :aleatorizar_preguntas,
      :aleatorizar_opciones,
      :codigo_acceso
    )
  end
  
  # Método eliminado para evitar conflictos

  def verify_role_access
    unless current_usuario.profesor? || current_usuario.admin?
      redirect_to quizzes_path, alert: 'No tienes permiso para realizar esta acción'
      return
    end
    
    # Para acciones que requieren verificación de propiedad de quiz
    if ['edit', 'update', 'destroy', 'publicar', 'despublicar'].include?(action_name) && @quiz.present?
      # Permitir a administradores hacer cualquier acción
      return if current_usuario.admin?
      
      # Verificar que el profesor sea dueño del curso al que pertenece el quiz
      unless current_usuario.profesor? && @quiz.curso.profesor_id == current_usuario.id
        redirect_to quiz_path(@quiz), alert: 'No tienes permiso para editar este quiz'
        return
      end
    end
  end
end
