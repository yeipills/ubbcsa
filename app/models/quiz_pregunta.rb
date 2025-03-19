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

  validates :contenido, presence: { message: "El enunciado de la pregunta no puede estar vacío" }
  validates :puntaje, presence: { message: "El puntaje es obligatorio" }, 
                     numericality: { greater_than: 0, message: "El puntaje debe ser mayor que cero" }
  validates :orden, presence: true, uniqueness: { scope: :quiz_id, message: "El orden debe ser único dentro del quiz" }
  validates :respuesta_correcta, presence: { message: "La respuesta correcta es obligatoria para preguntas de respuesta corta" }, 
                               if: -> { respuesta_corta? }
  validate :validar_opciones_correctas, if: -> { opcion_multiple? || verdadero_falso? || multiple_respuesta? }
  validate :validar_emparejamiento, if: -> { emparejamiento? }
  validate :validar_opciones_suficientes, if: -> { requiere_opciones? }

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
  
  # Obtiene la lista de preguntas adyacentes (anterior y siguiente) para navegación
  def preguntas_adyacentes
    {
      anterior: pregunta_anterior,
      siguiente: siguiente_pregunta
    }
  end

  # Verifica si una respuesta es correcta
  # @param respuesta [String|Integer|Array] La respuesta proporcionada
  # @return [Boolean] Si la respuesta es correcta o no
  def verificar_respuesta(respuesta)
    case tipo
    when 'opcion_multiple', 'verdadero_falso'
      # Para opciones múltiples, la respuesta debe ser el ID de la opción correcta
      opcion_id = respuesta.to_i
      opciones.find_by(id: opcion_id)&.es_correcta? || false
    when 'respuesta_corta'
      # Para respuesta corta, comparar ignorando mayúsculas/minúsculas y espacios
      respuesta_normalizada = respuesta.to_s.strip.downcase
      respuesta_correcta_normalizada = respuesta_correcta.strip.downcase
      respuesta_normalizada == respuesta_correcta_normalizada
    when 'multiple_respuesta'
      # Para selección múltiple, todas las opciones seleccionadas deben ser correctas
      # y todas las correctas deben estar seleccionadas
      seleccionadas = Array(respuesta).map(&:to_i)
      correctas = opciones.where(es_correcta: true).pluck(:id)
      
      # Verificar que todas las seleccionadas son correctas
      return false if seleccionadas.any? { |id| !correctas.include?(id) }
      
      # Verificar que todas las correctas están seleccionadas
      correctas.all? { |id| seleccionadas.include?(id) }
    when 'emparejamiento'
      # Para emparejamiento, verificar que todos los pares estén bien asociados
      emparejamientos = JSON.parse(respuesta) rescue {}
      return false if emparejamientos.empty?
      
      # Iterar por cada término y verificar su definición
      terminos.all? do |termino|
        next false unless termino.par_relacionado.present? && termino.par_relacionado["id"].present?
        
        definicion_id = termino.par_relacionado["id"].to_i
        emparejamientos[termino.id.to_s] == definicion_id.to_s
      end
    else
      false
    end
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
  
  def validar_opciones_suficientes
    unless tiene_opciones_suficientes?
      case tipo
      when 'opcion_multiple', 'multiple_respuesta'
        errors.add(:base, 'Debe definir al menos 2 opciones para este tipo de pregunta')
      when 'verdadero_falso'
        errors.add(:base, 'Debe definir exactamente 2 opciones para preguntas de verdadero/falso')
      when 'emparejamiento'
        errors.add(:base, 'Debe definir al menos 2 pares de términos y definiciones')
      end
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
