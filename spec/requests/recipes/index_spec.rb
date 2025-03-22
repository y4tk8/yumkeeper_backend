require "rails_helper"

RSpec.describe "GET /api/v1/users/:user_id/recipes", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:auth_headers) { user.create_new_auth_token } # Devise Token Authの認証情報

  context "有効なユーザーが自分のレシピ一覧を取得する場合" do
    let!(:recipes) { create_list(:recipe, 5, :with_video, user: user) }

    before do
      get "/api/v1/users/#{user.id}/recipes", headers: auth_headers
    end

    it "ステータス200が返り、作成した全てのレシピを取得する" do
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["recipes"].size).to eq(5)
    end

    it "各レシピに動画サムネイルが1件ずつ紐付いている" do
      response.parsed_body["recipes"].each do |recipe|
        expect(recipe["thumbnail_url"]).to be_present
      end
    end

    it "更新日時の降順でレシピを取得する" do
      expect(response.parsed_body["recipes"].pluck("id")).to eq(recipes.sort_by(&:updated_at).reverse.pluck(:id))
    end

    it "レスポンスヘッダーにページネーション情報を含む" do
      expect(response.headers["Current-Page"]).to eq("1")
      expect(response.headers["Page-Items"]).to eq("20")
      expect(response.headers["Total-Count"]).to eq("5")
      expect(response.headers["Total-Pages"]).to eq("1")
    end
  end

  context "別のユーザーのレシピ一覧を取得しようとした場合" do
    let(:other_user) { create(:user, :confirmed) }

    it "レシピ取得に失敗し、ステータス403が返る" do
      get "/api/v1/users/#{other_user.id}/recipes", headers: auth_headers

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body["error"]).to eq("アクセス権限がありません。")
    end
  end

  context "無効なユーザー（未認証ユーザー）の場合" do
    it "認証に失敗し、ステータス401が返る" do
      get "/api/v1/users/#{user.id}/recipes" # 認証ヘッダーなし

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["errors"]).to include("ログインもしくはアカウント登録してください。")
    end
  end
end
