class TestQuizEmparejamiento < ApplicationRecord
  # Este modelo es solo para pruebas de test, no afecta al funcionamiento real
  # Se puede eliminar después de las pruebas
  
  def self.crear_pregunta_emparejamiento
    # Buscar un curso y un usuario para la prueba
    curso = Curso.first
    usuario = Usuario.where(rol: 'profesor').first
    
    return unless curso && usuario
    
    # Crear quiz para pruebas (como borrador primero) con título único
    timestamp = Time.current.strftime('%Y%m%d%H%M%S')
    quiz = Quiz.create!(
      titulo: "Quiz de prueba - Términos Pareados #{timestamp}",
      descripcion: "Este es un quiz de prueba para términos pareados",
      curso: curso,
      laboratorio: curso.laboratorios.first,
      usuario: usuario,
      tiempo_limite: 30,
      intentos_permitidos: 3,
      fecha_inicio: Time.current,
      fecha_fin: Time.current + 7.days,
      estado: :borrador # Iniciamos como borrador para poder agregar preguntas
    )
    
    # Crear pregunta de emparejamiento
    pregunta = QuizPregunta.create!(
      quiz: quiz,
      contenido: "Relaciona los siguientes términos con sus definiciones",
      tipo: :emparejamiento,
      puntaje: 10,
      orden: 1
    )
    
    # Crear términos
    termino1 = pregunta.opciones.create!(
      contenido: "CPU",
      es_termino: true,
      orden: 1
    )
    
    termino2 = pregunta.opciones.create!(
      contenido: "RAM",
      es_termino: true,
      orden: 3
    )
    
    termino3 = pregunta.opciones.create!(
      contenido: "SSD",
      es_termino: true,
      orden: 5
    )
    
    # Crear definiciones
    definicion1 = pregunta.opciones.create!(
      contenido: "Unidad central de procesamiento, componente que realiza las operaciones básicas",
      es_termino: false,
      orden: 2
    )
    
    definicion2 = pregunta.opciones.create!(
      contenido: "Memoria de acceso aleatorio, almacena información temporalmente",
      es_termino: false,
      orden: 4
    )
    
    definicion3 = pregunta.opciones.create!(
      contenido: "Unidad de estado sólido, dispositivo de almacenamiento sin partes móviles",
      es_termino: false,
      orden: 6
    )
    
    # Relacionar términos con definiciones
    termino1.update(par_relacionado: { id: definicion1.id, tipo: "definicion" })
    termino2.update(par_relacionado: { id: definicion2.id, tipo: "definicion" })
    termino3.update(par_relacionado: { id: definicion3.id, tipo: "definicion" })
    
    # Agregar verdadero/falso para prueba
    pregunta_vf = QuizPregunta.create!(
      quiz: quiz,
      contenido: "¿Es la CPU el cerebro del computador?",
      tipo: :verdadero_falso,
      puntaje: 5,
      orden: 2
    )
    
    # Agregar opciones verdadero/falso
    pregunta_vf.opciones.create!(
      contenido: "Verdadero",
      es_correcta: true,
      orden: 1
    )
    
    pregunta_vf.opciones.create!(
      contenido: "Falso",
      es_correcta: false,
      orden: 2
    )
    
    # Agregar respuesta corta para prueba
    pregunta_rc = QuizPregunta.create!(
      quiz: quiz,
      contenido: "¿Qué significa la sigla HTML?",
      tipo: :respuesta_corta,
      puntaje: 5,
      orden: 3,
      respuesta_correcta: "HyperText Markup Language"
    )
    
    # Ahora que tenemos preguntas, podemos publicar el quiz
    quiz.update!(estado: :publicado)
    
    # Devolver el quiz creado
    quiz
  end
end
