class IntentoQuiz < ApplicationRecord
  self.table_name = 'intentos_quiz'

  belongs_to :quiz
  belongs_to :usuario
  has_many :respuestas, class_name: 'RespuestaQuiz', dependent: :destroy
  has_many :eventos_intento, dependent: :destroy
  has_one :quiz_result, dependent: :destroy
  
  store_accessor :metadata, :navegador, :dispositivo, :ultima_actividad, :vistas_pregunta, :orden_preguntas, :opciones_aleatorias
  
  # Validaciones
  validates :numero_intento, uniqueness: { scope: %i[quiz_id usuario_id] }
  validates :iniciado_en, presence: true

  # Enumeraciones
  enum estado: {
    en_progreso: 0,
    completado: 1,
    expirado: 2,
    abandonado: 3, # Nuevo estado para intentos abandonados (no completados pero no expirados)
    anulado: 4     # Nuevo estado para intentos invalidados por admin/profesor
  }

  # Callbacks
  before_validation :set_numero_intento, on: :create
  before_validation :set_iniciado_en, on: :create
  before_create :inicializar_metadata
  after_create :registrar_evento_inicio
  after_update :registrar_evento_finalizacion, if: -> { saved_change_to_estado? && (completado? || expirado?) }

  # Scopes
  scope :completados, -> { where(estado: :completado) }
  scope :en_curso, -> { where(estado: :en_progreso) }
  scope :recientes, -> { order(created_at: :desc) }
  scope :del_usuario, ->(usuario_id) { where(usuario_id: usuario_id) }
  scope :mejores_por_usuario, -> { 
    where(estado: :completado)
      .select('DISTINCT ON (usuario_id) *')
      .order('usuario_id, puntaje_total DESC')
  }
  
  # Métodos de instancia
  def duracion_segundos
    return nil unless finalizado_en
    (finalizado_en - iniciado_en).to_i
  end

  def duracion_formateada
    return 'No finalizado' unless duracion_segundos
    
    minutos = duracion_segundos / 60
    segundos = duracion_segundos % 60
    
    if minutos > 0
      "#{minutos}m #{segundos}s"
    else
      "#{segundos} segundos"
    end
  end

  def progreso_porcentaje
    total_preguntas = quiz.preguntas.count
    return 0 if total_preguntas.zero?

    preguntas_respondidas = respuestas.count
    (preguntas_respondidas.to_f / total_preguntas * 100).round
  end

  def tiempo_restante_segundos
    return 0 unless en_progreso?
    return 0 if expirado?

    tiempo_limite = quiz.tiempo_limite * 60
    tiempo_transcurrido = Time.current - iniciado_en

    [tiempo_limite - tiempo_transcurrido.to_i, 0].max
  end
  
  def tiempo_restante_formateado
    segundos = tiempo_restante_segundos
    minutos = segundos / 60
    segundos_restantes = segundos % 60
    
    if minutos > 0
      "#{minutos}:#{segundos_restantes.to_s.rjust(2, '0')}"
    else
      "0:#{segundos_restantes.to_s.rjust(2, '0')}"
    end
  end

  def respuesta_para(pregunta)
    respuestas.find_by(pregunta_id: pregunta.id)
  end

  def pregunta_respondida?(pregunta)
    respuesta_para(pregunta).present?
  end
  
  def todas_preguntas_respondidas?
    quiz.preguntas.count == respuestas.count
  end
  
  def preguntas_sin_responder
    ids_preguntas_respondidas = respuestas.pluck(:pregunta_id)
    preguntas_ordenadas.select { |p| !ids_preguntas_respondidas.include?(p.id) }
  end
  
  def primera_pregunta_sin_responder
    preguntas_sin_responder.first
  end
  
  # Devuelve las preguntas en el orden correspondiente (aleatorio si está habilitado)
  def preguntas_ordenadas
    return @preguntas_ordenadas if defined?(@preguntas_ordenadas)
    
    if quiz.aleatorizar_preguntas? && orden_preguntas.present?
      # Orden personalizado según metadatos
      @preguntas_ordenadas = orden_preguntas.map { |id| quiz.preguntas.find_by(id: id) }.compact
    else
      # Orden por defecto
      @preguntas_ordenadas = quiz.preguntas.order(:orden)
    end
    
    @preguntas_ordenadas
  end
  
  # Devuelve las opciones de una pregunta en el orden correspondiente (aleatorio si está habilitado)
  def opciones_ordenadas(pregunta)
    if quiz.aleatorizar_opciones? && opciones_aleatorias.present? && opciones_aleatorias[pregunta.id.to_s].present?
      # Orden personalizado según metadatos
      ids_opciones = opciones_aleatorias[pregunta.id.to_s]
      ids_opciones.map { |id| pregunta.opciones.find_by(id: id) }.compact
    else
      # Orden por defecto
      pregunta.opciones.order(:orden)
    end
  end

  def calcular_resultado(force_save = true)
    return puntaje_total if puntaje_total.present? && estado == 'completado' && !force_save

    total_puntos = 0
    total_posible = 0
    detalles_por_pregunta = {}

    quiz.preguntas.each do |pregunta|
      total_posible += pregunta.puntaje
      respuesta = respuesta_para(pregunta)
      
      puntaje_pregunta = if respuesta
                           respuesta.verificar_correctitud if respuesta.puntaje_obtenido.nil?
                           respuesta.puntaje_obtenido
                         else
                           0
                         end
      
      total_puntos += puntaje_pregunta
      
      # Guardar detalles por pregunta para análisis
      detalles_por_pregunta[pregunta.id] = {
        puntaje_obtenido: puntaje_pregunta,
        puntaje_posible: pregunta.puntaje,
        es_correcta: respuesta&.es_correcta || false
      }
    end

    porcentaje = total_posible.zero? ? 0 : ((total_puntos / total_posible.to_f) * 100).round(1)
    
    if force_save
      update_columns(
        puntaje_total: porcentaje,
        puntaje_obtenido: total_puntos,
        puntaje_maximo: total_posible,
        detalles_resultado: detalles_por_pregunta
      )
    end

    porcentaje
  end

  def resultado_texto
    case puntaje_total.to_f
    when 0..59.9
      'Insuficiente'
    when 60..69.9
      'Suficiente'
    when 70..79.9
      'Bueno'
    when 80..89.9
      'Muy bueno'
    else
      'Excelente'
    end
  end

  def resultado_color_clase
    case puntaje_total.to_f
    when 0..59.9
      'bg-red-600'
    when 60..69.9
      'bg-yellow-500'
    when 70..79.9
      'bg-blue-500'
    when 80..89.9
      'bg-green-500'
    else
      'bg-purple-600'
    end
  end
  
  def finalizar(tiempo_expirado = false)
    if tiempo_expirado
      update(estado: :expirado, finalizado_en: Time.current)
    else
      update(estado: :completado, finalizado_en: Time.current)
      calcular_resultado
    end
  end

  def expirado?
    return true if estado == 'expirado'
    return false unless quiz.tiempo_limite
    return false if finalizado_en.present?

    tiempo_transcurrido = (Time.current - iniciado_en) / 60
    tiempo_transcurrido > quiz.tiempo_limite
  end
  
  def anular!(motivo)
    return false unless en_progreso? || completado?
    
    update(
      estado: :anulado,
      finalizado_en: finalizado_en || Time.current,
      metadata: metadata.merge(motivo_anulacion: motivo)
    )
    
    registrar_evento('anulacion', { motivo: motivo })
    true
  end
  
  def registrar_evento(tipo, detalles = {})
    eventos_intento.create(
      tipo: tipo,
      usuario_id: usuario_id,
      detalles: detalles,
      timestamp: Time.current
    )
  end
  
  def actualizar_actividad!(datos = {})
    self.ultima_actividad = Time.current.to_i
    
    if datos[:pregunta_id].present?
      # Actualizar contador de vistas para esta pregunta
      vistas = (vistas_pregunta || {})
      vistas[datos[:pregunta_id].to_s] ||= 0
      vistas[datos[:pregunta_id].to_s] += 1
      self.vistas_pregunta = vistas
    end
    
    # Añadir datos del navegador y dispositivo si es la primera vez
    self.navegador ||= datos[:navegador] if datos[:navegador].present?
    self.dispositivo ||= datos[:dispositivo] if datos[:dispositivo].present?
    
    save
  end
  
  # Obtener la clasificación de este intento respecto a otros
  def posicion_ranking
    # Posición es 1-based (1 es el mejor)
    posicion = quiz.intentos.completado
                   .where('puntaje_total > ?', puntaje_total.to_f)
                   .count + 1
  end
  
  def tiempo_comparado_promedio
    return nil unless duracion_segundos && quiz.tiempo_promedio_segundos > 0
    
    diferencia = duracion_segundos - quiz.tiempo_promedio_segundos
    porcentaje = (diferencia.to_f / quiz.tiempo_promedio_segundos * 100).round
    
    { 
      diferencia: diferencia,
      porcentaje: porcentaje,
      mas_rapido: diferencia < 0
    }
  end
  
  def self.expirar_intentos_vencidos
    en_progreso.joins(:quiz)
      .where('intentos_quiz.iniciado_en + (quizzes.tiempo_limite * interval \'1 minute\') < ?', Time.current)
      .find_each do |intento|
        intento.finalizar(true)
      end
  end

  def self.detectar_intentos_abandonados(horas_inactividad = 12)
    en_progreso.where('updated_at < ?', Time.current - horas_inactividad.hours)
               .update_all(estado: :abandonado, finalizado_en: Time.current)
  end

  private

  def set_numero_intento
    return if numero_intento.present?

    ultimo_intento = quiz.intentos.where(usuario_id: usuario_id).maximum(:numero_intento) || 0
    self.numero_intento = ultimo_intento + 1
  end

  def set_iniciado_en
    self.iniciado_en ||= Time.current
  end
  
  def inicializar_metadata
    self.metadata ||= {}
    self.vistas_pregunta ||= {}
    
    # Generar orden aleatorio de preguntas si está habilitado
    if quiz.aleatorizar_preguntas?
      orden_aleatorio = quiz.preguntas.pluck(:id).shuffle
      self.orden_preguntas = orden_aleatorio
    end
    
    # Generar orden aleatorio de opciones si está habilitado
    if quiz.aleatorizar_opciones?
      opciones_random = {}
      quiz.preguntas.each do |pregunta|
        next unless pregunta.opciones.exists? # Solo para preguntas con opciones
        opciones_random[pregunta.id.to_s] = pregunta.opciones.pluck(:id).shuffle
      end
      self.opciones_aleatorias = opciones_random
    end
  end
  
  def registrar_evento_inicio
    registrar_evento('inicio', { numero_intento: numero_intento })
  end
  
  def registrar_evento_finalizacion
    if completado?
      registrar_evento('completado', { 
        puntaje: puntaje_total,
        duracion: duracion_segundos,
        preguntas_respondidas: respuestas.count,
        preguntas_totales: quiz.preguntas.count
      })
    elsif expirado?
      registrar_evento('expirado', {
        preguntas_respondidas: respuestas.count,
        preguntas_totales: quiz.preguntas.count,
        tiempo_transcurrido: (Time.current - iniciado_en).to_i
      })
    end
  end
end
