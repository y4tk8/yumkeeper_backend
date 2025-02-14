require "rails_helper"

RSpec.describe "User Authentication", type: :request do
  let(:user) { create(:user, :confirmed) }

  # ユーザーのサインイン
  describe "POST /api/v1/auth/sign_in" do
    context "正しいメールアドレスとパスワードの場合" do
      it "サインインが成功し、ステータス200が返る" do
        post "/api/v1/auth/sign_in", params: { email: user.email, password: user.password }

        expect(response).to have_http_status(:ok)
        expect(response.headers["access-token"]).to be_present
        expect(response.headers["client"]).to be_present
        expect(response.headers["uid"]).to eq(user.email)
      end
    end

    context "誤ったメールアドレス または パスワードの場合" do
      it "サインインに失敗し、ステータス401が返る（誤ったメールアドレス）" do
        post "/api/v1/auth/sign_in", params: { email: "wrong_email@example.com", password: user.password }

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("ログイン用の認証情報が正しくありません。再度お試しください。")
      end

      it "サインインに失敗し、ステータス401が返る（誤ったパスワード）" do
        post "/api/v1/auth/sign_in", params: { email: user.email, password: "wrong_password" }

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("ログイン用の認証情報が正しくありません。再度お試しください。")
      end
    end

    context "メール認証が完了していない場合" do
      let(:unconfirmed_user) { create(:user, confirmed_at: nil) }

      it "サインインが失敗し、ステータス401が返る" do
        post "/api/v1/auth/sign_in", params: { email: unconfirmed_user.email, password: unconfirmed_user.password }

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("ログイン用の認証情報が正しくありません。再度お試しください。")
      end
    end
  end

  # ユーザーのサインアウト
  describe "DELETE /api/v1/auth/sign_out" do
    let(:headers) do
      # サインインで認証情報をレスポンスとして取得
      post "/api/v1/auth/sign_in", params: { email: user.email, password: user.password }
      {
        "access-token" => response.headers["access-token"],
        "client" => response.headers["client"],
        "uid" => response.headers["uid"]
      }
    end

    context "認証情報が正しい場合" do
      it "サインアウトが成功し、ステータス200が返る" do
        delete "/api/v1/auth/sign_out", headers: headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["success"]).to be true
      end

      it "サインアウト後、ユーザーのtokensカラムが空になる" do
        delete "/api/v1/auth/sign_out", headers: headers

        user.reload
        expect(user.tokens).to be_empty
      end
    end

    context "認証情報がない、または間違っている場合" do
      # 認証情報がない
      it "サインアウトに失敗し、ステータス404が返る" do
        delete "/api/v1/auth/sign_out"

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body["errors"]).to include("ユーザーが見つからないか、ログインしていません。")
      end

      # 認証情報が間違っている
      it "サインアウトに失敗し、ステータス404が返る" do
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
