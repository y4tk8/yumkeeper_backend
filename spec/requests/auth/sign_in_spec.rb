require "rails_helper"

RSpec.describe "User Sign-In", type: :request do
  describe "POST /api/v1/auth/sign_in" do
    let(:user) { create(:user, :confirmed) }

    context "正しいメールアドレスとパスワードの場合" do
      it "サインインが成功し、ステータス200が返る" do
        post "/api/v1/auth/sign_in", params: { email: user.email, password: user.password }, as: :json

        expect(response).to have_http_status(:ok)
        expect(response.headers["access-token"]).to be_present
        expect(response.headers["client"]).to be_present
        expect(response.headers["uid"]).to eq(user.email)
      end
    end

    context "誤ったメールアドレス または パスワードの場合" do
      it "サインインに失敗し、ステータス401が返る（誤ったメールアドレス）" do
        post "/api/v1/auth/sign_in", params: { email: "wrong_email@example.com", password: user.password }, as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("メールアドレスまたはパスワードが正しくありません")
      end

      it "サインインに失敗し、ステータス401が返る（誤ったパスワード）" do
        post "/api/v1/auth/sign_in", params: { email: user.email, password: "wrong_password" }, as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("メールアドレスまたはパスワードが正しくありません")
      end
    end

    context "メール認証が完了していない場合" do
      let(:unconfirmed_user) { create(:user, confirmed_at: nil) }

      it "サインインが失敗し、ステータス401が返る" do
        post "/api/v1/auth/sign_in", params: { email: unconfirmed_user.email, password: unconfirmed_user.password }, as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("メールアドレスまたはパスワードが正しくありません")
      end
    end

    context "退会済みユーザーの場合" do
      let(:deleted_user) { create(:user, :deleted) }

      it "サインインが失敗し、ステータス401が返る" do
        post "/api/v1/auth/sign_in", params: { email: deleted_user.email, password: deleted_user.password }, as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["errors"]).to include("メールアドレスまたはパスワードが正しくありません")
      end
    end
  end
end
