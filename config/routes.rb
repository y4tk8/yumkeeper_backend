Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      mount_devise_token_auth_for "User", at: "auth", controllers: {
        registrations: "api/v1/auth/registrations",
        confirmations: "api/v1/auth/confirmations",
        passwords:     "api/v1/auth/passwords"
      }

      resources :users, only: [:show, :update] do
        member do
          delete :delete_profile_image
        end

        resources :recipes, only: [:index, :show, :create, :update, :destroy]
      end

      resources :videos, only: [:update]

      namespace :auth do
        resource :guest_user, only: [:create, :destroy]
      end
    end
  end

  # ヘルスチェック用
  get "/healthcheck", to: proc { [200, {}, ["OK"]] }

  # ユーザーを簡便に'認証済み'可能に（主にテスト利用）
  if Rails.env.development? || Rails.env.test?
    namespace :test_support do
      namespace :api do
        namespace :v1 do
          put "/test_user_confirm", to: "test_user_confirmations#update"
        end
      end
    end
  end

  # 開発環境からの送信メールをブラウザで一覧するためのパス
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
