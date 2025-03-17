class QuizResultsController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_quiz, only: [:index, :show, :export]
  before_action :set_result, only: [:show, :destroy]
  before_action :verify_access

  # Listado de resultados para un quiz específico
  def index
    @results = @quiz.quiz_results
                   .includes(:usuario, :intento_quiz)
                   .order(created_at: :desc)
                   .paginate(page: params[:page], per_page: 20)
    
    # Estadísticas globales
    @total_results = @results.count
    @aprobados = @results.where(aprobado: true).count
    @promedio = @results.average(:puntaje_total).to_f.round(2)
    @mejor_puntaje = @results.maximum(:puntaje_total)
    @peor_puntaje = @results.minimum(:puntaje_total)
    
    # Datos para gráficos
    prepare_chart_data
    
    respond_to do |format|
      format.html
      format.json { render json: { results: @results, stats: chart_data } }
    end
  end

  # Mostrar un resultado específico con detalles
  def show
    # Cargar respuestas detalladas para análisis
    @intento = @result.intento_quiz
    @respuestas = @intento.respuestas.includes(:pregunta, :opcion)
    
    # Organizar preguntas por categorías
    @preguntas_correctas = @respuestas.where(es_correcta: true).map(&:pregunta)
    @preguntas_incorrectas = @respuestas.where(es_correcta: false).map(&:pregunta)
    
    # Comparar con otros resultados
    @posicion = @result.posicion_ranking || @quiz.quiz_results.where('puntaje_total > ?', @result.puntaje_total).count + 1
    @total_resultados = @quiz.quiz_results.count
    @percentil = ((@total_resultados - @posicion) / @total_resultados.to_f * 100).round

    # Generar recomendaciones basadas en respuestas incorrectas
    generate_recommendations
    
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "resultado_#{@result.id}", 
               template: "quiz_results/show.pdf.erb", 
               layout: "pdf.html"
      end
      format.json { render json: @result.generar_resumen }
    end
  end
  
  # Exportar resultados en diferentes formatos
  def export
    @results = @quiz.quiz_results.includes(:usuario, :intento_quiz)
    
    respond_to do |format|
      format.csv do
        send_data generate_csv, 
                  filename: "resultados_quiz_#{@quiz.id}_#{Time.current.strftime('%Y%m%d')}.csv", 
                  type: 'text/csv'
      end
      format.pdf do
        render pdf: "resultados_quiz_#{@quiz.id}",
               template: "quiz_results/export.pdf.erb",
               layout: "pdf.html"
      end
      format.json { render json: @results.map(&:generar_resumen) }
    end
  end
  
  # Eliminar un resultado (solo para admin/profesor)
  def destroy
    authorize @result
    @result.destroy
    
    redirect_to quiz_quiz_results_path(@quiz), notice: 'Resultado eliminado exitosamente'
  end

  private
  
  def set_quiz
    @quiz = Quiz.find(params[:quiz_id])
  end
  
  def set_result
    @result = QuizResult.find(params[:id])
    @quiz = @result.quiz
  end
  
  def verify_access
    # Administradores tienen acceso total
    return if current_usuario.admin?
    
    # Profesores solo pueden ver resultados de sus cursos
    if current_usuario.profesor?
      return if @quiz.curso.profesor_id == current_usuario.id
      redirect_to root_path, alert: 'No tienes permiso para ver estos resultados'
      return
    end
    
    # Estudiantes solo pueden ver sus propios resultados
    if current_usuario.estudiante?
      if action_name == 'index'
        return if @quiz.curso.estudiantes.include?(current_usuario)
      else # show
        return if @result&.usuario_id == current_usuario.id
      end
      
      redirect_to root_path, alert: 'No tienes permiso para ver estos resultados'
      return
    end
  end
  
  # Método para generar resultados faltantes (administración)
  def process_missing_results
    authorize! :admin, @quiz
    
    count = 0
    @quiz.intentos.completado.where(has_result: [false, nil]).find_each do |intento|
      result = QuizResult.crear_desde_intento(intento)
      if result
        intento.update(has_result: true)
        count += 1
      end
    end
    
    # Marcar que el quiz tiene resultados
    @quiz.update(has_results_cache: true) if count > 0
    
    redirect_to quiz_quiz_results_path(@quiz), notice: "Se procesaron #{count} resultados pendientes."
  end
  
  def prepare_chart_data
    @chart_data = {
      rangos: ['0-20%', '21-40%', '41-60%', '61-80%', '81-100%'],
      valores: Array.new(5, 0)
    }
    
    @results.each do |result|
      rango_index = case result.puntaje_total
                    when 0..20 then 0
                    when 21..40 then 1
                    when 41..60 then 2
                    when 61..80 then 3
                    else 4
                    end
      @chart_data[:valores][rango_index] += 1
    end
    
    # También almacenar datos temporales
    @tiempos = @results.pluck(:tiempo_segundos).compact
    @tiempo_promedio = @tiempos.any? ? (@tiempos.sum / @tiempos.size.to_f).round : 0
    @tiempo_minimo = @tiempos.min || 0
    @tiempo_maximo = @tiempos.max || 0
  end
  
  def generate_recommendations
    @recomendaciones = []
    
    # Analizar patrones de error
    if @preguntas_incorrectas.any?
      categorias_problematicas = @preguntas_incorrectas.group_by(&:tipo)
                                  .transform_values(&:count)
                                  .sort_by { |_, v| -v }
                                  
      # Recomendar basado en tipo más problemático
      if tipo_problematico = categorias_problematicas.first
        case tipo_problematico[0]
        when 'opcion_multiple', 'verdadero_falso'
          @recomendaciones << 'Revisa los conceptos clave antes de seleccionar una respuesta, y descarta opciones claramente incorrectas.'
        when 'respuesta_corta'
          @recomendaciones << 'Practica la terminología específica y asegúrate de usar la ortografía correcta.'
        when 'emparejamiento'
          @recomendaciones << 'Crea tarjetas de estudio para memorizar las relaciones entre términos y definiciones.'
        when 'multiple_respuesta'
          @recomendaciones << 'Evalúa cada opción de forma independiente para determinar si es correcta o no.'
        end
      end
      
      # Recomendar material de estudio
      laboratorio = @quiz.laboratorio
      if laboratorio
        @recomendaciones << "Revisa nuevamente el laboratorio '#{laboratorio.titulo}' para reforzar estos conceptos."
      end
      
      # Revisar si hubo problemas de tiempo
      if @result.tiempo_segundos && @result.tiempo_segundos > (@quiz.tiempo_limite * 60 * 0.9)
        @recomendaciones << 'Trabajaste con el tiempo justo. Practica responder preguntas similares para mejorar tu velocidad.'
      end
    else
      @recomendaciones << '¡Excelente trabajo! Obtuviste todas las respuestas correctas.'
    end
  end
  
  def generate_csv
    CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Estudiante', 'Puntaje', 'Estado', 'Preguntas Correctas', 'Total Preguntas', 
              'Tiempo (segundos)', 'Fecha', 'Posición Ranking']
      
      @results.each do |result|
        csv << [
          result.id,
          result.usuario.nombre_completo,
          result.puntaje_total,
          result.aprobado ? 'Aprobado' : 'Reprobado',
          result.respuestas_correctas,
          result.total_preguntas,
          result.tiempo_segundos,
          result.created_at.strftime('%Y-%m-%d %H:%M'),
          result.posicion_ranking || 'N/A'
        ]
      end
    end
  end
end
