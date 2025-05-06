require "rails_helper"

RSpec.describe "DELETE /api/v1/users/:user_id/recipes/:id", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:auth_headers) { user.create_new_auth_token } # Devise Token Authの認証情報

  context "有効なユーザーが自分のレシピを削除する場合" do
    let!(:recipe) { create(:recipe, user: user) }

    it "ステータス200が返り、レシピがDBから物理削除される" do
      expect {
        delete "/api/v1/users/#{user.id}/recipes/#{recipe.id}", headers: auth_headers
      }.to change { Recipe.count }.by(-1)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["message"]).to eq("レシピが削除されました")
    end

    it "削除後にそのレシピにアクセスするとステータス403が返る" do
      delete "/api/v1/users/#{user.id}/recipes/#{recipe.id}", headers: auth_headers
      get "/api/v1/users/#{user.id}/recipes/#{recipe.id}", headers: auth_headers

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body["error"]).to eq("レシピが見つかりません")
    end
  end

  context "自分が保有していないレシピを削除しようとした場合" do
    let(:other_user) { create(:user, :confirmed) }
    let!(:other_recipe) { create(:recipe, user: other_user) }

    it "リクエストが失敗し、ステータス403が返る" do
      expect {
        delete "/api/v1/users/#{user.id}/recipes/#{other_recipe.id}", headers: auth_headers
      }.not_to change { Recipe.count }

      expect(response).to have_http_status(:forbidden)
    end
  end
end
