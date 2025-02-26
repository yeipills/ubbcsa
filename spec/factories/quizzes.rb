# spec/factories/quizzes.rb
FactoryBot.define do
  factory :quiz do
    titulo { Faker::Educator.course_name }
    descripcion { Faker::Lorem.paragraph }
    association :curso
    association :laboratorio
    association :usuario
    estado { :borrador }
    tiempo_limite { 30 }
    intentos_permitidos { 1 }
    activo { true }
    fecha_inicio { Time.current }
    fecha_fin { 1.week.from_now }
  end
end