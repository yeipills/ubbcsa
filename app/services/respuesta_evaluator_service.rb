class RespuestaEvaluatorService
  # Evalúa una respuesta y devuelve el resultado
  def self.evaluar(respuesta)
    case respuesta.pregunta.tipo
    when 'opcion_multiple', 'verdadero_falso'
      evaluar_opcion_simple(respuesta)
    when 'multiple_respuesta'
      evaluar_multiple_respuesta(respuesta)
    when 'respuesta_corta'
      evaluar_respuesta_corta(respuesta)
    when 'emparejamiento'
      evaluar_emparejamiento(respuesta)
    else
      { correcto: false, puntaje: 0 }
    end
  end
  
  # Evalúa respuestas de opción única (opción múltiple o verdadero/falso)
  def self.evaluar_opcion_simple(respuesta)
    return { correcto: false, puntaje: 0 } unless respuesta.opcion_id.present?
    
    opcion = respuesta.opcion
    resultado = opcion&.es_correcta? || false
    
    { 
      correcto: resultado, 
      puntaje: resultado ? respuesta.pregunta.puntaje : 0,
      retroalimentacion: resultado ? "¡Correcto!" : "Incorrecto. La respuesta correcta era: #{respuesta.pregunta.opciones.find_by(es_correcta: true)&.contenido}"
    }
  end
  
  # Evalúa respuestas de selección múltiple (múltiples correctas posibles)
  def self.evaluar_multiple_respuesta(respuesta)
    return { correcto: false, puntaje: 0 } unless respuesta.opciones_multiples.present?
    
    begin
      # Obtener IDs seleccionados y opciones
      ids_seleccionados = JSON.parse(respuesta.opciones_multiples)
      opciones = respuesta.pregunta.opciones
      opciones_correctas = opciones.select(&:es_correcta?)
      opciones_incorrectas = opciones.reject(&:es_correcta?)
      
      # Verificar selecciones
      selecciono_todas_correctas = opciones_correctas.all? { |oc| ids_seleccionados.include?(oc.id) }
      selecciono_alguna_incorrecta = opciones_incorrectas.any? { |oi| ids_seleccionados.include?(oi.id) }
      
      # Calcular puntaje parcial
      opciones_seleccionadas_correctamente = ids_seleccionados.count { |id| 
        opcion = opciones.find { |o| o.id == id }
        opcion&.es_correcta?
      }
      opciones_incorrectas_seleccionadas = ids_seleccionados.count - opciones_seleccionadas_correctamente
      
      if selecciono_todas_correctas && !selecciono_alguna_incorrecta
        # 100% correcto
        porcentaje = 1.0
        correcto = true
      elsif selecciono_todas_correctas && selecciono_alguna_incorrecta
        # Seleccionó todas las correctas pero también incorrectas
        porcentaje = [0, 1 - (opciones_incorrectas_seleccionadas.to_f / opciones_incorrectas.count)].max
        correcto = porcentaje >= 0.5
      else
        # No seleccionó todas las correctas
        porcentaje = opciones_seleccionadas_correctamente.to_f / opciones_correctas.count
        porcentaje = [0, porcentaje - (opciones_incorrectas_seleccionadas.to_f / opciones_incorrectas.count)].max
        correcto = porcentaje >= 0.5
      end
      
      # Información de retroalimentación
      opciones_faltantes = []
      opciones_incorrectas_seleccionadas = []
      
      opciones_correctas.each do |oc|
        opciones_faltantes << oc.contenido unless ids_seleccionados.include?(oc.id)
      end
      
      ids_seleccionados.each do |id|
        opcion = opciones.find { |o| o.id == id }
        if opcion && !opcion.es_correcta?
          opciones_incorrectas_seleccionadas << opcion.contenido
        end
      end
      
      retroalimentacion = ""
      if correcto
        retroalimentacion = "¡Respuesta correcta!"
        retroalimentacion += " (Parcialmente correcta)" if porcentaje < 1.0
      else
        retroalimentacion = "Respuesta incorrecta. "
        if opciones_faltantes.any?
          retroalimentacion += "No seleccionaste: #{opciones_faltantes.join(', ')}. "
        end
        if opciones_incorrectas_seleccionadas.any?
          retroalimentacion += "Selecciones incorrectas: #{opciones_incorrectas_seleccionadas.join(', ')}."
        end
      end
      
      {
        correcto: correcto,
        puntaje: (respuesta.pregunta.puntaje * porcentaje).round(2),
        retroalimentacion: retroalimentacion,
        porcentaje: (porcentaje * 100).round(1),
        faltantes: opciones_faltantes,
        incorrectas: opciones_incorrectas_seleccionadas
      }
    rescue JSON::ParserError
      { correcto: false, puntaje: 0, retroalimentacion: "Error en el formato de la respuesta" }
    end
  end
  
  # Evalúa respuestas de texto corto
  def self.evaluar_respuesta_corta(respuesta)
    return { correcto: false, puntaje: 0 } unless respuesta.respuesta_texto.present?
    
    pregunta = respuesta.pregunta
    texto_respuesta = respuesta.respuesta_texto.to_s.downcase.strip
    texto_correcto = pregunta.respuesta_correcta.to_s.downcase.strip
    
    # Coincidencia exacta
    if texto_respuesta == texto_correcto
      return { 
        correcto: true, 
        puntaje: pregunta.puntaje,
        retroalimentacion: "¡Respuesta correcta!",
        metodo: "coincidencia_exacta"
      }
    end
    
    # Coincidencia aproximada usando algoritmo de Levenshtein
    distancia = calcular_distancia_levenshtein(texto_respuesta, texto_correcto)
    umbral_distancia = [texto_correcto.length * 0.2, 2].min
    
    if distancia <= umbral_distancia
      return {
        correcto: true,
        puntaje: pregunta.puntaje * 0.9, # Ligera penalización por no ser exacta
        retroalimentacion: "¡Respuesta aceptada! (La respuesta exacta era: #{pregunta.respuesta_correcta})",
        metodo: "coincidencia_aproximada",
        distancia: distancia
      }
    end
    
    # Si hay múltiples respuestas correctas posibles, separadas por ;
    if texto_correcto.include?(';')
      respuestas_alternativas = texto_correcto.split(';').map(&:strip)
      
      respuestas_alternativas.each do |alternativa|
        if texto_respuesta == alternativa
          return {
            correcto: true,
            puntaje: pregunta.puntaje,
            retroalimentacion: "¡Respuesta correcta!",
            metodo: "alternativa_exacta"
          }
        end
        
        # También verificar coincidencia aproximada con alternativas
        distancia_alt = calcular_distancia_levenshtein(texto_respuesta, alternativa)
        umbral_alt = [alternativa.length * 0.2, 2].min
        
        if distancia_alt <= umbral_alt
          return {
            correcto: true,
            puntaje: pregunta.puntaje * 0.9,
            retroalimentacion: "¡Respuesta aceptada! (Una respuesta exacta era: #{alternativa})",
            metodo: "alternativa_aproximada",
            distancia: distancia_alt
          }
        end
      end
    end
    
    # Respuesta incorrecta
    {
      correcto: false,
      puntaje: 0,
      retroalimentacion: "Respuesta incorrecta. La respuesta correcta era: #{pregunta.respuesta_correcta}",
      metodo: "sin_coincidencia",
      distancia: distancia
    }
  end
  
  # Evalúa respuestas de emparejamiento
  def self.evaluar_emparejamiento(respuesta)
    return { correcto: false, puntaje: 0 } unless respuesta.respuesta_texto.present?
    
    begin
      # Parsear los pares seleccionados desde la respuesta
      pares_seleccionados = JSON.parse(respuesta.respuesta_texto)
      pregunta = respuesta.pregunta
      terminos = pregunta.terminos
      
      # Contadores para cálculo de puntaje
      total_terminos = terminos.count
      aciertos = 0
      
      # Detalles de retroalimentación
      pares_correctos = []
      pares_incorrectos = []
      
      # Verificar cada par
      terminos.each do |termino|
        par_correcto_id = termino.par_relacionado["id"].to_s
        par_seleccionado_id = pares_seleccionados[termino.id.to_s].to_s
        
        # Verificar si el par es correcto
        if par_correcto_id == par_seleccionado_id
          aciertos += 1
          pares_correctos << {
            termino: termino.contenido,
            definicion: pregunta.opciones.find_by(id: par_correcto_id)&.contenido
          }
        else
          seleccion = pregunta.opciones.find_by(id: par_seleccionado_id)&.contenido || "No seleccionado"
          correcto = pregunta.opciones.find_by(id: par_correcto_id)&.contenido || "No encontrado"
          
          pares_incorrectos << {
            termino: termino.contenido,
            seleccion: seleccion,
            correcto: correcto
          }
        end
      end
      
      # Calcular puntaje y determinar si es correcto
      porcentaje_acierto = total_terminos > 0 ? (aciertos.to_f / total_terminos) : 0
      puntaje = (pregunta.puntaje * porcentaje_acierto).round(2)
      correcto = porcentaje_acierto >= 0.8 # 80% o más se considera correcto
      
      # Generar retroalimentación
      if correcto
        if porcentaje_acierto == 1.0
          retroalimentacion = "¡Emparejamiento perfecto! Has relacionado correctamente todos los términos."
        else
          retroalimentacion = "¡Bien hecho! Has relacionado correctamente #{aciertos} de #{total_terminos} términos."
        end
      else
        retroalimentacion = "Has relacionado correctamente #{aciertos} de #{total_terminos} términos. "
        retroalimentacion += "Las relaciones correctas son: "
        terminos.each do |termino|
          definicion = pregunta.opciones.find_by(id: termino.par_relacionado["id"])&.contenido
          retroalimentacion += "#{termino.contenido} - #{definicion}; "
        end
      end
      
      {
        correcto: correcto,
        puntaje: puntaje,
        retroalimentacion: retroalimentacion,
        porcentaje: (porcentaje_acierto * 100).round(1),
        aciertos: aciertos,
        total: total_terminos,
        pares_correctos: pares_correctos,
        pares_incorrectos: pares_incorrectos
      }
    rescue JSON::ParserError
      { correcto: false, puntaje: 0, retroalimentacion: "Error en el formato de la respuesta" }
    end
  end
  
  private
  
  # Algoritmo de Levenshtein para calcular distancia entre cadenas
  def self.calcular_distancia_levenshtein(s, t)
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
end