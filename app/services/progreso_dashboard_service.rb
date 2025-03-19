# app/services/progreso_dashboard_service.rb
class ProgresoDashboardService
  attr_reader :usuario, :periodo, :curso_id

  def initialize(usuario, params = {})
    @usuario = usuario
    @periodo = params[:periodo] || 'month'
    @curso_id = params[:curso_id]
  end

  # Carga los datos para el dashboard
  def load_data
    if usuario.profesor?
      load_profesor_dashboard
    else
      load_estudiante_dashboard
    end
  end

  # Estadísticas generales para ambos tipos de usuario
  def estadisticas_generales
    {
      total_sesiones: usuario.sesion_laboratorios.count,
      sesiones_activas: usuario.sesion_laboratorios.activas.count,
      sesiones_completadas: usuario.sesion_laboratorios.completadas.count,
      tiempo_total: calcular_tiempo_total,
      promedio_completado: calcular_promedio_completado
    }
  end

  # Obtiene datos para gráficos
  def chart_data
    case periodo
    when 'week'
      data_by_day
    when 'month'
      data_by_week
    when 'year'
      data_by_month
    else
      data_by_week
    end
  end

  private

  # Dashboard para profesores
  def load_profesor_dashboard
    cursos = usuario.cursos_como_profesor

    cursos = cursos.where(id: curso_id) if curso_id.present?

    # Inicializar estadísticas de estudiantes con valores por defecto
    estudiantes_stats = {
      total_estudiantes: 0,
      estudiantes_activos: 0,
      promedio_completados: 0,
      nuevos_estudiantes: 0
    }
    
    # Solo calcular estadísticas de estudiantes si hay cursos
    estudiantes_stats = estadisticas_estudiantes(cursos) if cursos.any?

    # Inicializar con arrays vacíos para evitar errores de nil
    empty_labs = []
    empty_students = []

    {
      estadisticas: estadisticas_generales,
      estadisticas_estudiantes: estudiantes_stats,
      actividad_reciente: actividad_reciente_profesor,
      cursos_activos: cursos.where(estado: :publicado),
      laboratorios_populares: cursos.any? ? laboratorios_populares(cursos) : empty_labs,
      estudiantes_destacados: cursos.any? ? estudiantes_destacados(cursos) : empty_students,
      chart_data: chart_data,
      distribucion_completados: distribucion_por_dificultad,
      progreso_promedio: cursos.any? ? progreso_promedio_cursos(cursos) : []
    }
  end

  # Dashboard para estudiantes
  def load_estudiante_dashboard
    # Asegurarse que siempre haya datos mínimos para todos los componentes del dashboard
    stats = estadisticas_generales
    chart = habilidades_chart_data
    proximos = proximos_laboratorios
    cursos_data = progreso_cursos
    tiempo = tiempo_dedicado
    distribucion = distribucion_actividad
    actividad = actividad_reciente_estudiante
    logros_data = usuario.logros.where(visible: true).order(otorgado_en: :desc).limit(5)
    
    {
      estadisticas: stats,
      chart_data: chart,
      proximos_labs: proximos,
      cursos: cursos_data,
      tiempo_dedicado: tiempo,
      distribucion_actividad: distribucion,
      actividad_reciente: actividad,
      logros: logros_data
    }
  end

  def habilidades_chart_data
    # Implementación básica que devuelve datos de ejemplo
    {
      labels: ['Networking', 'Pentesting', 'Seguridad Web', 'Forense', 'Criptografía'],
      datasets: [{
        label: 'Habilidades',
        data: [65, 59, 80, 81, 56],
        backgroundColor: 'rgba(54, 162, 235, 0.2)',
        borderColor: 'rgb(54, 162, 235)',
        borderWidth: 1
      }]
    }
  end

  # Implementación de los métodos faltantes
  def tiempo_dedicado
    # Tiempo dedicado por tipo de laboratorio
    usuario.sesion_laboratorios
           .completadas
           .joins(:laboratorio)
           .group('laboratorios.tipo')
           .sum('EXTRACT(EPOCH FROM (tiempo_fin - tiempo_inicio))')
           .transform_values { |segundos| format_time(segundos) }
  end

  def distribucion_actividad
    # Distribución de actividad por día de la semana
    dias = usuario.sesion_laboratorios
                  .group('EXTRACT(DOW FROM created_at)')
                  .count
                  .transform_keys { |k| day_name(k.to_i) }

    # Si no hay datos, devolver estructura vacía
    if dias.empty?
      dias = {
        'Lunes' => 0,
        'Martes' => 0,
        'Miércoles' => 0,
        'Jueves' => 0,
        'Viernes' => 0,
        'Sábado' => 0,
        'Domingo' => 0
      }
    end

    dias
  end

  def day_name(dow)
    # Convertir número de día (0=domingo, 1=lunes, etc) a nombre
    dias = %w[Domingo Lunes Martes Miércoles Jueves Viernes Sábado]
    dias[dow]
  end

  def format_time(seconds)
    # Formatear segundos como texto legible
    minutes = (seconds / 60).to_i
    hours = (minutes / 60).to_i
    minutes_remainder = minutes % 60

    if hours > 0
      "#{hours}h #{minutes_remainder}m"
    else
      "#{minutes}m"
    end
  end

  # Estadísticas sobre los estudiantes (para profesores)

  def estadisticas_estudiantes(cursos)
    # Si no hay cursos, devolver valores por defecto
    return {
      total_estudiantes: 0,
      estudiantes_activos: 0,
      promedio_completados: 0,
      nuevos_estudiantes: 0
    } if cursos.blank?
    
    estudiantes_ids = CursoEstudiante.where(curso_id: cursos.pluck(:id)).pluck(:usuario_id).uniq
    
    # Si no hay estudiantes, devolver valores por defecto
    return {
      total_estudiantes: 0,
      estudiantes_activos: 0,
      promedio_completados: 0,
      nuevos_estudiantes: 0
    } if estudiantes_ids.blank?
    
    estudiantes = Usuario.where(id: estudiantes_ids)

    # Calcular promedio de completados con manejo de errores
    counts = SesionLaboratorio.completadas
                             .where(usuario_id: estudiantes_ids)
                             .group(:usuario_id)
                             .count
                             .values
    
    promedio = if counts.empty?
                 0
               else
                 begin
                   counts.sum.to_f / counts.size
                 rescue StandardError
                   0
                 end
               end

    {
      total_estudiantes: estudiantes.count,
      estudiantes_activos: estudiantes.joins(:sesion_laboratorios)
                                      .where(sesion_laboratorios: { estado: 'activa' })
                                      .distinct.count,
      promedio_completados: promedio,
      nuevos_estudiantes: estudiantes.where('created_at >= ?', 30.days.ago).count
    }
  end

  # Laboratorios más populares (para profesores)
  def laboratorios_populares(cursos)
    return [] if cursos.blank?
    
    cursos_ids = cursos.pluck(:id)
    return [] if cursos_ids.empty?
    
    # Verificar si hay sesiones de laboratorio para estos cursos
    has_sesiones = SesionLaboratorio.joins(:laboratorio)
                                    .where(laboratorios: { curso_id: cursos_ids })
                                    .exists?
    return [] unless has_sesiones
    
    Laboratorio.joins(:sesion_laboratorios)
               .where(curso_id: cursos_ids)
               .select('laboratorios.*, COUNT(sesion_laboratorios.id) as intentos_count')
               .group('laboratorios.id')
               .order('intentos_count DESC')
               .limit(5)
  end

  # Estudiantes destacados (para profesores)
  def estudiantes_destacados(cursos)
    return [] if cursos.blank?
    
    cursos_ids = cursos.pluck(:id)
    return [] if cursos_ids.empty?
    
    estudiantes_ids = CursoEstudiante.where(curso_id: cursos_ids).pluck(:usuario_id).uniq
    return [] if estudiantes_ids.empty?
    
    # Verificar si hay sesiones completadas para estos estudiantes
    has_sesiones_completadas = SesionLaboratorio.where(usuario_id: estudiantes_ids)
                                              .where(estado: 'completada')
                                              .exists?
    return [] unless has_sesiones_completadas

    Usuario.where(id: estudiantes_ids)
           .joins(:sesion_laboratorios)
           .where(sesion_laboratorios: { estado: 'completada' })
           .select('usuarios.*, COUNT(sesion_laboratorios.id) as completados_count')
           .group('usuarios.id')
           .order('completados_count DESC')
           .limit(5)
  end

  # Actividad reciente (para profesores)
  def actividad_reciente_profesor
    cursos_ids = usuario.cursos_como_profesor.pluck(:id)
    
    # Si no hay cursos, devolver una colección vacía
    return SesionLaboratorio.none if cursos_ids.empty?
    
    laboratorios_ids = Laboratorio.where(curso_id: cursos_ids).pluck(:id)
    
    # Si no hay laboratorios, devolver una colección vacía
    return SesionLaboratorio.none if laboratorios_ids.empty?

    SesionLaboratorio.where(laboratorio_id: laboratorios_ids)
                     .includes(:usuario, :laboratorio)
                     .order(created_at: :desc)
                     .limit(10)
  end

  # Actividad reciente (para estudiantes)
  def actividad_reciente_estudiante
    usuario.sesion_laboratorios
           .includes(:laboratorio)
           .order(created_at: :desc)
           .limit(10)
  end

  # Progreso en los cursos (para estudiantes)
  def progreso_cursos
    usuario.cursos.map do |curso|
      laboratorios = curso.laboratorios
      completados = usuario.sesion_laboratorios
                           .completadas
                           .where(laboratorio_id: laboratorios.pluck(:id))
                           .select(:laboratorio_id)
                           .distinct
                           .count

      total = laboratorios.count
      porcentaje = total > 0 ? (completados.to_f / total * 100).round : 0

      {
        curso: curso,
        completados: completados,
        total: total,
        porcentaje: porcentaje
      }
    end
  end

  # Laboratorios completados (para estudiantes)
  def laboratorios_completados
    usuario.sesion_laboratorios
           .completadas
           .includes(laboratorio: :curso)
           .order(created_at: :desc)
           .limit(5)
  end

  # Próximos laboratorios (para estudiantes)
  def proximos_laboratorios
    # Obtener laboratorios de cursos en los que está inscrito
    labs_cursos = Laboratorio.joins(:curso)
                             .where(cursos: { id: usuario.cursos.pluck(:id) })

    # Obtener IDs de laboratorios ya completados
    completados_ids = usuario.sesion_laboratorios
                             .completadas
                             .pluck(:laboratorio_id)

    # Filtrar laboratorios no completados
    labs_cursos.where.not(id: completados_ids)
               .order(:nivel_dificultad, :created_at)
               .limit(5)
  end

  # Distribución de habilidades (para estudiantes)
  def distribucion_habilidades
    # Agrupar laboratorios por tipo y contar completados
    labs_por_tipo = usuario.sesion_laboratorios
                           .completadas
                           .joins(:laboratorio)
                           .group('laboratorios.tipo')
                           .count

    # Calcular porcentajes
    total = labs_por_tipo.values.sum.to_f
    return [] if total == 0

    labs_por_tipo.map do |tipo, count|
      {
        tipo: tipo,
        count: count,
        porcentaje: ((count / total) * 100).round
      }
    end.sort_by { |item| -item[:count] }
  end

  # Datos para gráficos por día (últimos 7 días)
  def data_by_day
    range = 7.days.ago.beginning_of_day..Time.current.end_of_day
    data = usuario.sesion_laboratorios
                  .where(created_at: range)
                  .group('DATE(created_at)')
                  .count

    # Completar días faltantes
    labels = []
    values = []

    7.downto(0) do |i|
      date = i.days.ago.to_date
      labels << date.strftime('%d/%m')
      values << (data[date] || 0)
    end

    { labels: labels, values: values }
  end

  # Datos para gráficos por semana (últimas 4 semanas)
  def data_by_week
    range = 4.weeks.ago.beginning_of_week..Time.current.end_of_week
    data = usuario.sesion_laboratorios
                  .where(created_at: range)
                  .group("DATE_TRUNC('week', created_at)")
                  .count

    # Completar semanas faltantes
    labels = []
    values = []

    4.downto(0) do |i|
      week_start = i.weeks.ago.beginning_of_week
      labels << "Semana #{week_start.strftime('%d/%m')}"
      values << (data[week_start] || 0)
    end

    { labels: labels, values: values }
  end

  # Datos para gráficos por mes (últimos 12 meses)
  def data_by_month
    range = 12.months.ago.beginning_of_month..Time.current.end_of_month
    data = usuario.sesion_laboratorios
                  .where(created_at: range)
                  .group("DATE_TRUNC('month', created_at)")
                  .count

    # Completar meses faltantes
    labels = []
    values = []

    12.downto(0) do |i|
      month_start = i.months.ago.beginning_of_month
      labels << month_start.strftime('%b %Y')
      values << (data[month_start] || 0)
    end

    { labels: labels, values: values }
  end

  # Distribución por nivel de dificultad
  def distribucion_por_dificultad
    # Si no hay sesiones, devolver una estructura vacía con los niveles de dificultad comunes
    has_sesiones = usuario.sesion_laboratorios.completadas.exists?
    
    unless has_sesiones
      return {
        'principiante' => 0,
        'intermedio' => 0,
        'avanzado' => 0
      }
    end
    
    # Obtener distribución real
    result = usuario.sesion_laboratorios
                   .completadas
                   .joins(:laboratorio)
                   .group('laboratorios.nivel_dificultad')
                   .count
                   .transform_keys(&:to_s)
    
    # Asegurarse de que todos los niveles estén presentes
    ['principiante', 'intermedio', 'avanzado'].each do |nivel|
      result[nivel] ||= 0
    end
    
    result
  end

  # Progreso promedio en los cursos (para profesores)
  def progreso_promedio_cursos(cursos)
    return [] if cursos.blank?
    
    resultado = []
    
    cursos.each do |curso|
      laboratorios = curso.laboratorios
      next if laboratorios.empty?

      estudiantes = curso.estudiantes
      next if estudiantes.empty?

      # Calcular progreso de cada estudiante
      progreso_total = 0
      begin
        progreso_total = estudiantes.sum do |estudiante|
          lab_ids = laboratorios.pluck(:id)
          completados = estudiante.sesion_laboratorios
                                  .completadas
                                  .where(laboratorio_id: lab_ids)
                                  .select(:laboratorio_id)
                                  .distinct
                                  .count

          # Evitar división por cero
          laboratorios.count > 0 ? (completados.to_f / laboratorios.count * 100) : 0
        end

        # Calcular promedio - evitar división por cero
        promedio = estudiantes.count > 0 ? (progreso_total / estudiantes.count).round : 0

        resultado << {
          curso: curso,
          promedio: promedio
        }
      rescue StandardError => e
        # Registrar error pero continuar con el siguiente curso
        Rails.logger.error("Error calculando progreso promedio para curso #{curso.id}: #{e.message}")
        resultado << {
          curso: curso,
          promedio: 0
        }
      end
    end
    
    resultado
  end

  # Cálculo del tiempo total en laboratorios
  def calcular_tiempo_total
    # Suma del tiempo en sesiones completadas
    tiempo_completadas = usuario.sesion_laboratorios
                                .completadas
                                .where.not(tiempo_fin: nil)
                                .sum('EXTRACT(EPOCH FROM (tiempo_fin - tiempo_inicio))')

    # Suma del tiempo en sesiones activas (hasta ahora)
    tiempo_activas = usuario.sesion_laboratorios
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

  # Cálculo del promedio de completado de laboratorios
  def calcular_promedio_completado
    sesiones = usuario.sesion_laboratorios.completadas
    return 0 if sesiones.empty?

    total_tiempo = sesiones.where.not(tiempo_fin: nil)
                           .sum('EXTRACT(EPOCH FROM (tiempo_fin - tiempo_inicio))')

    promedio_segundos = total_tiempo / sesiones.count

    # Formatear como texto
    if promedio_segundos < 3600
      "#{(promedio_segundos / 60).to_i} minutos"
    else
      horas = (promedio_segundos / 3600).to_i
      minutos = ((promedio_segundos % 3600) / 60).to_i
      "#{horas} horas, #{minutos} minutos"
    end
  end
end
