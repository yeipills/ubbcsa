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
    @quiz = @curso.quizzes.build
    @laboratorios = @curso.laboratorios
  end

  def create
    @quiz = @curso.quizzes.build(quiz_params)
    @quiz.usuario = current_usuario

    if @quiz.save
      redirect_to quiz_path(@quiz), notice: 'Quiz creado exitosamente.'
    else
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
      :peso_calificacion
    )
  end

  def verify_role_access
    return if current_usuario.profesor? || current_usuario.admin?

    redirect_to quizzes_path, alert: 'No tienes permiso para realizar esta acción'
  end
end
