class Quiz < ApplicationRecord
  belongs_to :curso
  belongs_to :laboratorio, optional: true
  belongs_to :usuario

  has_many :preguntas, class_name: 'QuizPregunta', dependent: :destroy
  has_many :intentos, class_name: 'IntentoQuiz', dependent: :destroy

  # Validaciones
  validates :titulo, presence: true
  validates :descripcion, presence: true
  validates :tiempo_limite, numericality: { greater_than: 0 }
  validates :intentos_permitidos, numericality: { greater_than: 0 }
  validates :fecha_inicio, presence: true
  validates :fecha_fin, presence: true
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

  # Callbacks
  before_save :actualizar_estado_automaticamente
  after_save :notificar_cambios_si_publicado

  # Métodos de instancia
  def disponible_para?(usuario)
    publicado? &&
      Time.current.between?(fecha_inicio, fecha_fin) &&
      intentos_disponibles_para?(usuario)
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
    intentos.completado.average(:puntaje_total)
  end

  def tiempo_promedio_segundos
    intentos.completado.average('EXTRACT(EPOCH FROM (finalizado_en - iniciado_en))').to_i
  end

  def tasa_aprobacion(puntaje_minimo = 60)
    total = intentos.completado.count
    return 0 if total.zero?

    aprobados = intentos.completado.where('puntaje_total >= ?', puntaje_minimo).count
    (aprobados.to_f / total * 100).round(1)
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
    return unless estado_changed? || fecha_fin_changed?

    # Cerrar automáticamente si la fecha de fin ha pasado
    return unless fecha_fin && fecha_fin < Time.current

    self.estado = :cerrado
  end

  def notificar_cambios_si_publicado
    return unless estado_previously_changed? && publicado?

    QuizNotificationJob.perform_later(id)
  end
end
