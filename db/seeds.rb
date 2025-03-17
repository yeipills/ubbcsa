# db/seeds.rb
puts 'Creando logros de ejemplo...'
tipos = %w[completar_laboratorio aprobar_quiz completar_curso asistencia]
iconos = %w[trophy medal star microscope book brain]

Usuario.all.each do |usuario|
  3.times do |i|
    tipo = tipos.sample
    Logro.create!(
      usuario: usuario,
      tipo: tipo,
      titulo: "Logro #{i + 1}",
      descripcion: "Has completado una meta importante: #{tipo}.",
      metadatos: { icono: iconos.sample }.to_json,
      otorgado_en: Time.current - rand(1..30).days,
      visible: true
    )
    puts "  Creado logro para: #{usuario.email}"
  end
end

# Update existing quizzes with new fields
puts 'Actualizando quizzes con nuevos campos...'
Quiz.find_each do |quiz|
  quiz.update(
    codigo_acceso: SecureRandom.alphanumeric(6).upcase,
    fecha_publicacion: quiz.updated_at,
    mostrar_resultados_inmediatos: [true, false].sample,
    aleatorizar_preguntas: [true, false].sample,
    aleatorizar_opciones: [true, false].sample,
    peso_calificacion: [10, 20, 30, 40, 50, 100].sample,
    instrucciones: "Instrucciones para el quiz: #{quiz.titulo}. Este quiz tiene #{quiz.preguntas.count} preguntas y un tiempo límite de #{quiz.tiempo_limite} minutos."
  )
  puts "  Actualizado quiz #{quiz.id}: #{quiz.titulo} con código #{quiz.codigo_acceso}"
end
