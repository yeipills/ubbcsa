module QuizzesHelper
  def estado_quiz_badge(estado)
    case estado
    when 'borrador'
      'bg-gray-100 text-gray-800'
    when 'publicado'
      'bg-green-100 text-green-800'
    when 'cerrado'
      'bg-red-100 text-red-800'
    end
  end

  def formato_tiempo(segundos)
    return '--:--' unless segundos

    horas = (segundos / 3600).floor
    minutos = ((segundos % 3600) / 60).floor
    segundos_restantes = segundos % 60

    if horas > 0
      format('%02d:%02d:%02d', horas, minutos, segundos_restantes)
    else
      format('%02d:%02d', minutos, segundos_restantes)
    end
  end

  def progreso_quiz(intento)
    return 0 unless intento&.respuestas&.any?

    ((intento.respuestas.count.to_f / intento.quiz.preguntas.count) * 100).round
  end

  def formato_duracion(quiz)
    return 'Sin límite' unless quiz.tiempo_limite

    "#{quiz.tiempo_limite} min"
  end

  def estado_disponibilidad(quiz, usuario)
    if !quiz.publicado?
      {
        texto: 'No disponible',
        color: 'text-gray-500',
        icono: 'calendar-x'
      }
    elsif Time.current < quiz.fecha_inicio
      {
        texto: "Disponible #{l quiz.fecha_inicio, format: :short}",
        color: 'text-yellow-500',
        icono: 'calendar-clock'
      }
    elsif Time.current > quiz.fecha_fin
      {
        texto: 'Finalizado',
        color: 'text-red-500',
        icono: 'calendar-off'
      }
    elsif !quiz.intentos_disponibles_para?(usuario)
      {
        texto: 'Sin intentos disponibles',
        color: 'text-orange-500',
        icono: 'calendar-x'
      }
    else
      {
        texto: "Disponible hasta #{l quiz.fecha_fin, format: :short}",
        color: 'text-green-500',
        icono: 'calendar-check'
      }
    end
  end

  def tipo_pregunta_icon(tipo)
    case tipo
    when 'opcion_multiple'
      'list-checks'
    when 'verdadero_falso'
      'check-square'
    when 'respuesta_corta'
      'text'
    end
  end

  def rango_puntaje_color(puntaje)
    return 'bg-gray-700 text-gray-300' unless puntaje

    case puntaje
    when 0..40
      'bg-red-900 text-red-300'
    when 40..60
      'bg-orange-900 text-orange-300'
    when 60..80
      'bg-yellow-900 text-yellow-300'
    else
      'bg-green-900 text-green-300'
    end
  end
end
