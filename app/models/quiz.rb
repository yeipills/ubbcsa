class Quiz < ApplicationRecord
  belongs_to :curso
  belongs_to :laboratorio, optional: true
  belongs_to :usuario
  
  has_many :preguntas, class_name: 'QuizPregunta', dependent: :destroy
  has_many :intentos, class_name: 'IntentoQuiz', dependent: :destroy
  has_many :quiz_results, dependent: :destroy
  has_many :notificaciones, as: :notificable, dependent: :destroy

  attr_accessor :duplicar_preguntas

  # Validaciones
  validates :titulo, presence: true
  validates :titulo, uniqueness: { scope: [:curso_id, :laboratorio_id], 
                                   message: "ya existe un quiz con este título para el mismo curso y laboratorio" }
  validates :descripcion, presence: true
  validates :tiempo_limite, numericality: { greater_than: 0 }
  validates :intentos_permitidos, numericality: { greater_than: 0 }
  validates :fecha_inicio, presence: true
  validates :fecha_fin, presence: true
  validates :peso_calificacion, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :codigo_acceso, uniqueness: true, allow_blank: true
  validate :fecha_fin_despues_de_inicio
  validate :tiene_preguntas_si_publicado

  # Enumeraciones
  enum estado: {
    borrador: 0,
    publicado: 1,
    cerrado: 2
  }

  # Scopes
  scope :activos, -> { where(estado: :publicado) }
  scope :proximos, -> { where('fecha_inicio > ?', Time.current) }
  scope :en_curso, -> { where('fecha_inicio <= ? AND fecha_fin >= ?', Time.current, Time.current) }
  scope :finalizados, -> { where('fecha_fin < ?', Time.current) }
  scope :del_curso, ->(curso_id) { where(curso_id: curso_id) }
  scope :disponibles_para, ->(usuario) { 
    activos.where('fecha_inicio <= ? AND fecha_fin >= ?', Time.current, Time.current)
           .joins(:curso)
           .where('cursos.id IN (?)', usuario.cursos.pluck(:id))
  }
  scope :ordenados_por_fecha, -> { order(fecha_inicio: :desc) }
  
  # Callbacks
  before_save :actualizar_estado_automaticamente
  after_save :notificar_cambios_si_publicado
  after_create :generar_codigo_inicial

  # Métodos de instancia
  def disponible_para?(usuario)
    publicado? &&
      Time.current.between?(fecha_inicio, fecha_fin) &&
      intentos_disponibles_para?(usuario) &&
      es_parte_del_curso?(usuario)
  end

  def es_parte_del_curso?(usuario)
    # Verificar si el usuario es parte del curso (estudiante, profesor o admin)
    usuario.admin? || usuario.id == curso.profesor_id || curso.estudiantes.include?(usuario)
  end

  def intentos_disponibles_para?(usuario)
    intentos.where(usuario: usuario).count < intentos_permitidos
  end

  def intentos_completados_para(usuario)
    intentos.completado.where(usuario: usuario)
  end

  def mejor_intento_para(usuario)
    intentos_completados_para(usuario).order(puntaje_total: :desc).first
  end

  def tiempo_restante
    return 0 if fecha_fin.past?
    [(fecha_fin - Time.current).to_i, 0].max
  end

  def puntaje_total_posible
    preguntas.sum(:puntaje)
  end

  def puntaje_promedio
    intentos.completado.average(:puntaje_total) || 0
  end

  def tiempo_promedio_segundos
    intentos.completado.average('EXTRACT(EPOCH FROM (finalizado_en - iniciado_en))').to_i || 0
  end

  def tasa_aprobacion(puntaje_minimo = 60)
    total = intentos.completado.count
    return 0 if total.zero?

    aprobados = intentos.completado.where('puntaje_total >= ?', puntaje_minimo).count
    (aprobados.to_f / total * 100).round(1)
  end
  
  def estado_display
    case estado
    when 'borrador' then 'Borrador'
    when 'publicado' then 'Publicado'
    when 'cerrado' then 'Cerrado'
    end
  end
  
  def generar_estadisticas
    {
      total_intentos: intentos.completado.count,
      intentos_por_estudiante: intentos_por_estudiante,
      distribucion_puntajes: distribucion_puntajes,
      preguntas_dificiles: preguntas_dificiles,
      tiempo_promedio: tiempo_promedio_segundos
    }
  end
  
  def intentos_por_estudiante
    intentos.completado.group(:usuario_id).count.transform_keys { |k| Usuario.find(k).nombre_completo }
  end
  
  def distribucion_puntajes
    rangos = { 
      '0-20%' => 0,
      '21-40%' => 0,
      '41-60%' => 0,
      '61-80%' => 0, 
      '81-100%' => 0
    }
    
    intentos.completado.each do |intento|
      # Asegurar que el puntaje esté en el rango 0-100
      puntaje = [[intento.puntaje_total.to_f, 0].max, 100].min
      
      case puntaje
      when 0..20 then rangos['0-20%'] += 1
      when 21..40 then rangos['21-40%'] += 1
      when 41..60 then rangos['41-60%'] += 1
      when 61..80 then rangos['61-80%'] += 1
      else rangos['81-100%'] += 1
      end
    end
    
    rangos
  end
  
  def preguntas_dificiles(limit = 5)
    resultados = {}
    
    # Optimización: realizar una sola consulta para obtener datos de respuestas
    datos_respuestas = RespuestaQuiz.joins(:intento_quiz)
                      .where(pregunta_id: preguntas.pluck(:id))
                      .where(intentos_quiz: { estado: :completado })
                      .group(:pregunta_id)
                      .select(
                        'pregunta_id',
                        'COUNT(*) as total_respuestas',
                        'COUNT(CASE WHEN es_correcta = false THEN 1 END) as respuestas_incorrectas'
                      )
                      .to_a
    
    # Mapear a un hash para acceso rápido
    datos_por_pregunta = datos_respuestas.each_with_object({}) do |dato, hash|
      hash[dato.pregunta_id] = {
        total: dato.total_respuestas,
        incorrectas: dato.respuestas_incorrectas
      }
    end
    
    # Procesar cada pregunta
    preguntas.each do |pregunta|
      datos = datos_por_pregunta[pregunta.id]
      next unless datos && datos[:total] > 0
      
      tasa_error = (datos[:incorrectas].to_f / datos[:total] * 100).round(1)
      resultados[pregunta] = tasa_error
    end
    
    resultados.sort_by { |_, v| -v }.take(limit).to_h
  end
  
  def duplicar
    nuevo_quiz = self.dup
    nuevo_quiz.titulo = "Copia de #{titulo}"
    nuevo_quiz.codigo_acceso = nil
    nuevo_quiz.estado = :borrador
    
    Quiz.transaction do
      nuevo_quiz.save!
      
      # Duplicar preguntas
      preguntas.each do |pregunta|
        nueva_pregunta = pregunta.dup
        nueva_pregunta.quiz = nuevo_quiz
        nueva_pregunta.save!
        
        # Duplicar opciones
        pregunta.opciones.each do |opcion|
          nueva_opcion = opcion.dup
          nueva_opcion.pregunta = nueva_pregunta
          nueva_opcion.save!
        end
      end
    end
    
    nuevo_quiz
  end

  private

  def fecha_fin_despues_de_inicio
    return unless fecha_inicio && fecha_fin
    return unless fecha_fin <= fecha_inicio
    errors.add(:fecha_fin, 'debe ser posterior a la fecha de inicio')
  end

  def tiene_preguntas_si_publicado
    return unless publicado? && preguntas.none?
    errors.add(:base, 'No se puede publicar un quiz sin preguntas')
  end

  def actualizar_estado_automaticamente
    # Cerrar automáticamente si la fecha de fin ha pasado
    if fecha_fin && fecha_fin < Time.current
      self.estado = :cerrado 
    end
  end

  def notificar_cambios_si_publicado
    return unless estado_previously_changed? && publicado?
    # Implementar notificaciones
  end
  
  # Método privado para generar el código inicial al crear
  def generar_codigo_inicial
    # Solo generamos automáticamente si el quiz se crea como publicado
    generar_codigo_acceso if publicado? && codigo_acceso.blank?
  end
  
  # Genera un código único de acceso para el quiz
  def generar_codigo_acceso
    return codigo_acceso if codigo_acceso.present? && codigo_acceso != "AUTO"
    
    loop do
      codigo = SecureRandom.alphanumeric(6).upcase
      unless Quiz.exists?(codigo_acceso: codigo)
        update_column(:codigo_acceso, codigo)
        break
      end
    end
    
    codigo_acceso
  end
end
