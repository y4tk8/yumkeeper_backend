require "rails_helper"

RSpec.describe "Password Reset", type: :request do
  # メール認証済みのユーザー
  let(:user) { create(:user, :confirmed) }

  # リセットメール送信先のメールアドレスをPOST
  describe "POST /api/v1/auth/password" do
    context "メールアドレスが登録済みの場合" do
      before do
        post "/api/v1/auth/password", params: { email: user.email, redirect_url: "http://frontend.example.com/password_reset" }
      end

      it "パスワードリセットメールが送信され、ステータス200が返る" do
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["message"]).to include("すでにメールアドレスがデータベースに登録されている場合、 数分後にパスワード再発行用のリンクを記載したメールをお送りします。")
      end

      it "リセットトークンとメール送信日時のカラムが更新される" do
        user.reload
        expect(user.reset_password_token).to be_present
        expect(user.reset_password_sent_at).to be_within(3.second).of(Time.current) # 3秒以内の誤差を許容する
      end
    end
  end

  # リダイレクト先（パスワード更新ページ）URLへGET
  describe "GET /api/v1/auth/password/edit" do
    before do
      post "/api/v1/auth/password", params: { email: user.email, redirect_url: "http://frontend.example.com/password_reset" }
      user.reload
    end

    context "リセットトークンが有効な場合" do
      it "パスワードリセットメール内のリンク押下で再設定ページへリダイレクト" do
        # ハッシュ化前のリセットトークンを取得
        raw_token = user.send(:set_reset_password_token)
        get "/api/v1/auth/password/edit", params: { reset_password_token: raw_token, redirect_url: "http://frontend.example.com/password_reset" }

        expect(response).to have_http_status(:found)
        expect(response.headers["Location"]).to match(%r{\Ahttp://frontend\.example\.com/password_reset\?reset_password_token=#{Regexp.escape(raw_token)}}) # リダイレクト先URLにリセットトークンが含まれているか
        user.reload
        expect(user.allow_password_change).to be true # パスワード変更許可をtrueに
      end
    end

    context "リセットトークンが無効な場合" do
      it "再設定ページへのリダイレクトに失敗する" do
        get "/api/v1/auth/password/edit", params: { reset_password_token: "invalid_token", redirect_url: "http://frontend.example.com/password_reset" }

        expect(response).to have_http_status(:not_found)
        user.reload
        expect(user.allow_password_change).to be false # パスワード変更許可はfalseのまま
      end
    end

    context "リセットトークンの有効期間が切れている場合" do
      let!(:raw_token) { user.send(:set_reset_password_token) } # トークン有効切れを確実にするために即時評価

      before do
        user.update!(reset_password_sent_at: Time.current - 5.hours)
        user.reload
      end

      it "再設定ページへのリダイレクトに失敗する" do
        get "/api/v1/auth/password/edit", params: { reset_password_token: raw_token, redirect_url: "http://frontend.example.com/password_reset" }

        expect(response).to have_http_status(:not_found)
        user.reload
        expect(user.allow_password_change).to be false # パスワード変更許可はfalseのまま
      end
    end
  end

  # 新しいパスワードをPUT
  describe "PUT /api/v1/auth/password" do
    let(:raw_token) do
      post "/api/v1/auth/password", params: { email: user.email, redirect_url: "http://frontend.example.com/password_reset" }
      raw_token = user.send(:set_reset_password_token)
    end

    before do
      user.allow_password_change = true
      user.reload
    end

    it "パスワードリセットに成功し、ステータス200が返る" do
      put "/api/v1/auth/password", params: { password: "NewPassword1", password_confirmation: "NewPassword1", reset_password_token: raw_token }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["message"]).to include("パスワードの更新に成功しました。")
    end

    it "パスワードリセットトークンとメール送信日時のカラムがnilになる" do
      put "/api/v1/auth/password", params: { password: "NewPassword1", password_confirmation: "NewPassword1", reset_password_token: raw_token }

      user.reload
      expect(user.reset_password_token).to be_nil
      expect(user.reset_password_sent_at).to be_nil
      expect(user.allow_password_change).to be false # パスワード変更許可をfalseに
    end
  end
end
