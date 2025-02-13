Rails.application.routes.draw do
  namespace :api do
    scope :v1 do
      mount_devise_token_auth_for "User", at: "auth"
    end
  end

  # 開発環境で送信したメールをブラウザから一覧するためのパス
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
