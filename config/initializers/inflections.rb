# Configuración de inflection para modelos
ActiveSupport::Inflector.inflections(:en) do |inflect|
  # Configuraciones generales
  inflect.irregular 'quiz', 'quizzes'
  
  # Configuraciones específicas para modelos compuestos
  inflect.irregular 'quiz_pregunta', 'quiz_preguntas'
  inflect.irregular 'quiz_opcion', 'quiz_opciones'
  inflect.irregular 'intento_quiz', 'intentos_quiz'
  inflect.irregular 'respuesta_quiz', 'respuestas_quiz'
  inflect.irregular 'evento_intento', 'eventos_intento'
  inflect.irregular 'quiz_result', 'quiz_results'
end
