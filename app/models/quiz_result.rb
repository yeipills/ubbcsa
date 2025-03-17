class QuizResult < ApplicationRecord
  belongs_to :quiz
  belongs_to :usuario
  belongs_to :intento_quiz, class_name: 'IntentoQuiz', foreign_key: 'intento_quiz_id'
  
  validates :puntaje_total, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :total_preguntas, presence: true, numericality: { greater_than: 0 }
  validates :respuestas_correctas, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :intento_quiz_id, uniqueness: { scope: [:quiz_id, :usuario_id], message: "ya tiene un resultado registrado" }
  
  # Scopes
  scope :aprobados, -> { where(aprobado: true) }
  scope :mejor_puntaje, -> { order(puntaje_total: :desc).first }
  scope :por_usuario, ->(usuario_id) { where(usuario_id: usuario_id) }
  scope :por_quiz, ->(quiz_id) { where(quiz_id: quiz_id) }
  scope :recientes, -> { order(created_at: :desc) }
  
  # Calcular si aprobó según puntaje mínimo (por defecto 60%)
  def calcular_aprobacion(puntaje_minimo = 60)
    self.aprobado = puntaje_total >= puntaje_minimo
    save if changed?
    aprobado
  end
  
  # Calcular posición en ranking para este quiz
  def calcular_ranking
    mejor_puntaje = quiz.quiz_results.maximum(:puntaje_total) || 0
    return 1 if puntaje_total >= mejor_puntaje
    
    posicion = quiz.quiz_results.where('puntaje_total > ?', puntaje_total).count + 1
    update_column(:posicion_ranking, posicion)
    posicion
  end
  
  # Generar resumen con detalles del resultado
  def generar_resumen
    {
      quiz: quiz.titulo,
      estudiante: usuario.nombre_completo,
      puntaje: puntaje_total,
      estado: aprobado ? 'Aprobado' : 'Reprobado',
      fecha: created_at,
      tiempo: tiempo_segundos ? "#{(tiempo_segundos / 60.0).round(1)} minutos" : 'No registrado',
      ranking: posicion_ranking || 'No calculado',
      correctas: respuestas_correctas,
      incorrectas: total_preguntas - respuestas_correctas,
      porcentaje: "#{(respuestas_correctas.to_f / total_preguntas * 100).round(1)}%"
    }
  end
  
  # Método para actualizar desde un intento completado
  def self.crear_desde_intento(intento)
    return nil unless intento.completado?
    
    # Calcular datos necesarios
    tiempo = intento.finalizado_en && intento.iniciado_en ? 
             (intento.finalizado_en - intento.iniciado_en).to_i : nil
             
    respuestas_correctas = intento.respuestas.where(es_correcta: true).count
    total_preguntas = intento.quiz.preguntas.count
    
    # Preparar datos para análisis detallado
    preguntas_correctas = []
    preguntas_incorrectas = []
    
    intento.respuestas.includes(:pregunta).each do |respuesta|
      pregunta_data = {
        id: respuesta.pregunta_id,
        contenido: respuesta.pregunta.contenido.to_plain_text.truncate(100),
        tipo: respuesta.pregunta.tipo,
        puntaje: respuesta.pregunta.puntaje
      }
      
      if respuesta.es_correcta
        preguntas_correctas << pregunta_data
      else
        preguntas_incorrectas << pregunta_data
      end
    end
    
    # Crear o actualizar el resultado
    result = find_or_initialize_by(
      quiz_id: intento.quiz_id,
      usuario_id: intento.usuario_id,
      intento_quiz_id: intento.id
    )
    
    result.update(
      puntaje_total: intento.puntaje_total,
      total_preguntas: total_preguntas,
      respuestas_correctas: respuestas_correctas,
      tiempo_segundos: tiempo,
      preguntas_correctas: preguntas_correctas,
      preguntas_incorrectas: preguntas_incorrectas
    )
    
    # Calcular aprobación y ranking
    result.calcular_aprobacion
    result.calcular_ranking
    
    result
  end
end
