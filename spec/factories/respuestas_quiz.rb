# spec/factories/respuestas_quiz.rb
FactoryBot.define do
  factory :respuesta_quiz do
    association :intento_quiz
    association :pregunta, factory: :quiz_pregunta
    association :opcion, factory: :quiz_opcion
    puntaje_obtenido { rand(0..5) }
    es_correcta { [true, false].sample }
    respondido_en { Time.current }
  end
end