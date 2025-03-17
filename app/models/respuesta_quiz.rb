class RespuestaQuiz < ApplicationRecord
  self.table_name = 'respuestas_quiz'

  belongs_to :intento_quiz
  belongs_to :pregunta, class_name: 'QuizPregunta'
  belongs_to :opcion, class_name: 'QuizOpcion', optional: true
  
  # Virtual attributes
  attr_accessor :opciones_seleccionadas
  
  # Validaciones
  validates :pregunta_id, uniqueness: { scope: :intento_quiz_id }
  validate :validar_tipo_respuesta

  # Usar store_accessor para gestionar formato JSON
  store_accessor :datos_json, :pares_seleccionados, :opciones_multiples, :tiempo_respuesta_ms, 
                 :revisado_por, :comentario_revision, :estado_revision

  # Scopes
  scope :correctas, -> { where(es_correcta: true) }
  scope :incorrectas, -> { where(es_correcta: false) }
  scope :requieren_revision, -> { joins(:pregunta).where(quiz_preguntas: { tipo: :respuesta_corta }, es_correcta: nil) }
  scope :respuesta_corta, -> { joins(:pregunta).where(quiz_preguntas: { tipo: :respuesta_corta }) }
  scope :por_tipo_pregunta, ->(tipo) { joins(:pregunta).where(quiz_preguntas: { tipo: tipo }) }
 
  # Callbacks
  before_save :guardar_tiempo_respuesta
  after_save :actualizar_estadisticas_intento, if: -> { es_correcta_changed? || puntaje_obtenido_changed? }
  
  # Métodos de instancia
  def es_correcta?
    es_correcta
  end

  def valor
    case pregunta.tipo
    when 'emparejamiento'
      "Pares seleccionados"
    when 'multiple_respuesta'
      if opciones_multiples.present?
        ids = JSON.parse(opciones_multiples)
        opciones = QuizOpcion.where(id: ids).pluck(:contenido)
        opciones.join(', ')
      else
        'Sin selección'
      end
    else
      opcion_id.present? ? opcion.contenido : respuesta_texto
    end
  end

  # Verifica si la respuesta es correcta según el tipo de pregunta
  def verificar_correctitud
    case pregunta.tipo
    when 'opcion_multiple', 'verdadero_falso'
      resultado = opcion&.es_correcta? || false
      self.es_correcta = resultado
      self.puntaje_obtenido = resultado ? pregunta.puntaje : 0
    when 'multiple_respuesta'
      verificar_multiple_respuesta
    when 'respuesta_corta'
      verificar_respuesta_corta
    when 'emparejamiento'
      verificar_emparejamiento
    else
      self.es_correcta = false
      self.puntaje_obtenido = 0
    end
    
    save if changed?
    es_correcta
  end

  def tiempo_respuesta
    return datos_json['tiempo_respuesta_ms'].to_i / 1000.0 if datos_json && datos_json['tiempo_respuesta_ms'].present?
    return nil unless created_at && intento_quiz&.iniciado_en
    (created_at - intento_quiz.iniciado_en).to_i
  end
  
  def revisar!(es_correcta, puntaje, comentario = nil, revisor_id = nil)
    return false unless pregunta.respuesta_corta?
    
    self.es_correcta = es_correcta
    self.puntaje_obtenido = puntaje
    self.estado_revision = 'revisado'
    self.comentario_revision = comentario if comentario.present?
    self.revisado_por = revisor_id if revisor_id.present?
    
    save
  end
  
  def requiere_revision?
    pregunta.respuesta_corta? && es_correcta.nil?
  end
  
  def set_opciones_multiples(ids_array)
    return unless pregunta.multiple_respuesta?
    self.opciones_multiples = ids_array.to_json
  end
  
  def opciones_multiples_array
    return [] unless opciones_multiples.present?
    begin
      JSON.parse(opciones_multiples)
    rescue JSON::ParserError
      []
    end
  end
  
  # Devuelve el color de clase para mostrar esta respuesta
  def clase_color_resultado
    return 'bg-gray-200 text-gray-700' if es_correcta.nil?
    es_correcta? ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
  end
  
  # Muestra el estado breve para la respuesta
  def estado_display
    return 'Pendiente de revisión' if es_correcta.nil? && pregunta.respuesta_corta?
    es_correcta? ? 'Correcta' : 'Incorrecta'
  end
  
  private

  def validar_tipo_respuesta
    case pregunta.tipo
    when 'opcion_multiple', 'verdadero_falso'
      errors.add(:opcion_id, 'debe seleccionar una opción') if opcion_id.blank?
    when 'multiple_respuesta'
      if opciones_multiples.blank?
        errors.add(:opciones_multiples, 'debe seleccionar al menos una opción')
      end
    when 'respuesta_corta'
      errors.add(:respuesta_texto, 'no puede estar en blanco') if respuesta_texto.blank?
    when 'emparejamiento'
      if respuesta_texto.blank? || respuesta_texto !~ /\{.*\}/
        errors.add(:respuesta_texto, 'debe proporcionar pares seleccionados en formato JSON')
      end
    end
  end

  # Verifica si la respuesta a pregunta corta es correcta
  def verificar_respuesta_corta
    return false if respuesta_texto.blank?

    # Comparación básica (se puede mejorar con algoritmos más sofisticados)
    respuesta_correcta = pregunta.respuesta_correcta.to_s.downcase.strip
    respuesta_usuario = respuesta_texto.to_s.downcase.strip

    # Comprobación exacta
    coincidencia_exacta = respuesta_usuario == respuesta_correcta
    
    # Comprobación aproximada (para una experiencia más flexible)
    distancia = levenshtein_distance(respuesta_usuario, respuesta_correcta)
    coincidencia_aproximada = distancia <= [respuesta_correcta.length * 0.2, 2].min
    
    if coincidencia_exacta || coincidencia_aproximada
      self.es_correcta = true
      self.puntaje_obtenido = pregunta.puntaje
      self.estado_revision = 'automático'
    else
      # En caso de no coincidencia automática, marcamos para revisión manual
      # pero se considera incorrecta provisionalmente
      self.es_correcta = false 
      self.puntaje_obtenido = 0
      self.estado_revision = 'requiere_revisión'
    end

    es_correcta
  end

  # Algoritmo de Levenshtein para distancia entre cadenas
  def levenshtein_distance(s, t)
    m = s.length
    n = t.length
    
    return m if n == 0
    return n if m == 0
    
    d = Array.new(m + 1) { Array.new(n + 1) }
    
    (0..m).each { |i| d[i][0] = i }
    (0..n).each { |j| d[0][j] = j }
    
    (1..n).each do |j|
      (1..m).each do |i|
        d[i][j] = if s[i-1] == t[j-1]
                    d[i-1][j-1]
                  else
                    [d[i-1][j] + 1, d[i][j-1] + 1, d[i-1][j-1] + 1].min
                  end
      end
    end
    
    d[m][n]
  end
  
  # Verifica respuestas de selección múltiple con varias opciones correctas
  def verificar_multiple_respuesta
    return false if opciones_multiples.blank?
    
    begin
      # Obtener los IDs de las opciones seleccionadas
      ids_seleccionados = JSON.parse(opciones_multiples)
      return false if ids_seleccionados.empty?
      
      # Obtener todas las opciones de la pregunta
      todas_opciones = pregunta.opciones
      opciones_correctas = todas_opciones.select(&:es_correcta?)
      opciones_incorrectas = todas_opciones.reject(&:es_correcta?)
      
      # Verificar si seleccionó todas las correctas y ninguna incorrecta
      selecciono_todas_correctas = opciones_correctas.all? { |oc| ids_seleccionados.include?(oc.id) }
      selecciono_alguna_incorrecta = opciones_incorrectas.any? { |oi| ids_seleccionados.include?(oi.id) }
      
      # Calcular puntaje parcial
      total_opciones = todas_opciones.count
      opciones_seleccionadas_correctamente = ids_seleccionados.count { |id| 
        opcion = todas_opciones.find { |o| o.id == id }
        opcion&.es_correcta?
      }
      opciones_incorrectas_seleccionadas = ids_seleccionados.count - opciones_seleccionadas_correctamente
      
      # Si seleccionó todas las correctas y ninguna incorrecta, es 100% correcto
      if selecciono_todas_correctas && !selecciono_alguna_incorrecta
        self.es_correcta = true
        self.puntaje_obtenido = pregunta.puntaje
      elsif selecciono_todas_correctas && selecciono_alguna_incorrecta
        # Si seleccionó todas las correctas pero también alguna incorrecta, puntaje parcial
        porcentaje = [0, 1 - (opciones_incorrectas_seleccionadas.to_f / opciones_incorrectas.count)].max
        self.es_correcta = porcentaje >= 0.5 # Se considera correcta si obtuvo al menos 50%
        self.puntaje_obtenido = (pregunta.puntaje * porcentaje).round(2)
      else
        # Si no seleccionó todas las correctas, calcular puntaje parcial
        porcentaje = opciones_seleccionadas_correctamente.to_f / opciones_correctas.count
        porcentaje = [0, porcentaje - (opciones_incorrectas_seleccionadas.to_f / opciones_incorrectas.count)].max
        
        self.es_correcta = porcentaje >= 0.5 # Se considera correcta si obtuvo al menos 50%
        self.puntaje_obtenido = (pregunta.puntaje * porcentaje).round(2)
      end
    rescue JSON::ParserError
      self.es_correcta = false
      self.puntaje_obtenido = 0
    end
    
    es_correcta
  end

  # Verifica si los pares seleccionados son correctos
  def verificar_emparejamiento
    return false if respuesta_texto.blank?
    
    begin
      # Parsear los pares seleccionados en formato JSON
      pares_json = JSON.parse(respuesta_texto)
      
      # Obtener los términos de la pregunta
      terminos = pregunta.terminos
      
      # Contador de aciertos
      aciertos = 0
      total_terminos = terminos.count
      
      # Verificar cada par seleccionado
      terminos.each do |termino|
        par_correcto = termino.par_relacionado["id"].to_s
        par_seleccionado = pares_json[termino.id.to_s].to_s
        
        if par_correcto == par_seleccionado
          aciertos += 1
        end
      end
      
      if total_terminos > 0
        porcentaje_acierto = (aciertos.to_f / total_terminos)
        self.es_correcta = porcentaje_acierto >= 0.8 # 80% o más se considera correcto
        self.puntaje_obtenido = (pregunta.puntaje * porcentaje_acierto).round(2)
      else
        self.es_correcta = false
        self.puntaje_obtenido = 0
      end
    rescue JSON::ParserError
      self.es_correcta = false
      self.puntaje_obtenido = 0
    end
    
    es_correcta
  end
  
  def guardar_tiempo_respuesta
    return if datos_json && datos_json['tiempo_respuesta_ms'].present?
    return unless created_at && intento_quiz&.iniciado_en
    
    tiempo_ms = ((created_at - intento_quiz.iniciado_en) * 1000).to_i
    self.tiempo_respuesta_ms = tiempo_ms
  end
  
  def actualizar_estadisticas_intento
    # Si el intento está completado, recalcular los resultados
    intento_quiz.calcular_resultado if intento_quiz.completado?
  end
end
