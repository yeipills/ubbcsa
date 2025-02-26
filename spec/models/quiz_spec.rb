# spec/models/quiz_spec.rb
require 'rails_helper'

RSpec.describe Quiz, type: :model do
  describe 'associations' do
    it { should belong_to(:curso) }
    it { should belong_to(:laboratorio) }
    it { should belong_to(:usuario) }
    it { should have_many(:preguntas) }
    it { should have_many(:intentos) }
  end

  describe 'validations' do
    it { should validate_presence_of(:titulo) }
    it { should validate_numericality_of(:intentos_permitidos).is_greater_than(0) }
  end

  describe 'scopes' do
    it 'should return active quizzes' do
      active_quiz = create(:quiz, activo: true)
      inactive_quiz = create(:quiz, activo: false)
      expect(Quiz.activos).to include(active_quiz)
      expect(Quiz.activos).not_to include(inactive_quiz)
    end
  end
end