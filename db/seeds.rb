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
