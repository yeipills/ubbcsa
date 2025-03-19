# app/controllers/progreso_controller.rb
class ProgresoController < ApplicationController
  before_action :authenticate_usuario!
  before_action :set_periodo
  before_action :set_curso, only: [:index]

  def index
    @dashboard_data = ProgresoDashboardService.new(
      current_usuario,
      periodo: @periodo,
      curso_id: @curso_id
    ).load_data

    respond_to do |format|
      format.html
      format.json { render json: @dashboard_data }
    end
  rescue StandardError => e
    # Log del error para facilitar la depuración
    Rails.logger.error("Error en ProgresoDashboardService: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))

    flash.now[:alert] = 'Hubo un problema al cargar los datos del progreso. Por favor, inténtalo de nuevo.'
    # Datos mínimos para evitar errores en la vista, incluyendo todas las claves necesarias
    @dashboard_data = { 
      error: true, 
      actividad_reciente: [],
      estadisticas: {
        total_sesiones: 0,
        sesiones_activas: 0,
        sesiones_completadas: 0,
        tiempo_total: "0 minutos",
        promedio_completado: "0 minutos"
      },
      estadisticas_estudiantes: {
        total_estudiantes: 0,
        estudiantes_activos: 0,
        promedio_completados: 0,
        nuevos_estudiantes: 0
      },
      cursos_activos: [],
      laboratorios_populares: [],
      estudiantes_destacados: [],
      chart_data: { labels: [], values: [] },
      distribucion_completados: { 'principiante' => 0, 'intermedio' => 0, 'avanzado' => 0 },
      progreso_promedio: []
    }

    respond_to do |format|
      format.html { render :index }
      format.json { render json: { error: e.message }, status: :internal_server_error }
    end
  end

  def chart_data
    data = ProgresoDashboardService.new(
      current_usuario,
      periodo: @periodo
    ).chart_data

    render json: data
  end

  def detalles_laboratorio
    @laboratorio = Laboratorio.find(params[:id])
    @sesiones = current_usuario.sesion_laboratorios
                               .where(laboratorio: @laboratorio)
                               .order(created_at: :desc)

    @ultima_sesion = @sesiones.first
    @ejercicios_completados = EjercicioCompletado.where(
      usuario: current_usuario,
      ejercicio_id: @laboratorio.ejercicios.pluck(:id)
    ).includes(:ejercicio)

    # No se necesita obtener intentos, ya que no existe la tabla IntentoEjercicio
    @intentos = []

    respond_to do |format|
      format.html
      format.json do
        render json: {
          laboratorio: @laboratorio,
          sesiones: @sesiones,
          ultima_sesion: @ultima_sesion,
          ejercicios_completados: @ejercicios_completados,
          intentos: @intentos
        }
      end
    end
  end

  def detalles_curso
    @curso = Curso.find(params[:id])
    @laboratorios = @curso.laboratorios

    @completados = current_usuario.sesion_laboratorios
                                  .completadas
                                  .where(laboratorio_id: @laboratorios.pluck(:id))
                                  .select(:laboratorio_id)
                                  .distinct
                                  .pluck(:laboratorio_id)

    @progreso = @laboratorios.count > 0 ? (@completados.size.to_f / @laboratorios.count * 100).round : 0

    respond_to do |format|
      format.html
      format.json do
        render json: {
          curso: @curso,
          laboratorios: @laboratorios,
          completados: @completados,
          progreso: @progreso
        }
      end
    end
  end

  def estudiante
    @estudiante = Usuario.find(params[:id])

    # Verificar que el estudiante pertenece a algún curso del profesor
    cursos_ids = current_usuario.cursos_como_profesor.pluck(:id)
    estudiante_cursos = @estudiante.cursos.where(id: cursos_ids).pluck(:id)

    unless current_usuario.admin? || estudiante_cursos.any?
      flash[:error] = 'No tienes permisos para ver el progreso de este estudiante'
      redirect_to progreso_path
      return
    end

    @cursos = Curso.where(id: estudiante_cursos)
    @sesiones = @estudiante.sesion_laboratorios.includes(:laboratorio)
    @completados = @estudiante.sesion_laboratorios.completadas
    @tiempo_total = calcular_tiempo_total(@estudiante)

    # Progreso por curso
    @progreso_cursos = @cursos.map do |curso|
      laboratorios = curso.laboratorios
      completados = @estudiante.sesion_laboratorios
                               .completadas
                               .where(laboratorio_id: laboratorios.pluck(:id))
                               .select(:laboratorio_id)
                               .distinct
                               .count

      {
        curso: curso,
        completados: completados,
        total: laboratorios.count,
        porcentaje: laboratorios.count > 0 ? (completados.to_f / laboratorios.count * 100).round : 0
      }
    end

    respond_to do |format|
      format.html
      format.json do
        render json: {
          estudiante: @estudiante,
          cursos: @cursos,
          sesiones: @sesiones,
          completados: @completados,
          tiempo_total: @tiempo_total,
          progreso_cursos: @progreso_cursos
        }
      end
    end
  end

  def exportar_pdf
    respond_to do |format|
      format.html
      format.pdf do
        @dashboard_data = ProgresoDashboardService.new(
          current_usuario,
          periodo: @periodo,
          curso_id: @curso_id
        ).load_data

        # Verificar que las gemas de PDF estén disponibles
        begin
          require 'prawn'
          require 'prawn/table'
          
          render pdf: "progreso_#{current_usuario.nombre_usuario}",
                template: 'progreso/exportar_pdf',
                layout: 'pdf'
        rescue LoadError => e
          Rails.logger.error("Error al cargar las gemas de PDF: #{e.message}")
          flash[:error] = "No se pudo generar el PDF. Por favor, contacte al administrador."
          redirect_to progreso_path
        end
      end
    end
  rescue StandardError => e
    Rails.logger.error("Error al generar PDF: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    flash[:error] = "Ocurrió un error al generar el PDF. Por favor, inténtelo de nuevo."
    redirect_to progreso_path
  end

  private

  def set_periodo
    @periodo = params[:periodo] || 'month'
  end

  def set_curso
    @curso_id = params[:curso_id]
    @curso = Curso.find(@curso_id) if @curso_id.present?
  end

  def calcular_tiempo_total(estudiante)
    # Suma del tiempo en sesiones completadas
    tiempo_completadas = estudiante.sesion_laboratorios
                                   .completadas
                                   .where.not(tiempo_fin: nil)
                                   .sum('EXTRACT(EPOCH FROM (tiempo_fin - tiempo_inicio))')

    # Suma del tiempo en sesiones activas (hasta ahora)
    tiempo_activas = estudiante.sesion_laboratorios
                               .activas
                               .sum('EXTRACT(EPOCH FROM (NOW() - tiempo_inicio))')

    # Total en segundos
    total_segundos = tiempo_completadas + tiempo_activas

    # Formatear como texto
    if total_segundos < 3600
      "#{(total_segundos / 60).to_i} minutos"
    elsif total_segundos < 86_400
      horas = (total_segundos / 3600).to_i
      minutos = ((total_segundos % 3600) / 60).to_i
      "#{horas} horas, #{minutos} minutos"
    else
      dias = (total_segundos / 86_400).to_i
      horas = ((total_segundos % 86_400) / 3600).to_i
      "#{dias} días, #{horas} horas"
    end
  end
end
