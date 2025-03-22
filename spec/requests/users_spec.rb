require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  let(:user) { create(:user, :confirmed, :with_profile_image) }
  let(:other_user) { create(:user, :confirmed, username: nil) }
  let(:auth_headers) { user.create_new_auth_token } # Devise Token Authの認証情報

  # プロフィール情報を取得（show）
  describe "GET /api/v1/users/:id" do
    context "有効なユーザーが自分のプロフィールを取得する場合" do
      before do
        get "/api/v1/users/#{user.id}", headers: auth_headers
      end

      it "リクエストが成功し、ステータス200が返る" do
        expect(response).to have_http_status(:ok)
      end

      it "正しいプロフィール情報が返る" do
        expect(response.parsed_body[:user][:id]).to eq(user.id)
        expect(response.parsed_body[:user][:username]).to eq(user.username)
        expect(response.parsed_body[:user][:profile_image_url]).to be_present
      end
    end

    context "別のユーザーのプロフィールを取得しようとした場合" do
      it "プロフィール取得に失敗し、ステータス403が返る" do
        get "/api/v1/users/#{other_user.id}", headers: auth_headers

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to eq("アクセス権限がありません。")
      end
    end

    context "無効なユーザー（未認証ユーザー）の場合" do
      it "認証に失敗し、ステータス401が返る" do
        get "/api/v1/users/#{user.id}"# 認証ヘッダーなし

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("ログインもしくはアカウント登録してください。")
      end
    end
  end

  # プロフィール情報を更新（update）
  describe "PUT /api/v1/users/:id" do
    let(:file) { fixture_file_upload(Rails.root.join("spec/fixtures/profile_image.webp"), "image/webp") } # テスト用プロフィール画像

    context "有効なユーザーが自分のプロフィールを更新する場合" do
      let(:valid_params) do
        {
          user: {
            username: "新しいユーザー名",
            profile_image: file
          }
        }
      end

      before do
        put "/api/v1/users/#{user.id}", params: valid_params, headers: auth_headers, as: :json
      end

      it "リクエストが成功し、ステータス200が返る" do
        expect(response).to have_http_status(:ok)
      end

      it "正しいレスポンスメッセージが返る" do
        expect(response.parsed_body["message"]).to include("プロフィールを更新しました")
        expect(response.parsed_body["user"]["id"]).to eq(user.id)
        expect(response.parsed_body["user"]["username"]).to include("新しいユーザー名")
        expect(response.parsed_body["user"]["profile_image_url"]).to include("profile_image.webp")
      end

      it "DBのユーザー名とプロフィール画像が更新される" do
        user.reload
        expect(user.username).to eq("新しいユーザー名")
        expect(user.profile_image.attached?).to be_truthy
        expect(user.profile_image.filename).to eq("profile_image.webp")
      end
    end

    # ストロングパラメータ
    context "パラメータにuserキーがない場合" do
      let(:invalid_params_no_user) do
        {
          username: "新しいユーザー名",
          profile_image: file
        }
      end

      it "リクエストが失敗し、ステータス400が返る" do
        put "/api/v1/users/#{user.id}", params: invalid_params_no_user, headers: auth_headers, as: :json

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["error"]).to eq("Bad Request")
      end
    end
  end

  # プロフィール画像を削除（delete_profile_image）
  describe "DELETE /api/v1/users/:id/delete_profile_image" do
    context "プロフィール画像がアップロード済みの場合" do
      it "プロフィール画像が削除され、ステータス200が返る" do
        delete "/api/v1/users/#{user.id}/delete_profile_image", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["message"]).to include("プロフィール画像を削除しました")
        user.reload
        expect(user.profile_image.attached?).to be_falsey
      end
    end

    context "プロフィール画像がアップロードされていない場合" do
      let!(:user) { create(:user, :confirmed) } # プロフィール画像をアップロードしていないユーザー

      it "リクエストが失敗し、ステータス404が返る" do
        delete "/api/v1/users/#{user.id}/delete_profile_image", headers: auth_headers

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body["error"]).to include("プロフィール画像が設定されていません")
      end
    end
  end
end
