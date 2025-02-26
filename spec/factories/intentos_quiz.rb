# spec/factories/intentos_quiz.rb
FactoryBot.define do
  factory :intento_quiz do
    association :quiz
    association :usuario
    estado { :en_progreso }
    numero_intento { 1 }
    iniciado_en { Time.current }
  end
end