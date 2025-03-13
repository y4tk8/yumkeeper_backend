require "rails_helper"

RSpec.describe "Api::V1::Recipes", type: :request do
  let(:user) { create(:user, :confirmed) } # メール認証済みのユーザー
  let!(:recipes) { create_list(:recipe, 5, :add_video, user: user) } # 動画データ有りのレシピを5つ作成
  let(:recipe) { create(:recipe, :add_ingredients, :add_video, user: user) } # 材料・動画データ有りのレシピ
  let(:headers) { user.create_new_auth_token } # Devise Token Authの認証情報

  let(:other_user) { create(:user, :confirmed) } # 別ユーザー
  let!(:other_recipe) { create(:recipe, user: other_user) } # 別ユーザーのレシピ作成

  # ユーザーごとのレシピ一覧を取得（index）
  describe "GET /api/v1/users/:user_id/recipes" do
    context "有効なユーザーが自分のレシピ一覧を取得する場合" do
      before do
        get "/api/v1/users/#{user.id}/recipes", headers: headers, as: :json
      end

      it "リクエストが成功し、ステータス200が返る" do
        expect(response).to have_http_status(:ok)
      end

      it "作成した全てのレシピを取得する" do
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
    end

    context "別のユーザーのレシピ一覧を取得しようとした場合" do
      it "レシピ取得に失敗し、ステータス403が返る" do
        get "/api/v1/users/#{other_user.id}/recipes", headers: headers, as: :json

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

  # ユーザーごとのレシピ詳細を取得（show）
  describe "GET /api/v1/users/:user_id/recipes/:id" do
    before do
      get "/api/v1/users/#{user.id}/recipes/#{recipe.id}", headers: headers, as: :json
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
      it "レシピ取得に失敗し、ステータス403が返る" do
        get "/api/v1/users/#{user.id}/recipes/#{other_recipe.id}", headers: headers, as: :json

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to eq("レシピが見つかりません。")
      end
    end
  end

  # レシピを登録（create）
  describe "POST /api/v1/users/:user_id/recipes" do
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

    let(:invalid_params_no_recipe) do
      {
        name: "カレーライス",
        notes: "カレー粉はブレンドする"
      }
    end

    let(:invalid_params_no_name) do
      {
        recipe: {
          notes: "カレー粉はブレンドする"
        }
      }
    end

    let(:extra_params) do
      {
        recipe: {
          name: "カレーライス",
          notes: "カレー粉はブレンドする",
          image: "不要なデータ"
        }
      }
    end

    context "リクエストが正常な場合" do
      it "ステータス201が返り、レシピがDBに保存される" do
        expect {
          post "/api/v1/users/#{user.id}/recipes", params: valid_params, headers: headers, as: :json
        }.to change(Recipe, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["message"]).to eq("レシピが作成されました")
        expect(response.parsed_body["recipe"]["name"]).to eq("カレーライス")
        expect(response.parsed_body["recipe"]["notes"]).to eq("カレー粉はブレンドする")
      end

      it "レシピと一緒に、材料もDBに保存される" do
        expect {
          post "/api/v1/users/#{user.id}/recipes", params: valid_params, headers: headers, as: :json
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
          post "/api/v1/users/#{user.id}/recipes", params: valid_params, headers: headers, as: :json
        }.to change(Video, :count).by(1)

        expected_video = valid_params[:recipe][:video_attributes].deep_stringify_keys # キーはシンボルから文字列に変換
        expect(response.parsed_body["recipe"]["video"].except("id")).to eq(expected_video)
      end
    end

    # ストロングパラメータ
    context "パラメータにrecipeキーがない場合" do
      it "リクエストが失敗し、ステータス400が返る" do
        post "/api/v1/users/#{user.id}/recipes", params: invalid_params_no_recipe, headers: headers, as: :json

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["error"]).to eq("Bad Request")
      end
    end

    # バリデーションチェック
    context "パラメータにレシピ名（name）がない場合" do
      it "リクエストが失敗し、ステータス422が返る" do
        post "/api/v1/users/#{user.id}/recipes", params: invalid_params_no_name, headers: headers, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to eq("レシピの作成に失敗しました")
        expect(response.parsed_body["details"]).to include("レシピ名を入力してください")
      end
    end

    # ストロングパラメータ
    context "許可されていないパラメータ（image）を送った場合" do
      it "ステータス201は返るが、DBにimageは保存されない" do
        post "/api/v1/users/#{user.id}/recipes", params: extra_params, headers: headers, as: :json

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["recipe"]).not_to have_key("image")
      end
    end
  end

  # レシピを更新（update）
  describe "PUT /api/v1/users/:user_id/recipes/:id" do
    let(:params_to_update) do
      existing_ingredients = recipe.ingredients.to_a
      existing_video = recipe.video
      {
        recipe: {
          name: "新しいレシピ名",
          notes: "新しいメモ",
          ingredients_attributes: [
            { id: existing_ingredients[0].id, name: "新しい材料", quantity: 3, unit: "本", category: "ingredient" },
            { id: existing_ingredients[1].id, _destroy: true }
          ],
          video_attributes: {
            id: existing_video.id,
            etag: "new_etag_456",
            status: "private",
            is_embeddable: false,
            is_deleted: true
          }
        }
      }
    end

    let(:invalid_params) do
      {
        recipe: {
          name: "",
          notes: "新しいメモ"
        }
      }
    end

    context "有効なユーザーが自分のレシピを更新する場合" do
      it "リクエストが成功し、ステータス200が返る" do
        put "/api/v1/users/#{user.id}/recipes/#{recipe.id}", params: params_to_update, headers: headers, as: :json

        expect(response).to have_http_status(:ok)
      end

      it "DBのレシピデータが更新される" do
        old_updated_at = recipe.updated_at
        put "/api/v1/users/#{user.id}/recipes/#{recipe.id}", params: params_to_update, headers: headers, as: :json

        recipe.reload
        expect(recipe.name).to eq("新しいレシピ名")
        expect(recipe.notes).to eq("新しいメモ")
        expect(recipe.updated_at).to be > old_updated_at
      end

      it "DBの材料データが更新され、不要な材料は削除される" do
        put "/api/v1/users/#{user.id}/recipes/#{recipe.id}", params: params_to_update, headers: headers, as: :json

        update_id = params_to_update[:recipe][:ingredients_attributes][0][:id]
        delete_id = params_to_update[:recipe][:ingredients_attributes][1][:id]

        recipe.ingredients.reload
        updated_ingredient = recipe.ingredients.find_by(id: update_id)
        deleted_ingredient = recipe.ingredients.find_by(id: delete_id)

        expect(updated_ingredient).to have_attributes(
          "name": "新しい材料",
          "quantity": 3,
          "unit": "本",
          "category": "ingredient"
        )
        expect(deleted_ingredient).to be_nil
      end

      it "DBの動画データが更新される" do
        put "/api/v1/users/#{user.id}/recipes/#{recipe.id}", params: params_to_update, headers: headers, as: :json

        recipe.video.reload
        expect(recipe.video).to have_attributes(
          "etag": "new_etag_456",
          "status": "private",
          "is_embeddable": false,
          "is_deleted": true
        )
      end
    end

    context "レシピ名（name）が空の場合" do
      it "リクエストが失敗し、ステータス422が返る" do
        put "/api/v1/users/#{user.id}/recipes/#{recipe.id}", params: invalid_params, headers: headers, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to eq("レシピの更新に失敗しました")
        expect(response.parsed_body["details"]).to include("レシピ名を入力してください")
      end
    end

    context "自分が保有していないレシピを更新しようとした場合" do
      it "リクエストが失敗し、ステータス403が返る" do
        put "/api/v1/users/#{user.id}/recipes/#{other_recipe.id}", params: params_to_update, headers: headers, as: :json

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to eq("レシピが見つかりません。")
      end
    end
  end

  # レシピを削除（destroy）
  describe "DELETE /api/v1/users/:user_id/recipes/:id" do
    context "有効なユーザーが自分のレシピを削除する場合" do
      let!(:recipe_to_delete) { create(:recipe, user: user) }

      it "ステータス200が返り、レシピがDBから物理削除される" do
        expect {
          delete "/api/v1/users/#{user.id}/recipes/#{recipe_to_delete.id}", headers: headers, as: :json
        }.to change { Recipe.count }.by(-1)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["message"]).to eq("レシピが削除されました")
      end

      it "削除後にそのレシピにアクセスするとステータス403が返る" do
        delete "/api/v1/users/#{user.id}/recipes/#{recipe_to_delete.id}", headers: headers, as: :json
        get "/api/v1/users/#{user.id}/recipes/#{recipe_to_delete.id}", headers: headers, as: :json

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to eq("レシピが見つかりません。")
      end

      it "削除後にユーザーの recipe_count が減る" do
        expect {
          delete "/api/v1/users/#{user.id}/recipes/#{recipe_to_delete.id}", headers: headers, as: :json
          user.reload
        }.to change { user.recipe_count }.by(-1)
      end
    end

    context "自分が保有していないレシピを削除しようとした場合" do
      it "リクエストが失敗し、ステータス403が返る" do
        expect {
          delete "/api/v1/users/#{user.id}/recipes/#{other_recipe.id}", headers: headers, as: :json
        }.not_to change { Recipe.count }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
