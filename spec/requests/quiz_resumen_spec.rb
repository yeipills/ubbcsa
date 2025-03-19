require 'rails_helper'

RSpec.describe "QuizResumen", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/quiz_resumen/index"
      expect(response).to have_http_status(:success)
    end
  end

end
