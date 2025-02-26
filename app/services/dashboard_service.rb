# app/services/dashboard_service.rb
class DashboardService
  attr_reader :usuario
  
  def initialize(usuario)
    @usuario = usuario
  end

  def load_data
    {
      laboratorios_activos: cargar_laboratorios_activos,
      sesiones_recientes: cargar_sesiones_recientes,
      laboratorios_disponibles: cargar_laboratorios_disponibles,
      estadisticas: cargar_estadisticas,
      cursos: cargar_cursos,
      laboratorios: cargar_laboratorios_por_rol,
      progreso: calcular_progreso_general
    }
  end

  private
  def cargar_laboratorios_activos
    usuario.sesion_laboratorios
          .activas
          .includes(laboratorio: :curso)
          .limit(5)
  end

  def cargar_sesiones_recientes
    usuario.sesion_laboratorios
          .completadas
          .includes(laboratorio: :curso)
          .recientes
          .limit(5)
  end

  def cargar_laboratorios_disponibles
    return cargar_laboratorios_profesor if usuario.profesor?
    cargar_laboratorios_estudiante
  end

  def cargar_estadisticas
    Rails.cache.fetch("user_stats/#{usuario.id}", expires_in: 5.minutes) do
      {
        sesiones_activas: usuario.sesion_laboratorios.activas.count,
        laboratorios_completados: usuario.laboratorios_completados,
        cursos_inscritos: usuario.todos_cursos.count
      }
    end
  end

  def cargar_cursos
    usuario.todos_cursos
          .includes(:laboratorios)
          .limit(3)
  end

  def cargar_laboratorios_por_rol
    return cargar_laboratorios_profesor_rol if usuario.profesor?
    cargar_laboratorios_estudiante_rol
  end

  private

  def cargar_laboratorios_profesor
    Laboratorio.activos
              .where(curso: { profesor_id: usuario.id })
              .includes(:curso)
              .limit(3)
  end

  def cargar_laboratorios_estudiante
    Laboratorio.activos
              .includes(:curso)
              .where.not(id: usuario.laboratorios.select(:id))
              .limit(3)
  end

  def cargar_laboratorios_profesor_rol
    Laboratorio.joins(:curso)
              .where(cursos: { profesor_id: usuario.id })
              .order(created_at: :desc)
              .limit(5)
  end

  def cargar_laboratorios_estudiante_rol
    usuario.laboratorios
          .order(created_at: :desc)
          .limit(5)
  end

  def calcular_progreso_general
    return 0 if usuario.profesor?
    
    Rails.cache.fetch("user_progress/#{usuario.id}", expires_in: 15.minutes) do
      total = usuario.laboratorios.count
      completados = usuario.laboratorios_completados
      
      total.zero? ? 0 : (completados.to_f / total * 100).round(2)
    end
  end
end