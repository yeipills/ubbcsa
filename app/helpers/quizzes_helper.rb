# app/helpers/quizzes_helper.rb
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
    minutos = (segundos / 60).floor
    segundos_restantes = segundos % 60
    "%02d:%02d" % [minutos, segundos_restantes]
  end

  def progreso_quiz(intento)
    return 0 unless intento&.respuestas&.any?
    ((intento.respuestas.count.to_f / intento.quiz.preguntas.count) * 100).round
  end
  def formato_duracion(quiz)
    return "Sin límite" unless quiz.tiempo_limite
    "#{quiz.tiempo_limite} min"
  end
end