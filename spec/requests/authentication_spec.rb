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
end
