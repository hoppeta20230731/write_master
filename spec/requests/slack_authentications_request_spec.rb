require 'rails_helper'

RSpec.describe "SlackAuthentications", type: :request do

  describe "GET /create" do
    it "returns http success" do
      get "/slack_authentications/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /failure" do
    it "returns http success" do
      get "/slack_authentications/failure"
      expect(response).to have_http_status(:success)
    end
  end

end
