class QuizResumenController < ApplicationController
  before_action :authenticate_usuario!
  
  def index
    # Usar diferente lógica según el rol del usuario
    if current_usuario.admin?
      @quizzes = Quiz.all.order(created_at: :desc).limit(20)
    elsif current_usuario.profesor?
      @quizzes = Quiz.where(usuario_id: current_usuario.id).order(created_at: :desc)
    else
      @quizzes = Quiz.disponibles_para(current_usuario).order(fecha_inicio: :desc)
    end
    
    # Estadísticas generales
    @stats = {
      total_quizzes: @quizzes.count,
      quizzes_activos: @quizzes.activos.count,
      quizzes_proximos: @quizzes.proximos.count,
      quizzes_finalizados: @quizzes.finalizados.count
    }
    
    # Intentos recientes por usuario
    @intentos_recientes = IntentoQuiz.where(usuario_id: current_usuario.id)
                                      .order(created_at: :desc)
                                      .limit(5)
                                      .includes(:quiz)
    
    # Rendimiento general (si hay intentos)
    if @intentos_recientes.any?
      @rendimiento = {
        promedio: @intentos_recientes.where(estado: :completado).average(:puntaje_total) || 0,
        completados: @intentos_recientes.where(estado: :completado).count,
        total: @intentos_recientes.count,
        mejor_puntaje: @intentos_recientes.where(estado: :completado).maximum(:puntaje_total) || 0
      }
    end
    
    # Estadísticas generales para profesores
    if current_usuario.profesor? || current_usuario.admin?
      preparar_estadisticas_profesor
    end
    
    # Quizzes activos recientes para estudiantes
    if current_usuario.estudiante?
      preparar_quizzes_activos
    end
  end
  
  private
  
  def preparar_estadisticas_profesor
    # Si es profesor, mostrar estadísticas de todos sus quizzes
    if current_usuario.profesor?
      cursos_ids = current_usuario.cursos_como_profesor.pluck(:id)
      @quizzes_profesor = Quiz.where(curso_id: cursos_ids)
    else # admin
      @quizzes_profesor = Quiz.all
    end
    
    # Total de estudiantes que han hecho intentos
    @total_estudiantes = Usuario.joins(:intentos_quiz)
                              .where(intentos_quiz: { quiz_id: @quizzes_profesor.pluck(:id) })
                              .distinct.count
    
    # Tasa de aprobación global
    total_intentos = IntentoQuiz.where(quiz_id: @quizzes_profesor.pluck(:id), estado: :completado).count
    aprobados = QuizResult.where(quiz_id: @quizzes_profesor.pluck(:id), aprobado: true).count
    
    @tasa_aprobacion = total_intentos > 0 ? (aprobados.to_f / total_intentos * 100).round(1) : 0
    
    # Promedio general de puntajes
    @promedio_puntajes = QuizResult.where(quiz_id: @quizzes_profesor.pluck(:id)).average(:puntaje_total)&.round(1) || 0
    
    # Quizzes más populares (con más intentos)
    @quizzes_populares = @quizzes_profesor.joins(:intentos)
                           .select('quizzes.*, COUNT(intentos_quiz.id) as intentos_count')
                           .group('quizzes.id')
                           .order('intentos_count DESC')
                           .limit(5)
  end
  
  def preparar_quizzes_activos
    # Para estudiantes: quizzes disponibles que aún no han completado
    cursos_ids = current_usuario.cursos.pluck(:id)
    
    @quizzes_disponibles = Quiz.activos
                            .where(curso_id: cursos_ids)
                            .where('fecha_inicio <= ? AND fecha_fin >= ?', Time.current, Time.current)
                            .order(fecha_fin: :asc)
                            .limit(5)
    
    # Para cada quiz, verificar si el estudiante ya lo completó o está en progreso
    @estado_quizzes = {}
    @quizzes_disponibles.each do |quiz|
      intentos = IntentoQuiz.where(quiz_id: quiz.id, usuario_id: current_usuario.id)
      
      if intento = intentos.en_progreso.first
        @estado_quizzes[quiz.id] = { estado: 'en_progreso', intento_id: intento.id }
      elsif intentos.completado.exists?
        mejor_intento = intentos.completado.order(puntaje_total: :desc).first
        @estado_quizzes[quiz.id] = { 
          estado: 'completado', 
          intento_id: mejor_intento.id,
          puntaje: mejor_intento.puntaje_total 
        }
      else
        @estado_quizzes[quiz.id] = { estado: 'disponible' }
      end
    end
    
    # Quizzes próximos que aún no han iniciado
    @quizzes_proximos = Quiz.activos
                           .where(curso_id: cursos_ids)
                           .where('fecha_inicio > ?', Time.current)
                           .order(fecha_inicio: :asc)
                           .limit(3)
  end
end
