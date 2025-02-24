require "rails_helper"

RSpec.describe "Api::V1::Recipes", type: :request do
  let(:user) { create(:user, :confirmed) } # メール認証済みのユーザー
  let(:other_user) { create(:user, :confirmed) } # 他のユーザー
  let!(:recipes) { create_list(:recipe, 5, user: user) } # レシピを5つ作成
  let(:headers) { user.create_new_auth_token } # Devise Token Authの認証情報

  # ユーザーごとのレシピ一覧を取得
  describe "GET /api/v1/users/:user_id/recipes" do
    context "有効なユーザーが自分のレシピ一覧を取得する場合" do
      before do
        get "/api/v1/users/#{user.id}/recipes", headers: headers
      end

      it "リクエストが成功し、ステータス200が返る" do
        expect(response).to have_http_status(:ok)
      end

      it "作成した全てのレシピとカウントを取得する" do
        expect(response.parsed_body["recipes"].length).to eq(5)
        expect(response.parsed_body["recipe_count"]).to eq(5)
      end

      it "作成日時の降順でレシピを取得する" do
        expect(response.parsed_body["recipes"].pluck("id")).to eq(recipes.sort_by(&:created_at).reverse.pluck(:id))
      end
    end

    context "他のユーザーのレシピ一覧を取得しようとした場合" do
      before do
        get "/api/v1/users/#{other_user.id}/recipes", headers: headers
      end

      it "レシピ取得に失敗し、ステータス403が返る" do
        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to eq("アクセス権限がありません。")
      end
    end

    context "無効なユーザー（未認証ユーザー）の場合" do
      before do
        get "/api/v1/users/#{user.id}/recipes" # 認証ヘッダーなし
      end

      it "認証に失敗し、ステータス401が返る" do
        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("ログインもしくはアカウント登録してください。")
      end
    end
  end
end
