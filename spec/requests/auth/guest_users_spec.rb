require "rails_helper"

RSpec.describe "Guest User", type: :request do
  # ゲストサインイン（create）
  describe "POST /api/v1/auth/guest_user" do
    context "有効な場合" do
      before { post "/api/v1/auth/guest_user" }

      it "リクエストが成功し、ステータス200が返る" do
        expect(response).to have_http_status(:ok)
      end

      it "ゲストユーザー情報と認証トークンが返る" do
        expect(response.parsed_body["message"]).to include("ログインしました")
        expect(response.parsed_body["user"]["role"]).to eq("ゲスト")
        expect(response.headers["access-token"]).to be_present
        expect(response.headers["client"]).to be_present
        expect(response.headers["uid"]).to be_present
      end
    end

    context "無効な場合" do
      let(:user) { create(:user, :confirmed) } # 通常ユーザー
      let(:auth_headers) { user.create_new_auth_token } # Devise Token Authの認証情報

      it "認証済みの通常ユーザーはゲストサインインできない" do
        post "/api/v1/auth/guest_user", headers: auth_headers

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("すでにログインしている場合はゲスト機能は使えません")
      end
    end
  end

  # ゲストサインアウト（destroy）
  describe "DELETE /api/v1/auth/guest_user" do
    let(:guest_user) { create(:user, :guest) }
    let(:auth_headers) { guest_user.create_new_auth_token }

    context "有効な場合" do
      before { delete "/api/v1/auth/guest_user", headers: auth_headers }

      it "リクエストが成功し、ステータス200が返る" do
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["message"]).to include("ログアウトしました")
      end

      it "DBからゲストユーザーが物理削除される" do
        expect(User.exists?(guest_user.id)).to be_falsey
      end
    end

    context "無効な場合" do
      let(:user) { create(:user, :confirmed) }
      let(:auth_headers) { user.create_new_auth_token }

      it "未認証ユーザーはサインアウトできない" do
        delete "/api/v1/auth/guest_user" # 認証ヘッダーなし

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("ログインもしくはアカウント登録してください。")
      end

      it "通常ユーザーはサインアウトできない" do
        delete "/api/v1/auth/guest_user", headers: auth_headers

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("すでにログインしている場合はゲスト機能は使えません")
      end
    end
  end
end
