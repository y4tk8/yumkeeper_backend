require "rails_helper"

RSpec.describe "GET /api/v1/users/:user_id/recipes/:id", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:recipe) { create(:recipe, :with_ingredients, :with_video, user: user) }
  let(:auth_headers) { user.create_new_auth_token } # Devise Token Authの認証情報

  before do
    get "/api/v1/users/#{user.id}/recipes/#{recipe.id}", headers: auth_headers
  end

  context "有効なユーザーが自分のレシピ詳細を取得する場合" do
    it "リクエストが成功し、ステータス200が返る" do
      expect(response).to have_http_status(:ok)
    end

    it "正しいレシピデータが返る" do
      expect(response.parsed_body["recipe"]["id"]).to eq(recipe.id)
      expect(response.parsed_body["recipe"]["name"]).to eq(recipe.name)
      expect(response.parsed_body["recipe"]["notes"]).to eq(recipe.notes)
      expect(Time.parse(response.parsed_body["recipe"]["created_at"])).to be_within(1.second).of(recipe.created_at)
      expect(Time.parse(response.parsed_body["recipe"]["created_at"])).to be_within(1.second).of(recipe.updated_at)
    end

    it "正しい材料データが返る" do
      expected_ingredients = recipe.ingredients.map do |ingredient|
        {
          "id" => ingredient.id,
          "name" => ingredient.name,
          "quantity" => ingredient.quantity,
          "unit" => ingredient.unit,
          "category" => ingredient.category
        }
      end

      expect(response.parsed_body["recipe"]["ingredients"]).to match_array(expected_ingredients)
    end

    it "正しい動画データが返る" do
      video_response = response.parsed_body["recipe"]["video"]
      expected_video = {
        "id" => recipe.video.id,
        "video_id" => recipe.video.video_id,
        "etag" => recipe.video.etag,
        "status" => recipe.video.status,
        "cached_at" => recipe.video.cached_at
      }

      expect(video_response["id"]).to eq(expected_video["id"])
      expect(video_response["video_id"]).to eq(expected_video["video_id"])
      expect(video_response["etag"]).to eq(expected_video["etag"])
      expect(video_response["status"]).to eq(expected_video["status"])
      expect(Time.parse(video_response["cached_at"])).to be_within(1.second).of(expected_video["cached_at"])
    end
  end

  context "自分が保有していないレシピ詳細を取得しようとした場合" do
    let(:other_user) { create(:user, :confirmed) }
    let!(:other_recipe) { create(:recipe, user: other_user) }

    it "レシピ取得に失敗し、ステータス403が返る" do
      get "/api/v1/users/#{user.id}/recipes/#{other_recipe.id}", headers: auth_headers

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body["error"]).to eq("レシピが見つかりません")
    end
  end
end
