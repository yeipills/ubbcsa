# app/models/quiz_pregunta.rb
class QuizPregunta < ApplicationRecord
  self.table_name = 'quiz_preguntas'
  
  # Virtual attributes
  attr_accessor :remove_imagen, :multiple_respuestas_correctas

  belongs_to :quiz
  has_many :opciones, class_name: 'QuizOpcion', foreign_key: 'pregunta_id', dependent: :destroy
  has_many :respuestas, class_name: 'RespuestaQuiz', foreign_key: 'pregunta_id'
  has_one_attached :imagen
  
  accepts_nested_attributes_for :opciones, allow_destroy: true, reject_if: :all_blank

  validates :contenido, presence: true
  validates :puntaje, presence: true, numericality: { greater_than: 0 }
  validates :orden, presence: true, uniqueness: { scope: :quiz_id }
  validates :respuesta_correcta, presence: true, if: -> { respuesta_corta? }
  validate :validar_opciones_correctas, if: -> { opcion_multiple? || verdadero_falso? }
  validate :validar_emparejamiento, if: -> { emparejamiento? }

  enum tipo: {
    opcion_multiple: 0,
    verdadero_falso: 1,
    respuesta_corta: 2,
    emparejamiento: 3,
    multiple_respuesta: 4  # Nuevo tipo: selección múltiple con varias respuestas correctas
  }

  default_scope { order(orden: :asc) }
  
  # Callbacks
  after_save :procesar_imagen
  before_validation :inicializar_orden, on: :create

  # Métodos auxiliares
  def requiere_opciones?
    opcion_multiple? || verdadero_falso? || emparejamiento? || multiple_respuesta?
  end

  def tiene_opciones_suficientes?
    return true unless requiere_opciones?
    
    if opcion_multiple? || multiple_respuesta?
      opciones.count >= 2
    elsif verdadero_falso?
      opciones.count == 2
    elsif emparejamiento?
      # Para emparejamiento, necesitamos al menos 2 pares (4 opciones en total)
      terminos = opciones.where(es_termino: true).count
      definiciones = opciones.where(es_termino: false).count
      terminos >= 2 && definiciones >= 2 && terminos == definiciones
    else
      true
    end
  end

  def tiene_respuesta_correcta?
    if opcion_multiple? || verdadero_falso?
      opciones.where(es_correcta: true).exists?
    elsif multiple_respuesta?
      opciones.where(es_correcta: true).count >= 1
    elsif respuesta_corta?
      respuesta_correcta.present?
    elsif emparejamiento?
      # Para emparejamiento, verificamos que todos los términos tengan un par relacionado
      terminos = opciones.where(es_termino: true)
      terminos.all? { |t| t.par_relacionado.present? && t.par_relacionado["id"].present? }
    else
      false
    end
  end
  
  # Devuelve las opciones organizadas para emparejamiento
  def terminos
    return [] unless emparejamiento?
    opciones.where(es_termino: true).order(:orden)
  end
  
  def definiciones
    return [] unless emparejamiento?
    opciones.where(es_termino: false).order(:orden)
  end
  
  # Verifica si las relaciones de emparejamiento están completas y correctas
  def emparejamiento_completo?
    return false unless emparejamiento?
    
    terminos_list = terminos
    definiciones_list = definiciones
    
    return false if terminos_list.size != definiciones_list.size || terminos_list.empty?
    
    terminos_list.all? { |t| t.par_relacionado.present? && t.par_relacionado["id"].present? }
  end
  
  # Devuelve una versión legible del tipo de pregunta
  def tipo_display
    case tipo
    when 'opcion_multiple'
      'Opción Múltiple'
    when 'verdadero_falso'
      'Verdadero/Falso'
    when 'respuesta_corta'
      'Respuesta Corta'
    when 'emparejamiento'
      'Términos Pareados'
    when 'multiple_respuesta'
      'Selección Múltiple (Varias correctas)'
    else
      tipo.to_s.humanize
    end
  end
  
  def icono_tipo
    case tipo
    when 'opcion_multiple'
      'fa-list-ul'
    when 'verdadero_falso'
      'fa-toggle-on'
    when 'respuesta_corta'
      'fa-font'
    when 'emparejamiento'
      'fa-link'
    when 'multiple_respuesta'
      'fa-check-square'
    else
      'fa-question'
    end
  end
  
  def siguiente_pregunta
    quiz.preguntas.where('orden > ?', orden).order(orden: :asc).first
  end
  
  def pregunta_anterior
    quiz.preguntas.where('orden < ?', orden).order(orden: :desc).first
  end
  
  def opciones_en_orden_aleatorio
    opciones.to_a.shuffle
  end
  
  # Permite calcular la tasa de error para esta pregunta
  def tasa_error
    total_respuestas = respuestas.joins(:intento_quiz).where(intentos_quiz: { estado: :completado }).count
    return 0 if total_respuestas.zero?
    
    respuestas_incorrectas = respuestas.joins(:intento_quiz)
                                      .where(intentos_quiz: { estado: :completado })
                                      .where(es_correcta: false)
                                      .count
                                      
    (respuestas_incorrectas.to_f / total_respuestas * 100).round(1)
  end
  
  # Tiempo promedio de respuesta para esta pregunta (en segundos)
  def tiempo_promedio_respuesta
    respuestas.joins(:intento_quiz)
              .where(intentos_quiz: { estado: :completado })
              .average('EXTRACT(EPOCH FROM (respuestas_quiz.created_at - intentos_quiz.iniciado_en))')
              &.to_i || 0
  end
  
  private
  
  def validar_opciones_correctas
    if opcion_multiple? && opciones.select(&:es_correcta?).count != 1
      errors.add(:base, 'Debe haber exactamente una opción correcta para preguntas de opción múltiple')
    elsif verdadero_falso? && opciones.select(&:es_correcta?).count != 1
      errors.add(:base, 'Debe haber exactamente una opción correcta para preguntas de verdadero/falso')
    elsif multiple_respuesta? && opciones.select(&:es_correcta?).count < 1
      errors.add(:base, 'Debe haber al menos una opción correcta para preguntas de selección múltiple')
    end
  end
  
  def validar_emparejamiento
    if emparejamiento?
      terminos_count = opciones.select(&:es_termino?).count
      definiciones_count = opciones.reject(&:es_termino?).count
      
      if terminos_count != definiciones_count
        errors.add(:base, 'Debe haber igual número de términos y definiciones')
      elsif terminos_count < 2
        errors.add(:base, 'Debe haber al menos 2 pares de términos y definiciones')
      end
    end
  end
  
  def procesar_imagen
    if remove_imagen == '1' && imagen.attached?
      imagen.purge
    end
  end
  
  def inicializar_orden
    return if orden.present?
    
    ultimo_orden = quiz.preguntas.maximum(:orden) || 0
    self.orden = ultimo_orden + 1
  end
end
