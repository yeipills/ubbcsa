require 'rails_helper'

RSpec.describe "Laboratorios", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/laboratorios/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/laboratorios/show"
      expect(response).to have_http_status(:success)
    end
  end

end
