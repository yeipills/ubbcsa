require 'rails_helper'

RSpec.describe "Cursos", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/cursos/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/cursos/show"
      expect(response).to have_http_status(:success)
    end
  end

end
