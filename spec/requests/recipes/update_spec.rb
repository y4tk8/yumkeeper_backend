require "rails_helper"

RSpec.describe "PUT /api/v1/users/:user_id/recipes/:id", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:recipe) { create(:recipe, :with_ingredients, :with_video, user: user) }
  let(:auth_headers) { user.create_new_auth_token } # Devise Token Authの認証情報

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

  context "有効なユーザーが自分のレシピを更新する場合" do
    it "リクエストが成功し、ステータス200が返る" do
      put "/api/v1/users/#{user.id}/recipes/#{recipe.id}", params: params_to_update, headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
    end

    it "DBのレシピデータが更新される" do
      old_updated_at = recipe.updated_at

      put "/api/v1/users/#{user.id}/recipes/#{recipe.id}", params: params_to_update, headers: auth_headers, as: :json

      recipe.reload
      expect(recipe.name).to eq("新しいレシピ名")
      expect(recipe.notes).to eq("新しいメモ")
      expect(recipe.updated_at).to be > old_updated_at
    end

    it "DBの材料データが更新され、不要な材料は削除される" do
      put "/api/v1/users/#{user.id}/recipes/#{recipe.id}", params: params_to_update, headers: auth_headers, as: :json

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
      put "/api/v1/users/#{user.id}/recipes/#{recipe.id}", params: params_to_update, headers: auth_headers, as: :json

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
    let(:invalid_params) do
      {
        recipe: {
          name: "",
          notes: "新しいメモ"
        }
      }
    end

    it "リクエストが失敗し、ステータス422が返る" do
      put "/api/v1/users/#{user.id}/recipes/#{recipe.id}", params: invalid_params, headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("レシピの更新に失敗しました")
      expect(response.parsed_body["details"]).to include("レシピ名を入力してください")
    end
  end

  context "自分が保有していないレシピを更新しようとした場合" do
    let(:other_user) { create(:user, :confirmed) }
    let!(:other_recipe) { create(:recipe, user: other_user) }

    it "リクエストが失敗し、ステータス403が返る" do
      put "/api/v1/users/#{user.id}/recipes/#{other_recipe.id}", params: params_to_update, headers: auth_headers, as: :json

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body["error"]).to eq("レシピが見つかりません。")
    end
  end
end
