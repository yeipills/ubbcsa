# db/seeds.rb
puts "Limpiando registros anteriores..."
Quiz.destroy_all
Curso.destroy_all
Usuario.destroy_all
Laboratorio.destroy_all

puts "Creando usuario profesor..."
profesor = Usuario.create!(
  email: 'profesor@example.com',
  password: '123456',
  nombre_completo: 'Profesor Demo',
  rol: 'profesor'
)

puts "Creando curso..."
curso = Curso.create!(
  nombre: 'Ciberseguridad Básica',
  codigo: 'CB101',
  descripcion: 'Curso introductorio de ciberseguridad',
  profesor: profesor
)

puts "Creando laboratorio..."
laboratorio = Laboratorio.create!(
  nombre: 'Lab de Pruebas',
  descripcion: 'Laboratorio inicial',
  curso: curso,
  tipo: 'practica'
)

puts "Creando quiz de ejemplo..."
quiz = Quiz.create!(
  titulo: "Introducción a la Seguridad Informática",
  descripcion: "Quiz básico sobre conceptos de seguridad",
  curso: curso,
  laboratorio: laboratorio,
  usuario: profesor,
  estado: :publicado,
  tiempo_limite: 30,
  intentos_permitidos: 2,
  fecha_inicio: Time.current,
  fecha_fin: 1.week.from_now
)

puts "Creando preguntas..."
pregunta1 = quiz.preguntas.create!(
  contenido: "¿Qué es un ataque de denegación de servicio (DoS)?",
  tipo: :opcion_multiple,
  puntaje: 5,
  orden: 1
)

pregunta1.opciones.create!([
  { contenido: "Un ataque que sobrecarga los recursos del sistema", es_correcta: true, orden: 1 },
  { contenido: "Un tipo de virus informático", es_correcta: false, orden: 2 },
  { contenido: "Una técnica de encriptación", es_correcta: false, orden: 3 }
])

puts "Seeds completados exitosamente!"