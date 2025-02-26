
# spec/models/quiz_pregunta_spec.rb
require 'rails_helper'

RSpec.describe QuizPregunta, type: :model do
  describe 'associations' do
    it { should belong_to(:quiz) }
    it { should have_many(:opciones) }
    it { should have_many(:respuestas) }
  end

  describe 'validations' do
    it { should validate_presence_of(:contenido) }
    it { should validate_presence_of(:puntaje) }
    it { should validate_numericality_of(:puntaje).is_greater_than(0) }
  end

  describe 'default scope' do
    it 'orders by orden asc' do
      quiz = create(:quiz)
      pregunta2 = create(:quiz_pregunta, quiz: quiz, orden: 2)
      pregunta1 = create(:quiz_pregunta, quiz: quiz, orden: 1)
      expect(quiz.preguntas.to_a).to eq([pregunta1, pregunta2])
    end
  end
end