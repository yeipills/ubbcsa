# lib/tasks/quiz.rake
namespace :quiz do
  desc "Cierra los quizzes vencidos"
  task cerrar_vencidos: :environment do
    Quiz.where("fecha_fin < ?", Time.current).update_all(estado: :cerrado)
  end

  desc "Envía recordatorios para quizzes próximos a vencer"
  task enviar_recordatorios: :environment do
    Quiz.publicado.where("fecha_fin < ?", 24.hours.from_now).find_each do |quiz|
      quiz.curso.estudiantes.each do |estudiante|
        QuizMailer.recordatorio_quiz(estudiante, quiz).deliver_later
      end
    end
  end
  
  desc "Crear quiz de prueba con diferentes tipos de preguntas"
  task crear_test: :environment do
    quiz = TestQuizEmparejamiento.crear_pregunta_emparejamiento
    if quiz
      puts "Quiz de prueba creado con éxito:"
      puts "- ID: #{quiz.id}"
      puts "- Título: #{quiz.titulo}"
      puts "- Curso: #{quiz.curso.nombre}"
      puts "- Preguntas: #{quiz.preguntas.count}"
      
      # Contar por tipo (evitando el error de SQL con una consulta más simple)
      tipos = {}
      quiz.preguntas.each do |pregunta|
        tipos[pregunta.tipo] ||= 0
        tipos[pregunta.tipo] += 1
      end
      
      tipos.each do |tipo, cantidad|
        tipo_nombre = case tipo
                     when "opcion_multiple" then "Opción Múltiple"
                     when "verdadero_falso" then "Verdadero/Falso"
                     when "respuesta_corta" then "Respuesta Corta"
                     when "emparejamiento" then "Términos Pareados"
                     else "Desconocido"
                     end
        puts "  - #{tipo_nombre}: #{cantidad}"
      end
    else
      puts "Error: No se pudo crear el quiz de prueba"
      puts "Asegúrate de que existe al menos un curso y un profesor"
    end
  end
  
  desc "Listar todos los quizzes existentes"
  task listar: :environment do
    quizzes = Quiz.all.includes(:curso, :preguntas)
    if quizzes.any?
      puts "Quizzes existentes (#{quizzes.count}):"
      quizzes.each do |quiz|
        puts "- ID: #{quiz.id}, Título: #{quiz.titulo}"
        puts "  Curso: #{quiz.curso.nombre}"
        puts "  Preguntas: #{quiz.preguntas.count}"
        puts "  Estado: #{quiz.estado}"
        puts ""
      end
    else
      puts "No hay quizzes en la base de datos"
    end
  end
  
  desc "Eliminar quizzes de prueba"
  task eliminar_test: :environment do
    test_quizzes = Quiz.where("titulo LIKE ?", "%Quiz de prueba%")
    if test_quizzes.any?
      count = test_quizzes.count
      test_quizzes.destroy_all
      puts "Eliminados #{count} quizzes de prueba"
    else
      puts "No hay quizzes de prueba para eliminar"
    end
  end
  
  desc "Actualizar quizzes con nuevos campos"
  task actualizar_campos: :environment do
    puts 'Actualizando quizzes con nuevos campos...'
    Quiz.find_each do |quiz|
      codigo = SecureRandom.alphanumeric(6).upcase
      
      # Corregir fechas para quizzes que no las tienen
      quiz.fecha_inicio ||= Time.current
      quiz.fecha_fin ||= Time.current + 1.day
      
      # Usar update_columns para evitar validaciones y actualizar solo los nuevos campos
      quiz.update_columns(
        codigo_acceso: codigo,
        fecha_publicacion: quiz.updated_at || Time.current,
        mostrar_resultados_inmediatos: [true, false].sample,
        aleatorizar_preguntas: [true, false].sample,
        aleatorizar_opciones: [true, false].sample,
        peso_calificacion: [10, 20, 30, 40, 50, 100].sample,
        instrucciones: "Instrucciones para el quiz: #{quiz.titulo}. Este quiz tiene #{quiz.preguntas.count} preguntas y un tiempo límite de #{quiz.tiempo_limite} minutos."
      )
      
      puts "  Actualizado quiz #{quiz.id}: #{quiz.titulo} con código #{codigo} ✅"
    end
  end
end