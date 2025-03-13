class ApplicationController < ActionController::API
  # トークンベースのユーザー認証
  include DeviseTokenAuth::Concerns::SetUserByToken

  # ページネーション
  include Pagy::Backend
end
