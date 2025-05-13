require "rails_helper"

RSpec.describe "User Sign-Up", type: :request do
  describe "POST /api/v1/auth" do
    let(:valid_params) do
      {
        email: "test@example.com",
        password: "Password1",
        password_confirmation: "Password1"
      }
    end

    context "正しいメールアドレス、パスワード、確認用パスワードの場合" do
      it "サインアップが成功し、ステータス200が返る" do
        post "/api/v1/auth", params: valid_params, as: :json

        expect(response).to have_http_status(:ok)
      end

      it "Usersテーブルのレコードが1増える" do
        expect {
          post "/api/v1/auth", params: valid_params, as: :json
        }.to change { User.count }.by(1)
      end

      it "アカウント認証メールが送信される" do
        expect {
          post "/api/v1/auth", params: valid_params, as: :json
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context "重複するメールアドレスがDBに存在する場合" do
      it "リクエストが失敗し、ステータス422が返る" do
        create(:user, email: valid_params[:email])

        post "/api/v1/auth", params: valid_params, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]["email"]).to include("入力したメールアドレスはすでに存在します")
      end
    end

    context "パスワードが8文字未満 または 確認用パスワードと一致しない場合" do
      it "エラーメッセージと共に、ステータス422が返る（パスワードが8文字未満）" do
        post "/api/v1/auth", params: { email: "test@example.com", password: "Pass1", password_confirmation: "Pass1" }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]["password"]).to include("パスワードは8文字以上で入力してください")
      end

      it "エラーメッセージと共に、ステータス422が返る（確認用パスワードと不一致）" do
        post "/api/v1/auth", params: { email: "test@example.com", password: "Password1", password_confirmation: "DifferentPass1" }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["errors"]["password_confirmation"]).to include("入力したパスワードが一致しません")
      end
    end
  end
end
