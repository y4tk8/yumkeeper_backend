Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      mount_devise_token_auth_for "User", at: "auth", controllers: {
        registrations: "api/v1/auth/registrations",
        passwords:     "api/v1/auth/passwords"
      }

      resources :users do
        resources :recipes, only: [:index, :show, :create, :update, :destroy]
      end

      resources :videos, only: [:update]
    end
  end

  # 開発環境で送信したメールをブラウザから一覧するためのパス
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
