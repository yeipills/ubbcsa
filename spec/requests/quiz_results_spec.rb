require 'rails_helper'

RSpec.describe "QuizResults", type: :request do
  describe "GET /show" do
    it "returns http success" do
      get "/quiz_results/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /index" do
    it "returns http success" do
      get "/quiz_results/index"
      expect(response).to have_http_status(:success)
    end
  end

end
