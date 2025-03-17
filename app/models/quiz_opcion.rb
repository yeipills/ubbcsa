# app/models/quiz_opcion.rb
class QuizOpcion < ApplicationRecord
  self.table_name = 'quiz_opciones' # Especificar nombre de tabla correcto

  belongs_to :pregunta, class_name: 'QuizPregunta'
  has_many :respuestas, class_name: 'RespuestaQuiz', foreign_key: 'opcion_id'

  validates :contenido, presence: true
  validates :orden, presence: true, uniqueness: { scope: :pregunta_id }

  default_scope { order(orden: :asc) }
  
  # Validación específica para preguntas de emparejamiento
  validate :validar_emparejamiento, if: -> { pregunta&.emparejamiento? }
  
  # Callback para actualizar relaciones de emparejamiento después de guardar
  after_create :actualizar_relaciones_emparejamiento, if: -> { pregunta&.emparejamiento? }
  
  # Encuentra la opción relacionada en un emparejamiento
  def opcion_relacionada
    return nil unless pregunta.emparejamiento? && par_relacionado.present? && par_relacionado["id"].present?
    
    QuizOpcion.find_by(id: par_relacionado["id"])
  end
  
  # Verifica si esta opción tiene un emparejamiento válido
  def emparejamiento_valido?
    return true unless pregunta.emparejamiento?
    
    if es_termino
      opcion_relacionada.present? && !opcion_relacionada.es_termino
    else
      # Las definiciones (no términos) no necesitan tener un par explícito
      # ya que son seleccionadas por los términos
      true
    end
  end
  
  private
  
  def validar_emparejamiento
    return unless pregunta.emparejamiento?
    
    # Si es un término nuevo, no validamos el par_relacionado
    # ya que se actualizará después de crear todos los términos y definiciones
    return if new_record?
    
    if es_termino && (!par_relacionado.present? || !par_relacionado["id"].present?)
      errors.add(:par_relacionado, "debe tener un par relacionado para un término")
    end
    
    if es_termino && par_relacionado.present? && par_relacionado["id"].present?
      # Si el ID comienza con "dummy_", estamos en proceso de creación
      return if par_relacionado["id"].to_s.start_with?("dummy_")
      
      opcion_relacionada = QuizOpcion.find_by(id: par_relacionado["id"])
      
      if opcion_relacionada.nil?
        errors.add(:par_relacionado, "la opción relacionada no existe")
      elsif opcion_relacionada.es_termino
        errors.add(:par_relacionado, "un término no puede relacionarse con otro término")
      elsif opcion_relacionada.pregunta_id != pregunta_id
        errors.add(:par_relacionado, "la opción relacionada debe pertenecer a la misma pregunta")
      end
    end
  end
  
  # Actualiza las relaciones entre términos y definiciones
  def actualizar_relaciones_emparejamiento
    return unless pregunta.emparejamiento?
    return unless es_termino
    
    # Buscar si el par_relacionado tiene un valor "dummy"
    return unless par_relacionado.present? && par_relacionado["id"].to_s.start_with?("dummy_")
    
    # Extraer el orden del dummy
    begin
      orden_definicion = par_relacionado["id"].to_s.sub("dummy_", "").to_i
      
      # Buscar la definición correspondiente
      definicion = pregunta.opciones.where(es_termino: false, orden: orden_definicion).first
      return unless definicion
      
      # Actualizar el par_relacionado con el ID real
      self.par_relacionado = { id: definicion.id, tipo: "definicion" }
      self.save(validate: false)
    rescue => e
      Rails.logger.error("Error actualizando relación de emparejamiento: #{e.message}")
    end
  end
end
