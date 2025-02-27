require "rails_helper"

RSpec.describe "Api::V1::Recipes", type: :request do
  let(:user) { create(:user, :confirmed) } # メール認証済みのユーザー
  let!(:recipes) { create_list(:recipe, 5, user: user) } # レシピを5つ作成
  let(:recipe) { recipes.first }
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

      it "作成した全てのレシピとカウントを取得する" do
        expect(response.parsed_body["recipes"].length).to eq(5)
        expect(response.parsed_body["recipe_count"]).to eq(5)
      end

      it "作成日時の降順でレシピを取得する" do
        expect(response.parsed_body["recipes"].pluck("id")).to eq(recipes.sort_by(&:created_at).reverse.pluck(:id))
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
          notes: "カレー粉はブレンドする"
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
    let(:valid_attributes) do
      {
        recipe: {
          "name": "新しいレシピ名",
          "notes": "新しいメモ"
        }
      }
    end

    let(:invalid_attributes) do
      {
        recipe: {
          "name": "",
          "notes": "新しいメモ"
        }
      }
    end

    context "有効なユーザーが自分のレシピを更新する場合" do
      it "リクエストが成功し、ステータス200が返る" do
        put "/api/v1/users/#{user.id}/recipes/#{recipe.id}", params: valid_attributes, headers: headers, as: :json

        expect(response).to have_http_status(:ok)
      end

      it "DBの該当データが更新される" do
        old_updated_at = recipe.updated_at
        put "/api/v1/users/#{user.id}/recipes/#{recipe.id}", params: valid_attributes, headers: headers, as: :json

        recipe.reload
        expect(recipe.name).to eq("新しいレシピ名")
        expect(recipe.notes).to eq("新しいメモ")
        expect(recipe.updated_at).to be > old_updated_at
      end

      it "レシピ名（name）が空の場合、ステータス422が返る" do
        put "/api/v1/users/#{user.id}/recipes/#{recipe.id}", params: invalid_attributes, headers: headers, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to eq("レシピの更新に失敗しました")
        expect(response.parsed_body["details"]).to include("レシピ名を入力してください")
      end
    end

    context "自分が保有していないレシピを更新しようとした場合" do
      it "リクエストが失敗し、ステータス403が返る" do
        put "/api/v1/users/#{user.id}/recipes/#{other_recipe.id}", params: valid_attributes, headers: headers, as: :json

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to eq("レシピが見つかりません。")
      end
    end
  end
end
