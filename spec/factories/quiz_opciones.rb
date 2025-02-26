# spec/factories/quiz_opciones.rb
FactoryBot.define do
  factory :quiz_opcion do
    association :pregunta, factory: :quiz_pregunta
    contenido { Faker::Lorem.sentence }
    es_correcta { [true, false].sample }
    orden { rand(1..4) }
    activa { true }
  end
end