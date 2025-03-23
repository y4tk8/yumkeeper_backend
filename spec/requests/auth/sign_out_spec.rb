require "rails_helper"

RSpec.describe "User Sign-Out", type: :request do
  describe "DELETE /api/v1/auth/sign_out" do
    let(:user) { create(:user, :confirmed) }
    let(:auth_headers) { user.create_new_auth_token } # Devise Token Authの認証情報

    context "認証情報が正しい場合" do
      it "サインアウトが成功し、ステータス200が返る" do
        delete "/api/v1/auth/sign_out", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["success"]).to be_truthy
      end

      it "サインアウト後、ユーザーのtokensカラムが空になる" do
        delete "/api/v1/auth/sign_out", headers: auth_headers

        user.reload
        expect(user.tokens).to be_empty
      end
    end

    context "認証情報がない、または間違っている場合" do
      it "サインアウトに失敗し、ステータス404が返る（認証情報がない）" do
        delete "/api/v1/auth/sign_out"

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body["errors"]).to include("ユーザーが見つからないか、ログインしていません。")
      end

      it "サインアウトに失敗し、ステータス404が返る（認証情報が間違っている）" do
        invalid_headers = {
          "access-token" => "invalid_token",
          "client" => "invalid_client",
          "uid" => "invalid_uid@example.com"
        }

        delete "/api/v1/auth/sign_out", headers: invalid_headers

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body["errors"]).to include("ユーザーが見つからないか、ログインしていません。")
      end
    end
  end
end
