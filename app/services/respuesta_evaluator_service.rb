# app/services/respuesta_evaluator_service.rb
class RespuestaEvaluatorService
  # Constantes para configuración de evaluación
  SIMILITUD_MINIMA_RESPUESTA_CORTA = 0.85
  PUNTAJE_PARCIAL_HABILITADO = true

  class << self
    # Evalúa una respuesta y determina si es correcta y qué puntaje recibe
    #
    # @param respuesta [RespuestaQuiz] La respuesta a evaluar
    # @return [Hash] Resultado de la evaluación {:es_correcta, :puntaje, :retroalimentacion}
    def evaluar(respuesta)
      pregunta = respuesta.pregunta

      resultado = case pregunta.tipo
                  when 'opcion_multiple', 'verdadero_falso'
                    evaluar_opcion_multiple(respuesta)
                  when 'respuesta_corta'
                    evaluar_respuesta_corta(respuesta)
                  else
                    { es_correcta: false, puntaje: 0, retroalimentacion: 'Tipo de pregunta no soportado' }
                  end

      # Actualizar la respuesta con el resultado
      respuesta.update(
        es_correcta: resultado[:es_correcta],
        puntaje_obtenido: resultado[:puntaje]
      )

      resultado
    end

    private

    # Evalúa respuestas de opción múltiple o verdadero/falso
    def evaluar_opcion_multiple(respuesta)
      if respuesta.opcion_id.nil?
        return { es_correcta: false, puntaje: 0,
                 retroalimentacion: 'No se seleccionó ninguna opción' }
      end

      opcion = respuesta.opcion
      pregunta = respuesta.pregunta

      es_correcta = opcion.es_correcta?
      puntaje = es_correcta ? pregunta.puntaje : 0
      retroalimentacion = opcion.retroalimentacion.presence || pregunta.retroalimentacion.presence

      { es_correcta: es_correcta, puntaje: puntaje, retroalimentacion: retroalimentacion }
    end

    # Evalúa respuestas cortas utilizando algoritmos de comparación de texto
    def evaluar_respuesta_corta(respuesta)
      if respuesta.respuesta_texto.blank?
        return { es_correcta: false, puntaje: 0,
                 retroalimentacion: 'No se proporcionó ninguna respuesta' }
      end

      pregunta = respuesta.pregunta
      if pregunta.respuesta_correcta.blank?
        return { es_correcta: false, puntaje: 0,
                 retroalimentacion: 'No hay respuesta correcta definida' }
      end

      respuesta_usuario = normalizar_texto(respuesta.respuesta_texto)
      respuesta_correcta = normalizar_texto(pregunta.respuesta_correcta)

      similitud = calcular_similitud(respuesta_usuario, respuesta_correcta)

      # Determinar si es correcta y calcular puntaje
      es_correcta = similitud >= SIMILITUD_MINIMA_RESPUESTA_CORTA

      # Puntaje exacto o parcial según configuración
      puntaje = if es_correcta
                  pregunta.puntaje
                elsif PUNTAJE_PARCIAL_HABILITADO && similitud > 0.5
                  # Puntaje parcial basado en similitud
                  (pregunta.puntaje * similitud).round(1)
                else
                  0
                end

      retroalimentacion = pregunta.retroalimentacion.presence

      {
        es_correcta: es_correcta,
        puntaje: puntaje,
        similitud: similitud,
        retroalimentacion: retroalimentacion
      }
    end

    # Normaliza el texto para comparación (quita espacios extra, minúsculas, etc)
    def normalizar_texto(texto)
      texto.to_s.downcase.strip.gsub(/\s+/, ' ')
    end

    # Calcula similitud entre dos textos (implementación básica)
    # Usa distancia de Levenshtein normalizada
    def calcular_similitud(texto1, texto2)
      # Si son idénticos
      return 1.0 if texto1 == texto2

      # Si alguno está vacío
      return 0.0 if texto1.empty? || texto2.empty?

      # Implementación básica de distancia de Levenshtein
      m = texto1.length
      n = texto2.length

      # Crear matriz de distancias
      d = Array.new(m + 1) { Array.new(n + 1, 0) }

      # Inicializar primera fila y columna
      (0..m).each { |i| d[i][0] = i }
      (0..n).each { |j| d[0][j] = j }

      # Calcular distancia
      (1..m).each do |i|
        (1..n).each do |j|
          cost = texto1[i - 1] == texto2[j - 1] ? 0 : 1
          d[i][j] = [
            d[i - 1][j] + 1,      # eliminación
            d[i][j - 1] + 1,      # inserción
            d[i - 1][j - 1] + cost # sustitución
          ].min
        end
      end

      # Calcular similitud como 1 - (distancia normalizada)
      distancia = d[m][n].to_f
      max_longitud = [m, n].max.to_f

      1.0 - (distancia / max_longitud)
    end
  end
end
