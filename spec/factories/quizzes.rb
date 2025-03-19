FactoryBot.define do
  factory :quiz do
    titulo { "MyString" }
    descripcion { "MyText" }
    estado { 1 }
    tiempo_limite { 1 }
    intentos_permitidos { 1 }
    fecha_inicio { "2025-03-17 03:23:01" }
    fecha_fin { "2025-03-17 03:23:01" }
    peso_calificacion { 1 }
    codigo_acceso { "MyString" }
    aleatorizar_preguntas { false }
    aleatorizar_opciones { false }
    mostrar_resultados_inmediatos { false }
    curso { nil }
    laboratorio { nil }
    usuario { nil }
  end
end
