require "rails_helper"

RSpec.describe "POST /api/v1/users/:user_id/recipes", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:auth_headers) { user.create_new_auth_token } # Devise Token Authの認証情報

  context "リクエストが正常な場合" do
    let(:valid_params) do
      {
        recipe: {
          name: "カレーライス",
          notes: "カレー粉はブレンドする",
          ingredients_attributes: [
            { name: "豚肉", quantity: 300, unit: "g", category: "ingredient" },
            { name: "ニンジン", quantity: 1.5, unit: "本", category: "ingredient" },
            { name: "カレー粉", quantity: 1, unit: "箱", category: "seasoning" }
          ],
          video_attributes: {
            video_id: "abcd1234XYZ",
            etag: "etag_sample_123",
            thumbnail_url: "https://example.com/thumbnail.jpg",
            status: "public",
            is_embeddable: true,
            is_deleted: false,
            cached_at: Time.current.iso8601(3)
          }
        }
      }
    end

    it "ステータス201が返り、レシピがDBに保存される" do
      expect {
        post "/api/v1/users/#{user.id}/recipes", params: valid_params, headers: auth_headers, as: :json
      }.to change(Recipe, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["message"]).to eq("レシピが作成されました")
      expect(response.parsed_body["recipe"]["name"]).to eq("カレーライス")
      expect(response.parsed_body["recipe"]["notes"]).to eq("カレー粉はブレンドする")
    end

    it "レシピと一緒に、材料もDBに保存される" do
      expect {
        post "/api/v1/users/#{user.id}/recipes", params: valid_params, headers: auth_headers, as: :json
      }.to change(Ingredient, :count).by(3)

      expected_ingredients = [
        { "name" => "豚肉", "quantity" => 300, "unit" => "g", "category" => "ingredient" },
        { "name" => "ニンジン", "quantity" => 1.5, "unit" => "本", "category" => "ingredient" },
        { "name" => "カレー粉", "quantity" => 1, "unit" => "箱", "category" => "seasoning" }
      ]

      actual_ingredients = response.parsed_body["recipe"]["ingredients"].map do |ingredient|
        ingredient.slice("name", "quantity", "unit", "category")
      end

      expect(actual_ingredients.size).to eq(3)
      expect(actual_ingredients).to match_array(expected_ingredients)
    end

    it "レシピと一緒に、動画もDBに保存される" do
      expect {
        post "/api/v1/users/#{user.id}/recipes", params: valid_params, headers: auth_headers, as: :json
      }.to change(Video, :count).by(1)

      expected_video = valid_params[:recipe][:video_attributes].deep_stringify_keys # キーはシンボルから文字列に変換
      expect(response.parsed_body["recipe"]["video"].except("id")).to eq(expected_video)
    end
  end

  # ストロングパラメータ
  context "パラメータにrecipeキーがない場合" do
    let(:invalid_params_no_recipe) do
      {
        name: "カレーライス",
        notes: "カレー粉はブレンドする"
      }
    end

    it "リクエストが失敗し、ステータス400が返る" do
      post "/api/v1/users/#{user.id}/recipes", params: invalid_params_no_recipe, headers: auth_headers, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["error"]).to eq("Bad Request")
    end
  end

  # バリデーションチェック
  context "パラメータにレシピ名（name）がない場合" do
    let(:invalid_params_no_name) do
      {
        recipe: {
          notes: "カレー粉はブレンドする"
        }
      }
    end

    it "リクエストが失敗し、ステータス422が返る" do
      post "/api/v1/users/#{user.id}/recipes", params: invalid_params_no_name, headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("レシピの作成に失敗しました")
      expect(response.parsed_body["details"]).to include("レシピ名を入力してください")
    end
  end

  # ストロングパラメータ
  context "許可されていないパラメータ（image）を送った場合" do
    let(:extra_params) do
      {
        recipe: {
          name: "カレーライス",
          notes: "カレー粉はブレンドする",
          image: "不要なデータ"
        }
      }
    end

    it "ステータス201は返るが、DBにimageは保存されない" do
      post "/api/v1/users/#{user.id}/recipes", params: extra_params, headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["recipe"]).not_to have_key("image")
    end
  end
end
