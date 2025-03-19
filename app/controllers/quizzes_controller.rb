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
    @quizzes = @quizzes.where(curso_id: params[:curso_id]) if params[:curso_id].present?
    
    # Búsqueda por texto
    if params[:query].present?
      query = "%#{params[:query]}%"
      @quizzes = @quizzes.where("titulo ILIKE ? OR descripcion ILIKE ?", query, query)
    end
    
    # Paginación manual si Kaminari no está cargado correctamente
    begin
      @quizzes = @quizzes.page(params[:page]).per(9)
    rescue NoMethodError => e
      # Solución alternativa: paginación manual
      @page = (params[:page] || 1).to_i
      @per_page = 9
      @total_count = @quizzes.count
      @quizzes = @quizzes.offset((@page - 1) * @per_page).limit(@per_page)
      
      # Proporcionar los métodos requeridos por la vista
      @quizzes.define_singleton_method(:total_count) { @total_count }
      @quizzes.define_singleton_method(:limit_value) { @per_page }
      @quizzes.define_singleton_method(:total_pages) { (@total_count / @per_page.to_f).ceil }
      @quizzes.define_singleton_method(:current_page) { @page }
    end
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
  
  # Método para gestionar preguntas
  def gestionar_preguntas
    @quiz = Quiz.find(params[:id])
    @preguntas = @quiz.preguntas.includes(:opciones).order(orden: :asc)
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
    require 'csv'
    
    # Obtener intentos completados para el quiz
    intentos = quiz.intentos.completado.includes(:usuario, respuestas: { pregunta: :opciones })
    
    CSV.generate(headers: true) do |csv|
      # Encabezados
      headers = ['Estudiante', 'Email', 'Fecha', 'Tiempo (min)', 'Puntaje (%)', 'Respuestas Correctas']
      
      # Agregar encabezados para cada pregunta
      preguntas = quiz.preguntas.order(orden: :asc)
      preguntas.each_with_index do |pregunta, index|
        headers << "P#{index + 1}: #{pregunta.enunciado.truncate(30)}"
      end
      
      csv << headers
      
      # Datos de cada intento
      intentos.each do |intento|
        row = []
        # Información básica del intento
        row << intento.usuario.nombre_completo
        row << intento.usuario.email
        row << I18n.l(intento.finalizado_en, format: :short) if intento.finalizado_en
        row << ((intento.finalizado_en - intento.iniciado_en) / 60.0).round(2) if intento.finalizado_en && intento.iniciado_en
        row << intento.puntaje_total
        correctas = intento.respuestas.where(es_correcta: true).count
        row << "#{correctas}/#{intento.respuestas.count}"
        
        # Respuestas específicas para cada pregunta
        preguntas.each do |pregunta|
          respuesta = intento.respuestas.find_by(pregunta_id: pregunta.id)
          if respuesta
            if pregunta.tipo == 'opcion_multiple' || pregunta.tipo == 'verdadero_falso'
              opcion = respuesta.opcion
              if opcion
                valor = opcion.texto.truncate(30)
                valor = "✓ #{valor}" if respuesta.es_correcta
                valor = "✗ #{valor}" unless respuesta.es_correcta
                row << valor
              else
                row << "Sin respuesta"
              end
            elsif pregunta.tipo == 'respuesta_corta'
              valor = respuesta.texto_respuesta.to_s.truncate(30)
              valor = "✓ #{valor}" if respuesta.es_correcta
              valor = "✗ #{valor}" unless respuesta.es_correcta
              row << valor
            elsif pregunta.tipo == 'emparejamiento'
              valor = respuesta.es_correcta ? "✓ Correcto" : "✗ Incorrecto" 
              row << valor
            else
              row << "N/A"
            end
          else
            row << "Sin respuesta"
          end
        end
        
        csv << row
      end
    end
  end

  def generar_pdf(quiz)
    require 'prawn'
    require 'prawn/table'
    
    # Verificar que Prawn está disponible
    begin
      pdf = Prawn::Document.new
      
      # Título y encabezado
      pdf.font_size(18) { pdf.text "Resultados del Quiz: #{quiz.titulo}", style: :bold }
      pdf.move_down 10
      pdf.font_size(12) { pdf.text "Curso: #{quiz.curso.nombre}" }
      pdf.font_size(12) { pdf.text "Fecha de exportación: #{I18n.l(Date.today, format: :long)}" }
      pdf.move_down 20
      
      # Información del quiz
      pdf.font_size(14) { pdf.text "Información del Quiz", style: :bold }
      pdf.move_down 5
      
      info = [
        ["Título", quiz.titulo],
        ["Descripción", quiz.descripcion.truncate(100)],
        ["Estado", quiz.estado_display],
        ["Fecha de inicio", I18n.l(quiz.fecha_inicio, format: :long)],
        ["Fecha de fin", I18n.l(quiz.fecha_fin, format: :long)],
        ["Tiempo límite", "#{quiz.tiempo_limite} minutos"],
        ["Intentos permitidos", quiz.intentos_permitidos.to_s],
        ["Preguntas", quiz.preguntas.count.to_s]
      ]
      
      pdf.table(info, width: pdf.bounds.width) do
        cells.padding = [5, 10]
        column(0).font_style = :bold
        column(0).width = 150
        cells.borders = []
        row(0..7).borders = [:bottom]
        row(0..7).border_color = "DDDDDD"
      end
      
      pdf.move_down 20
      
      # Estadísticas generales
      pdf.font_size(14) { pdf.text "Estadísticas", style: :bold }
      pdf.move_down 5
      
      intentos = quiz.intentos.completado
      estadisticas = [
        ["Total de intentos", intentos.count.to_s],
        ["Puntaje promedio", "#{quiz.puntaje_promedio.round(2)}%"],
        ["Tiempo promedio", "#{(quiz.tiempo_promedio_segundos / 60.0).round(2)} minutos"],
        ["Tasa de aprobación (>60%)", "#{quiz.tasa_aprobacion}%"]
      ]
      
      pdf.table(estadisticas, width: pdf.bounds.width) do
        cells.padding = [5, 10]
        column(0).font_style = :bold
        column(0).width = 150
        cells.borders = []
        row(0..3).borders = [:bottom]
        row(0..3).border_color = "DDDDDD"
      end
      
      pdf.move_down 20
      
      # Tabla de resultados por estudiante
      pdf.font_size(14) { pdf.text "Resultados por Estudiante", style: :bold }
      pdf.move_down 10
      
      if intentos.any?
        resultados_data = [["Estudiante", "Fecha", "Tiempo", "Puntaje", "Correctas"]]
        
        intentos.includes(:usuario).order('usuarios.nombre ASC').each do |intento|
          tiempo = intento.finalizado_en && intento.iniciado_en ? 
                  ((intento.finalizado_en - intento.iniciado_en) / 60.0).round(2) : "N/A"
          correctas = intento.respuestas.where(es_correcta: true).count
          total = intento.respuestas.count
          
          resultados_data << [
            intento.usuario.nombre_completo,
            I18n.l(intento.finalizado_en, format: :short),
            "#{tiempo} min",
            "#{intento.puntaje_total}%",
            "#{correctas}/#{total}"
          ]
        end
        
        pdf.table(resultados_data, width: pdf.bounds.width) do
          cells.padding = [5, 5]
          row(0).font_style = :bold
          row(0).background_color = "DDDDDD"
          cells.borders = [:left, :right, :top, :bottom]
        end
      else
        pdf.text "No hay intentos completados para este quiz.", style: :italic
      end
      
      # Preguntas problemáticas
      pdf.move_down 20
      pdf.font_size(14) { pdf.text "Preguntas con Mayor Dificultad", style: :bold }
      pdf.move_down 10
      
      problematicas = quiz.preguntas_dificiles(3)
      
      if problematicas.any?
        problematicas_data = [["Pregunta", "Tasa de Error (%)"]]
        
        problematicas.each do |pregunta, tasa|
          problematicas_data << [
            pregunta.enunciado.truncate(50),
            tasa.to_s
          ]
        end
        
        pdf.table(problematicas_data, width: pdf.bounds.width) do
          cells.padding = [5, 5]
          row(0).font_style = :bold
          row(0).background_color = "DDDDDD"
          cells.borders = [:left, :right, :top, :bottom]
        end
      else
        pdf.text "No hay suficientes datos para determinar preguntas problemáticas.", style: :italic
      end
      
      # Pie de página
      pdf.number_pages "Página <page> de <total>", 
                      { start_count_at: 1, page_filter: :all, at: [pdf.bounds.right - 150, 0], 
                        align: :right, size: 9 }
      
      pdf.render
    rescue LoadError
      # Si no está disponible Prawn, devolver un PDF básico con mensaje de error
      StringIO.new("No se puede generar el PDF: Prawn no está disponible").read
    end
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
