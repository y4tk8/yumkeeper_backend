require "rails_helper"

RSpec.describe "Resend Account Confirmation", type: :request do
  # NOTE: セキュリティ観点（総当たり攻撃防止）から、すべて同様にステータス200を返す
  describe "POST /api/v1/auth/confirmation" do
    context "未認証ユーザーがリクエストした場合" do
      let(:unconfirmed_user) { create(:user, confirmed_at: nil) }

      it "認証メールが再送され、ステータス200が返る" do
        expect {
          post "/api/v1/auth/confirmation", params: { email: unconfirmed_user.email }, as: :json
        }.to change { ActionMailer::Base.deliveries.count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["message"]).to include("アカウント認証メールを再送しました。メールをご確認ください。")
      end
    end

    context "認証済みユーザーがリクエストした場合" do
      let(:user) { create(:user, :confirmed) }

      it "認証メールが送信され、ステータス200が返る" do
        expect {
          post "/api/v1/auth/confirmation", params: { email: user.email }, as: :json
        }.to change { ActionMailer::Base.deliveries.count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["message"]).to include("アカウント認証メールを再送しました。メールをご確認ください。")
      end
    end

    context "退会済みユーザーがリクエストした場合" do
      let(:deleted_user) { create(:user, :deleted, confirmed_at: nil) }

      it "認証メールが送信され、ステータス200が返る" do
        expect {
          post "/api/v1/auth/confirmation", params: { email: deleted_user.email }, as: :json
        }.to change { ActionMailer::Base.deliveries.count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["message"]).to include("アカウント認証メールを再送しました。メールをご確認ください。")
      end
    end

    context "存在しないメールアドレスを指定した場合" do
      it "認証メールは送信されず、ステータス200が返る" do
        expect {
          post "/api/v1/auth/confirmation", params: { email: "nonexistent@example.com" }, as: :json
        }.not_to change { ActionMailer::Base.deliveries.count }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["message"]).to include("アカウント認証メールを再送しました。メールをご確認ください。")
      end
    end
  end
end
