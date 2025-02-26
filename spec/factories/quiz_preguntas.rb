# spec/factories/quiz_preguntas.rb
FactoryBot.define do
  factory :quiz_pregunta do
    association :quiz
    contenido { Faker::Lorem.question }
    tipo { :opcion_multiple }
    puntaje { rand(1..5) }
    orden { rand(1..10) }
    activa { true }
  end
end