module Api
  module V1
    module Auth
      class GuestUsersController < ApplicationController
        before_action :authenticate_api_v1_user!, only: [:destroy]
        before_action :check_if_user_signed_in

        # 認証情報をレスポンスヘッダーに付与するDevise Token Authの既定メソッドをスキップ
        # NOTE: これがないと 既定のafter_action が実行され、destroyの際に404エラーを返す
        skip_after_action :update_auth_header, only: [:destroy]

        # ゲストサインイン処理
        def create
          email = "guest_#{SecureRandom.hex(6)}@example.com"

          guest_user = User.create!(
            email: email,
            password: SecureRandom.alphanumeric(20),
            confirmed_at: Time.current, # メール認証済みにする
            uid: email,
            role: "ゲスト"
          )

          # Devise Token Authのトークン発行 & ヘッダーに付与
          token = guest_user.create_new_auth_token
          response.headers.merge!(token)

          render json: { message: "ゲストとしてログインしました", user: guest_user }, status: :ok
        end

        # ゲストサインアウト処理
        def destroy
          if current_api_v1_user&.role == "ゲスト"
            current_api_v1_user.destroy!
            render json: { message: "ゲストからログアウトしました" }, status: :ok
          end
        end

        private

        # 通常ユーザー（ゲスト以外）なら403エラーを返す
        def check_if_user_signed_in
          if api_v1_user_signed_in? && current_api_v1_user.role == "一般"
            render json: { error: "すでにログインしている場合はゲスト機能は使えません" }, status: :forbidden
          end
        end
      end
    end
  end
end
