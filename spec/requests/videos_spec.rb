require "rails_helper"

RSpec.describe "Api::V1::Videos", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:recipe) { create(:recipe, user: user) }
  let(:video) { create(:video, recipe: recipe) }
  let(:auth_headers) { user.create_new_auth_token } # Devise Token Authの認証情報

  # 動画を更新（update）
  describe "PUT /api/v1/videos/:id" do
    let(:valid_params) do
      {
        video: {
          etag: "new_etag_456",
          status: "private",
          is_embeddable: "false",
          is_deleted: "true",
          cached_at: Time.current
        }
      }
    end

    context "リクエストが正常な場合" do
      before do
        put "/api/v1/videos/#{video.id}", params: valid_params, headers: auth_headers, as: :json
      end

      it "リクエストが成功し、ステータス200が返る" do
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["message"]).to eq("動画が更新されました")
      end

      it "DBの動画データが更新される" do
        video.reload
        expect(video.etag).to eq("new_etag_456")
        expect(video.status).to eq("private")
        expect(video.is_embeddable).to be false
        expect(video.is_deleted).to be true
      end
    end

    context "別のユーザーが動画を更新しようとした場合" do
      let(:other_user) { create(:user, :confirmed) }
      let(:other_auth_headers) { other_user.create_new_auth_token }

      it "動画更新に失敗し、ステータス403が返る" do
        put "/api/v1/videos/#{video.id}", params: valid_params, headers: other_auth_headers, as: :json

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to eq("アクセス権限がありません")
      end
    end

    context "動画が見つからない場合" do
      it "リクエストが失敗し、ステータス404が返る" do
        put "/api/v1/videos/9999", params: valid_params, headers: auth_headers, as: :json

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body["error"]).to eq("動画が見つかりません")
      end
    end

    # ストロングパラメータ
    context "パラメータにvideoキーがない場合" do
      let(:invalid_params_no_video) do
        {
          etag: "new_etag_456",
          status: "private"
        }
      end

      it "リクエストが失敗し、ステータス400が返る" do
        put "/api/v1/videos/#{video.id}", params: invalid_params_no_video, headers: auth_headers, as: :json

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["error"]).to eq("Bad Request")
      end
    end

    context "無効なユーザー（未認証ユーザー）の場合" do
      it "認証に失敗し、ステータス401が返る" do
        put "/api/v1/videos/#{video.id}", params: valid_params, as: :json # 認証ヘッダーなし

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("ログインもしくはアカウント登録してください。")
      end
    end
  end
end
